import Foundation

public protocol PermissionChecking: Sendable {
    func require(_ permission: Permission) throws
}
