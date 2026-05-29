import Foundation
import WMSCore
import WMSData
import WMSServices
import WMSFeatures

@Observable
@MainActor
final class DependencyContainer {
    let store: WMSDataStore
    let router: AppRouter

    let warehouseRepository: FileWarehouseRepository
    let inventoryItemRepository: FileInventoryItemRepository
    let stockMovementRepository: FileStockMovementRepository
    let employeeRepository: FileEmployeeRepository
    let transferOrderRepository: FileTransferOrderRepository
    let auditRepository: FileAuditRepository
    let alertRepository: FileAlertRepository

    let warehouseService: WarehouseService
    let inventoryService: InventoryService
    let inventoryAlertService: InventoryAlertService
    let employeeService: EmployeeService
    let transferService: TransferService
    let dashboardService: DashboardService
    let stockMovementService: StockMovementService
    let auditLogger: AuditLogger
    let auditLogService: AuditLogService

    let accessController: AccessController
    let settingsViewModel: SettingsViewModel

    init() {
        let dataProtector = KeychainDataProtector()
        self.store = WMSDataStore(dataProtector: dataProtector)
        self.router = AppRouter()
        self.accessController = AccessController()

        self.warehouseRepository = FileWarehouseRepository(store: store)
        self.inventoryItemRepository = FileInventoryItemRepository(store: store)
        self.stockMovementRepository = FileStockMovementRepository(store: store)
        self.employeeRepository = FileEmployeeRepository(store: store)
        self.transferOrderRepository = FileTransferOrderRepository(store: store)
        self.auditRepository = FileAuditRepository(store: store)
        self.alertRepository = FileAlertRepository(store: store)

        self.auditLogger = AuditLogger(repository: auditRepository)
        self.auditLogService = AuditLogService(repository: auditRepository)
        self.inventoryAlertService = InventoryAlertService(alertRepository: alertRepository)

        self.inventoryService = InventoryService(
            itemRepository: inventoryItemRepository,
            movementRepository: stockMovementRepository,
            alertService: inventoryAlertService,
            auditLogger: auditLogger,
            accessController: accessController
        )
        self.warehouseService = WarehouseService(
            repository: warehouseRepository,
            inventoryService: inventoryService,
            auditLogger: auditLogger,
            accessController: accessController
        )
        self.employeeService = EmployeeService(
            repository: employeeRepository,
            auditLogger: auditLogger,
            accessController: accessController
        )
        self.transferService = TransferService(
            transferRepository: transferOrderRepository,
            itemRepository: inventoryItemRepository,
            auditLogger: auditLogger,
            accessController: accessController
        )
        self.stockMovementService = StockMovementService(
            movementRepository: stockMovementRepository
        )
        self.dashboardService = DashboardService(
            warehouseRepository: warehouseRepository,
            inventoryService: inventoryService,
            movementService: stockMovementService,
            employeeService: employeeService,
            transferService: transferService,
            alertService: inventoryAlertService
        )
        self.settingsViewModel = SettingsViewModel(
            onRoleChanged: { [weak accessController, weak auditLogger] role in
                accessController?.currentUserRole = role
                auditLogger?.currentUserRole = role.rawValue
            }
        )
        accessController.currentUserRole = settingsViewModel.currentUserRole
        auditLogger.currentUserRole = settingsViewModel.currentUserRole.rawValue
    }
}
