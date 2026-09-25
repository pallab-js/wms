import Foundation
import WMSCore

/// Shared pagination helper. Clamps `page`/`pageSize` so callers can never trigger
/// out-of-range or overflow traps inside array slicing.
enum Pagination {
    static func page<T>(_ values: [T], page: Int, pageSize: Int) -> PaginatedResult<T> {
        let safePage = max(0, page)
        let safeSize = max(1, pageSize)
        let (rawOffset, overflow) = safePage.multipliedReportingOverflow(by: safeSize)
        let offset = overflow ? values.count : rawOffset
        let items = Array(values.dropFirst(offset).prefix(safeSize))
        return PaginatedResult(items: items, totalCount: values.count, page: safePage, pageSize: safeSize)
    }
}
