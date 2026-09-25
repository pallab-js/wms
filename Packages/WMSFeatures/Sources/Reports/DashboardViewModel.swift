import Foundation
import WMSCore
import WMSServices

@Observable
@MainActor
public final class DashboardViewModel {
    var data: DashboardData?
    var isLoading = false
    var errorMessage: String?
    var lastRefreshDate: Date?

    private let service: DashboardService
    private let alertService: InventoryAlertService

    public init(service: DashboardService, alertService: InventoryAlertService) {
        self.service = service
        self.alertService = alertService
    }

    public func loadDashboard() async {
        isLoading = true
        errorMessage = nil
        do {
            data = try await service.getDashboardData()
            lastRefreshDate = Date()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    public func refresh() async {
        await loadDashboard()
    }

    public func acknowledgeAlert(id: UUID) async {
        do {
            try await alertService.acknowledgeAlert(id: id)
            await loadDashboard()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
