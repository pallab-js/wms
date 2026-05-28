import SwiftUI
import WMSFeatures

@main
struct WarehouseOSApp: App {
    let container: DependencyContainer

    init() {
        self.container = DependencyContainer()
    }

    var body: some Scene {
        WindowGroup {
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
