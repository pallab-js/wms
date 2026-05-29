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

    let settingsViewModel: SettingsViewModel

    init() {
        self.store = WMSDataStore()
        self.router = AppRouter()

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
            auditLogger: auditLogger
        )
        self.warehouseService = WarehouseService(
            repository: warehouseRepository,
            inventoryService: inventoryService,
            auditLogger: auditLogger
        )
        self.employeeService = EmployeeService(
            repository: employeeRepository,
            auditLogger: auditLogger
        )
        self.transferService = TransferService(
            transferRepository: transferOrderRepository,
            itemRepository: inventoryItemRepository,
            auditLogger: auditLogger
        )
        self.stockMovementService = StockMovementService(
            movementRepository: stockMovementRepository
        )
        self.dashboardService = DashboardService(
            warehouseRepository: warehouseRepository,
            inventoryService: inventoryService,
            movementService: stockMovementService
        )
        self.settingsViewModel = SettingsViewModel(
            onRoleChanged: { [weak auditLogger] role in
                auditLogger?.currentUserRole = role.rawValue
            }
        )
        auditLogger.currentUserRole = settingsViewModel.currentUserRole.rawValue
    }
}
