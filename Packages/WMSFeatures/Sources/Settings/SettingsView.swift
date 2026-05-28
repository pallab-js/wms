import SwiftUI
import WMSCore
import WMSDesignSystem

public struct SettingsView: View {
    let viewModel: SettingsViewModel

    public init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        Form {
            Section("Organisation") {
                TextField("Organisation Name", text: Binding(
                    get: { viewModel.organisationName },
                    set: { viewModel.organisationName = $0 }
                ))
            }

            Section("Defaults") {
                TextField("Default Unit of Measure", text: Binding(
                    get: { viewModel.defaultUnitOfMeasure },
                    set: { viewModel.defaultUnitOfMeasure = $0 }
                ))
            }

            Section("User Role") {
                Picker("Current Role", selection: Binding(
                    get: { viewModel.currentUserRole },
                    set: { viewModel.currentUserRole = $0 }
                )) {
                    ForEach(UserRole.allCases, id: \.self) { role in
                        Text(role.label).tag(role)
                    }
                }
                .pickerStyle(.radioGroup)
            }

            Section {
                Button("Save Settings") {
                    viewModel.saveSettings()
                }
            }

            if let message = viewModel.savedMessage {
                Section {
                    Text(message)
                        .foregroundColor(.wmsSuccess)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
    }
}
