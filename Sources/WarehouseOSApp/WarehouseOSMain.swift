import Foundation

@main
enum WarehouseOSMain {
    static func main() {
        let arguments = Array(CommandLine.arguments.dropFirst())

        if arguments.contains("--help") || arguments.contains("-h") {
            print(SeedCommand.usageText)
            return
        }

        if arguments.contains("--seed") {
            Task.detached {
                let status = await SeedCommand.run(arguments: arguments)
                exit(status)
            }
            dispatchMain()
        }

        WarehouseOSApp.main()
    }
}
