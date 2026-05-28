import SwiftUI
import WMSFeatures
import WMSCore
import WMSServices

struct ContentView: View {
    @Environment(AppRouter.self) private var router
    @Environment(DependencyContainer.self) private var container

    var body: some View {
        @Bindable var router = router

        NavigationSplitView {
            List(AppSection.allCases, selection: $router.selectedSection) { section in
                Label(section.label, systemImage: section.icon)
                    .tag(section)
            }
            .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 300)
            .navigationTitle("WarehouseOS")
        } detail: {
            switch router.selectedSection {
            case .warehouses:
                WarehouseListContent(viewModel: WarehouseListViewModel(service: container.warehouseService))
            case .inventory:
                InventoryListContent(
                    viewModel: InventoryListViewModel(service: container.inventoryService),
                    warehouseService: container.warehouseService
                )
            case .employees:
                EmployeeListContent(viewModel: EmployeeListViewModel(service: container.employeeService))
            case .transfers:
                TransferListContent(
                    viewModel: TransferListViewModel(transferService: container.transferService, warehouseService: container.warehouseService, inventoryService: container.inventoryService),
                    warehouseService: container.warehouseService
                )
            case .reports:
                DashboardContent(viewModel: DashboardViewModel(service: container.dashboardService))
            case .auditLog:
                AuditLogContent(auditLogService: container.auditLogService)
            case .settings:
                SettingsContent(viewModel: container.settingsViewModel)
            case .none:
                ContentUnavailableView(
                    "Select a Section",
                    systemImage: "sidebar.left",
                    description: Text("Choose a section from the sidebar.")
                )
            }
        }
        .frame(minWidth: 900, minHeight: 600)
        .sheet(isPresented: $router.showSearch) {
            GlobalSearchView(
                warehouseService: container.warehouseService,
                inventoryService: container.inventoryService,
                employeeService: container.employeeService
            )
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    router.showSearch = true
                } label: {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .accessibilityLabel("Global search")
                .keyboardShortcut("f", modifiers: [.command])
            }
        }
    }
}

struct WarehouseListContent: View {
    @State var viewModel: WarehouseListViewModel

    var body: some View {
        WarehouseListView(viewModel: viewModel)
            .task { await viewModel.loadWarehouses() }
    }
}

struct InventoryListContent: View {
    @State var viewModel: InventoryListViewModel
    let warehouseService: WarehouseService

    @State private var warehouses: [Warehouse] = []

    var body: some View {
        InventoryListView(viewModel: viewModel, warehouses: $warehouses)
            .task {
                warehouses = (try? await warehouseService.getAllWarehouses()) ?? []
                await viewModel.loadItems()
            }
    }
}

struct EmployeeListContent: View {
    @State var viewModel: EmployeeListViewModel

    var body: some View {
        EmployeeListView(viewModel: viewModel)
            .task { await viewModel.loadEmployees() }
    }
}

struct TransferListContent: View {
    @State var viewModel: TransferListViewModel
    let warehouseService: WarehouseService

    @State private var warehouses: [Warehouse] = []

    var body: some View {
        TransferListView(viewModel: viewModel, warehouses: $warehouses)
            .task {
                warehouses = (try? await warehouseService.getAllWarehouses()) ?? []
                await viewModel.loadTransfers()
                await viewModel.loadInventoryItems()
            }
    }
}

struct DashboardContent: View {
    @State var viewModel: DashboardViewModel

    var body: some View {
        DashboardView(viewModel: viewModel)
            .task { await viewModel.loadDashboard() }
    }
}

struct AuditLogContent: View {
    let auditLogService: AuditLogService

    var body: some View {
        AuditLogView(auditService: auditLogService)
    }
}

struct SettingsContent: View {
    @State var viewModel: SettingsViewModel

    var body: some View {
        SettingsView(viewModel: viewModel)
    }
}
