import Foundation
import WMSCore
import WMSData
import WMSServices

@main
struct WMSSeed {
    static func main() async {
        let arguments = Array(CommandLine.arguments.dropFirst())
        if arguments.contains("--help") || arguments.contains("-h") {
            print(usageText)
            return
        }

        var reset = false
        var customDirectory: String?
        var index = 0
        while index < arguments.count {
            let argument = arguments[index]
            switch argument {
            case "--reset":
                reset = true
                index += 1
            case "--dir":
                index += 1
                guard index < arguments.count else {
                    exitWithMessage("--dir requires a directory path.")
                }
                customDirectory = arguments[index]
                index += 1
            default:
                exitWithMessage("Unknown option: \(argument)\n\n\(usageText)")
            }
        }

        let baseURL = customDirectory.map { URL(fileURLWithPath: $0, isDirectory: true) }
        do {
            try await run(baseURL: baseURL, reset: reset)
        } catch {
            exitWithMessage("Seeding failed: \(error)")
        }
    }

    static func run(baseURL: URL?, reset: Bool) async throws {
        let directory = baseURL ?? defaultDirectory()
        print("Data directory: \(directory.path)")

        if reset {
            let removed = try removeExistingData(in: directory)
            print("Reset: removed \(removed) data file(s).")
        }

        let store = WMSDataStore(baseURL: baseURL, dataProtector: KeychainDataProtector())
        let warehouseRepository = FileWarehouseRepository(store: store)
        let itemRepository = FileInventoryItemRepository(store: store)
        let movementRepository = FileStockMovementRepository(store: store)
        let employeeRepository = FileEmployeeRepository(store: store)
        let transferRepository = FileTransferOrderRepository(store: store)
        let auditRepository = FileAuditRepository(store: store)
        let alertRepository = FileAlertRepository(store: store)

        if !reset, let existing = try? await warehouseRepository.fetchAll(), !existing.isEmpty {
            print("Store already contains \(existing.count) warehouse(s); nothing to do.")
            print("Pass --reset to wipe the data files and reseed.")
            return
        }

        let accessController = AccessController(initialRole: .administrator)
        let auditLogger = AuditLogger(repository: auditRepository)
        let alertService = InventoryAlertService(alertRepository: alertRepository)
        let inventoryService = InventoryService(
            itemRepository: itemRepository,
            movementRepository: movementRepository,
            alertService: alertService,
            auditLogger: auditLogger,
            accessController: accessController
        )
        let warehouseService = WarehouseService(
            repository: warehouseRepository,
            inventoryService: inventoryService,
            auditLogger: auditLogger,
            accessController: accessController
        )
        let employeeService = EmployeeService(
            repository: employeeRepository,
            auditLogger: auditLogger,
            accessController: accessController
        )
        let transferService = TransferService(
            transferRepository: transferRepository,
            auditLogger: auditLogger,
            accessController: accessController
        )

        let seeder = Seeder(
            warehouseService: warehouseService,
            inventoryService: inventoryService,
            employeeService: employeeService,
            transferService: transferService
        )
        try await seeder.run()
    }

    private static func defaultDirectory() -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        let base = appSupport ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        return base.appendingPathComponent("WarehouseOS", isDirectory: true)
    }

    private static func removeExistingData(in directory: URL) throws -> Int {
        let fileManager = FileManager.default
        let contents = (try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        let dataFiles = contents.filter { $0.pathExtension == "json" }
        for file in dataFiles {
            try fileManager.removeItem(at: file)
        }
        return dataFiles.count
    }

    private static func exitWithMessage(_ message: String) -> Never {
        FileHandle.standardError.write(Data("\(message)\n".utf8))
        exit(1)
    }

    private static let usageText = """
    Usage: swift run WMSSeed [--dir <path>] [--reset]

    Loads a full demo dataset (warehouses, employees, inventory, movements,
    transfers, audit entries and alerts) through the real services, so the data
    is encrypted exactly like the app writes it.

      --dir <path>   Store data in <path> instead of the app's data directory.
      --reset        Delete existing JSON data files before seeding.
      -h, --help     Show this help.
    """
}

// MARK: - Dataset

private struct WarehouseSeed {
    let name: String
    let code: String
    let address: String
    let capacity: Int
}

private struct ItemSeed {
    let sku: String
    let name: String
    let description: String
    let category: String
    let unitOfMeasure: String
    let quantity: Int
    let threshold: Int
    let unitCost: Double
    let warehouseIndex: Int
}

private struct MovementSeed {
    let sku: String
    let type: MovementType
    let quantity: Int
    let note: String
    let reference: String
}

private struct TransferSeed {
    let sourceIndex: Int
    let destinationIndex: Int
    let lines: [(sku: String, quantity: Int)]
    let notes: String
    let targetState: TransferStatus
}

private struct EmployeeSeed {
    let firstName: String
    let lastName: String
    let code: String
    let title: String
    let email: String
    let phone: String
    let hired: Date
}

private final class Seeder {
    private let warehouseService: WarehouseService
    private let inventoryService: InventoryService
    private let employeeService: EmployeeService
    private let transferService: TransferService

    init(
        warehouseService: WarehouseService,
        inventoryService: InventoryService,
        employeeService: EmployeeService,
        transferService: TransferService
    ) {
        self.warehouseService = warehouseService
        self.inventoryService = inventoryService
        self.employeeService = employeeService
        self.transferService = transferService
    }

    func run() async throws {
        let warehouses = try await seedWarehouses()
        _ = try await seedEmployees()
        let items = try await seedItems(warehouses: warehouses)
        try await seedMovements(items: items)
        try await seedTransfers(warehouses: warehouses, items: items)
        print("Seed complete. Launch the app to explore the data.")
    }

    private func seedWarehouses() async throws -> [Warehouse] {
        let seeds: [WarehouseSeed] = [
            WarehouseSeed(
                name: "Central Distribution Centre",
                code: "WH-001",
                address: "12 Harbour Road, Sydney NSW 2000",
                capacity: 12000
            ),
            WarehouseSeed(
                name: "North Retail Hub",
                code: "WH-002",
                address: "48 Miller Street, North Sydney NSW 2060",
                capacity: 5000
            ),
            WarehouseSeed(
                name: "South Overflow Storage",
                code: "WH-003",
                address: "9 Industrial Way, Botany NSW 2019",
                capacity: 8000
            )
        ]

        var created: [Warehouse] = []
        for seed in seeds {
            let warehouse = try await warehouseService.createWarehouse(
                name: seed.name,
                code: seed.code,
                address: seed.address,
                capacity: seed.capacity
            )
            created.append(warehouse)
        }
        print("Warehouses: \(created.count)")
        return created
    }

    private func seedEmployees() async throws -> [Employee] {
        let seeds: [EmployeeSeed] = [
            EmployeeSeed(
                firstName: "Amelia", lastName: "Hart", code: "EMP-001",
                title: "Warehouse Manager", email: "amelia.hart@example.com",
                phone: "+61 400 111 222", hired: date(2023, 2, 13)
            ),
            EmployeeSeed(
                firstName: "Ben", lastName: "Okafor", code: "EMP-002",
                title: "Inventory Controller", email: "ben.okafor@example.com",
                phone: "+61 400 333 444", hired: date(2023, 6, 5)
            ),
            EmployeeSeed(
                firstName: "Chloe", lastName: "Nguyen", code: "EMP-003",
                title: "Forklift Operator", email: "chloe.nguyen@example.com",
                phone: "+61 400 555 666", hired: date(2024, 1, 22)
            ),
            EmployeeSeed(
                firstName: "Daniel", lastName: "Ruiz", code: "EMP-004",
                title: "Dispatch Coordinator", email: "daniel.ruiz@example.com",
                phone: "+61 400 777 888", hired: date(2024, 3, 11)
            ),
            EmployeeSeed(
                firstName: "Eva", lastName: "Kowalski", code: "EMP-005",
                title: "Stock Auditor", email: "eva.kowalski@example.com",
                phone: "+61 400 999 000", hired: date(2024, 8, 19)
            ),
            EmployeeSeed(
                firstName: "Farid", lastName: "Hassan", code: "EMP-006",
                title: "Receiving Clerk", email: "farid.hassan@example.com",
                phone: "+61 400 121 314", hired: date(2022, 11, 7)
            )
        ]

        var created: [Employee] = []
        for seed in seeds {
            let employee = try await employeeService.createEmployee(
                firstName: seed.firstName,
                lastName: seed.lastName,
                employeeCode: seed.code,
                jobTitle: seed.title,
                email: seed.email,
                phone: seed.phone,
                hireDate: seed.hired,
                notes: ""
            )
            created.append(employee)
        }
        if let inactive = created.last {
            try await employeeService.deactivateEmployee(id: inactive.id)
        }
        print("Employees: \(created.count) (1 inactive)")
        return created
    }

    private func seedItems(warehouses: [Warehouse]) async throws -> [String: InventoryItem] {
        let seeds: [ItemSeed] = [
            ItemSeed(sku: "SKU-1001", name: "Industrial Bolts M8", description: "Boxed M8 hex bolts, 100 pack", category: "Hardware", unitOfMeasure: "boxes", quantity: 480, threshold: 100, unitCost: 12.5, warehouseIndex: 0),
            ItemSeed(sku: "SKU-1002", name: "Packing Tape 48mm", description: "Clear adhesive tape for cartons", category: "Packaging", unitOfMeasure: "rolls", quantity: 60, threshold: 80, unitCost: 3.2, warehouseIndex: 0),
            ItemSeed(sku: "SKU-1003", name: "Bubble Wrap Roll", description: "10m protective wrap", category: "Packaging", unitOfMeasure: "rolls", quantity: 12, threshold: 15, unitCost: 18.75, warehouseIndex: 0),
            ItemSeed(sku: "SKU-1004", name: "Safety Gloves L", description: "Cut-resistant handling gloves", category: "Safety", unitOfMeasure: "units", quantity: 240, threshold: 60, unitCost: 6.4, warehouseIndex: 0),
            ItemSeed(sku: "SKU-1005", name: "Steel Bracket", description: "Galvanised mounting bracket", category: "Hardware", unitOfMeasure: "units", quantity: 0, threshold: 20, unitCost: 4.1, warehouseIndex: 0),
            ItemSeed(sku: "SKU-1006", name: "Standard Wood Pallet", description: "EUR-style 1200x800 pallet", category: "Logistics", unitOfMeasure: "pallets", quantity: 300, threshold: 50, unitCost: 22.0, warehouseIndex: 0),
            ItemSeed(sku: "SKU-2001", name: "Cable Tie Pack", description: "200mm black ties, 100 pack", category: "Electrical", unitOfMeasure: "packs", quantity: 150, threshold: 40, unitCost: 5.5, warehouseIndex: 1),
            ItemSeed(sku: "SKU-2002", name: "LED Panel 600mm", description: "600x600 office ceiling panel", category: "Electrical", unitOfMeasure: "units", quantity: 45, threshold: 20, unitCost: 39.9, warehouseIndex: 1),
            ItemSeed(sku: "SKU-2003", name: "Label Rolls", description: "100x50mm thermal labels", category: "Packaging", unitOfMeasure: "rolls", quantity: 8, threshold: 25, unitCost: 9.0, warehouseIndex: 1),
            ItemSeed(sku: "SKU-2004", name: "Work Boots Size 10", description: "Steel toe safety boots", category: "Safety", unitOfMeasure: "pairs", quantity: 36, threshold: 12, unitCost: 74.0, warehouseIndex: 1),
            ItemSeed(sku: "SKU-2005", name: "Handheld Scanner", description: "Bluetooth barcode scanner", category: "Equipment", unitOfMeasure: "units", quantity: 9, threshold: 3, unitCost: 320.0, warehouseIndex: 1),
            ItemSeed(sku: "SKU-3001", name: "Shrink Wrap Film", description: "500mm machine film, per kg", category: "Packaging", unitOfMeasure: "kg", quantity: 220, threshold: 60, unitCost: 2.8, warehouseIndex: 2),
            ItemSeed(sku: "SKU-3002", name: "Storage Bin 60L", description: "Stackable plastic tote", category: "Storage", unitOfMeasure: "units", quantity: 500, threshold: 100, unitCost: 11.25, warehouseIndex: 2),
            ItemSeed(sku: "SKU-3003", name: "Forklift Battery", description: "48V traction battery", category: "Equipment", unitOfMeasure: "units", quantity: 6, threshold: 4, unitCost: 850.0, warehouseIndex: 2),
            ItemSeed(sku: "SKU-3004", name: "Conveyor Belt 2m", description: "Replacement belt section", category: "Equipment", unitOfMeasure: "units", quantity: 2, threshold: 2, unitCost: 410.0, warehouseIndex: 2)
        ]

        var items: [String: InventoryItem] = [:]
        var lowStock = 0
        for seed in seeds {
            guard seed.warehouseIndex < warehouses.count else { continue }
            let item = try await inventoryService.createItem(
                sku: seed.sku,
                name: seed.name,
                description: seed.description,
                category: seed.category,
                unitOfMeasure: seed.unitOfMeasure,
                currentQuantity: seed.quantity,
                minimumThreshold: seed.threshold,
                unitCost: seed.unitCost,
                warehouseID: warehouses[seed.warehouseIndex].id
            )
            items[seed.sku] = item
            if seed.quantity <= seed.threshold {
                lowStock += 1
            }
        }
        print("Inventory items: \(items.count) (\(lowStock) below threshold)")
        return items
    }

    private func seedMovements(items: [String: InventoryItem]) async throws {
        let seeds: [MovementSeed] = [
            MovementSeed(sku: "SKU-1001", type: .stockOut, quantity: 40, note: "Order #1024 dispatched", reference: "SO-1024"),
            MovementSeed(sku: "SKU-1004", type: .stockIn, quantity: 120, note: "Supplier delivery received", reference: "PO-8871"),
            MovementSeed(sku: "SKU-1006", type: .stockOut, quantity: 30, note: "Loading bay usage", reference: "SO-1031"),
            MovementSeed(sku: "SKU-3002", type: .adjustment, quantity: 470, note: "Cycle count variance", reference: "CC-0042"),
            MovementSeed(sku: "SKU-3001", type: .stockIn, quantity: 100, note: "Top-up from supplier", reference: "PO-8875")
        ]

        var recorded = 0
        for seed in seeds {
            guard let item = items[seed.sku] else { continue }
            _ = try await inventoryService.recordMovement(
                itemID: item.id,
                type: seed.type,
                quantity: seed.quantity,
                note: seed.note,
                referenceNumber: seed.reference
            )
            recorded += 1
        }
        print("Stock movements: \(recorded)")
    }

    private func seedTransfers(warehouses: [Warehouse], items: [String: InventoryItem]) async throws {
        let seeds: [TransferSeed] = [
            TransferSeed(
                sourceIndex: 0, destinationIndex: 2,
                lines: [(sku: "SKU-1001", quantity: 25)],
                notes: "Weekly replenishment to overflow storage",
                targetState: .draft
            ),
            TransferSeed(
                sourceIndex: 0, destinationIndex: 1,
                lines: [(sku: "SKU-1004", quantity: 50)],
                notes: "PPE restock for the north hub",
                targetState: .submitted
            ),
            TransferSeed(
                sourceIndex: 2, destinationIndex: 1,
                lines: [(sku: "SKU-3002", quantity: 100)],
                notes: "Bins for retail pick face",
                targetState: .approved
            ),
            TransferSeed(
                sourceIndex: 0, destinationIndex: 2,
                lines: [(sku: "SKU-1006", quantity: 60)],
                notes: "Pallets for south dispatch run",
                targetState: .inTransit
            ),
            TransferSeed(
                sourceIndex: 2, destinationIndex: 0,
                lines: [(sku: "SKU-3003", quantity: 2)],
                notes: "Battery swap for central forklifts",
                targetState: .completed
            ),
            TransferSeed(
                sourceIndex: 1, destinationIndex: 0,
                lines: [(sku: "SKU-2001", quantity: 20)],
                notes: "Cancelled: request withdrawn by store",
                targetState: .cancelled
            )
        ]

        var created = 0
        for seed in seeds {
            guard seed.sourceIndex < warehouses.count, seed.destinationIndex < warehouses.count else { continue }
            let lineItems: [TransferLineItem] = try seed.lines.map { line in
                guard let item = items[line.sku] else {
                    throw WMSError.validationError("Unknown seed SKU: \(line.sku)")
                }
                return TransferLineItem(inventoryItemID: item.id, requestedQuantity: line.quantity)
            }

            let order = try await transferService.createTransfer(
                sourceWarehouseID: warehouses[seed.sourceIndex].id,
                destinationWarehouseID: warehouses[seed.destinationIndex].id,
                lineItems: lineItems,
                notes: seed.notes
            )
            try await advance(order: order, to: seed.targetState)
            created += 1
        }
        print("Transfer orders: \(created) (one per workflow state)")
    }

    private func advance(order: TransferOrder, to state: TransferStatus) async throws {
        switch state {
        case .draft:
            return
        case .submitted:
            try await transferService.submitTransfer(id: order.id)
        case .approved:
            try await transferService.submitTransfer(id: order.id)
            try await transferService.approveTransfer(id: order.id)
        case .inTransit:
            try await transferService.submitTransfer(id: order.id)
            try await transferService.approveTransfer(id: order.id)
            try await transferService.executeTransfer(id: order.id)
        case .completed:
            try await transferService.submitTransfer(id: order.id)
            try await transferService.approveTransfer(id: order.id)
            try await transferService.executeTransfer(id: order.id)
            try await transferService.completeTransfer(id: order.id)
        case .cancelled:
            try await transferService.submitTransfer(id: order.id)
            try await transferService.cancelTransfer(id: order.id)
        }
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        let components = DateComponents(year: year, month: month, day: day)
        return Calendar.current.date(from: components) ?? Date()
    }
}
