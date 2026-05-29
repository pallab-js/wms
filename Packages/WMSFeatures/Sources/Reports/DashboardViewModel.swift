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

    public init(service: DashboardService) {
        self.service = service
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
}
