import Foundation
import WMSCore
import WMSServices

@Observable
@MainActor
public final class ReportsViewModel {
    var data: ReportsData?
    var isLoading = false
    var errorMessage: String?
    var lastRefreshDate: Date?

    private let service: ReportsService

    public init(service: ReportsService) {
        self.service = service
    }

    public func loadReports() async {
        isLoading = true
        errorMessage = nil
        do {
            data = try await service.getReports()
            lastRefreshDate = Date()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    public func refresh() async {
        await loadReports()
    }

    public func exportCSV() -> String? {
        data?.csv
    }
}
