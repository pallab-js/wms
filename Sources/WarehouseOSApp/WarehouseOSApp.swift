import SwiftUI
import WMSFeatures

struct WarehouseOSApp: App {
    let container: DependencyContainer

    init() {
        self.container = DependencyContainer()
    }

    var body: some Scene {
        Window("WarehouseOS", id: "main") {
            ContentView()
                .environment(container.router)
                .environment(container)
                .frame(minWidth: 900, minHeight: 600)
                .onAppear {
                    NotificationManager.shared.requestPermission()
                }
        }
        .defaultSize(width: 1200, height: 800)
    }
}
