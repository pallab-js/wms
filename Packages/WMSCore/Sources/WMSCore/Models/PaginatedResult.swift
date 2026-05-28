import Foundation

public struct PaginatedResult<T: Sendable>: Sendable {
    public let items: [T]
    public let totalCount: Int
    public let page: Int
    public let pageSize: Int

    public var totalPages: Int {
        guard pageSize > 0 else { return 0 }
        return (totalCount + pageSize - 1) / pageSize
    }

    public var hasNextPage: Bool {
        page < totalPages - 1
    }

    public var hasPreviousPage: Bool {
        page > 0
    }

    public init(items: [T], totalCount: Int, page: Int, pageSize: Int) {
        self.items = items
        self.totalCount = totalCount
        self.page = page
        self.pageSize = pageSize
    }
}
