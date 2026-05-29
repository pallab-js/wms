import Foundation
import os
import WMSCore

public final class AccessController: @unchecked Sendable, PermissionChecking {
    private let lock = OSAllocatedUnfairLock()
    private var _currentUserRole: UserRole

    public var currentUserRole: UserRole {
        get { lock.withLock { _currentUserRole } }
        set { lock.withLock { _currentUserRole = newValue } }
    }

    public init(initialRole: UserRole = .inventoryClerk) {
        self._currentUserRole = initialRole
    }

    public func require(_ permission: Permission) throws {
        let role = currentUserRole
        guard role.permissions.contains(permission) else {
            throw WMSError.unauthorised
        }
    }
}

public struct NullPermissionChecker: PermissionChecking {
    public init() {}
    public func require(_ permission: Permission) throws {}
}
