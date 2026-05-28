import Foundation
import WMSCore

@Observable
@MainActor
public final class SettingsViewModel {
    var organisationName: String = ""
    var defaultUnitOfMeasure: String = "units"
    var currentUserRole: UserRole = .administrator
    var savedMessage: String?

    private let userDefaults = UserDefaults.standard

    private enum Keys {
        static let organisationName = "wms_organisation_name"
        static let defaultUnitOfMeasure = "wms_default_unit_of_measure"
        static let currentUserRole = "wms_current_user_role"
    }

    public init() {
        loadSettings()
    }

    public func loadSettings() {
        organisationName = userDefaults.string(forKey: Keys.organisationName) ?? "My Organisation"
        defaultUnitOfMeasure = userDefaults.string(forKey: Keys.defaultUnitOfMeasure) ?? "units"
        if let roleRaw = userDefaults.string(forKey: Keys.currentUserRole),
           let role = UserRole(rawValue: roleRaw) {
            currentUserRole = role
        }
    }

    public func saveSettings() {
        userDefaults.set(organisationName, forKey: Keys.organisationName)
        userDefaults.set(defaultUnitOfMeasure, forKey: Keys.defaultUnitOfMeasure)
        userDefaults.set(currentUserRole.rawValue, forKey: Keys.currentUserRole)
        savedMessage = "Settings saved successfully."
    }
}
