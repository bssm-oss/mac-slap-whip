import AppKit
import Foundation

public enum MacWhipEntrypoint {
    @MainActor
    public static func run(arguments: [String]) async -> Never {
        if arguments.contains("--self-check") {
            await SelfCheckRunner.run()
            Foundation.exit(EXIT_SUCCESS)
        }

        if let integrationIndex = arguments.firstIndex(of: "--integration-check") {
            let phrase = arguments.indices.contains(integrationIndex + 1)
                ? arguments[integrationIndex + 1]
                : "echo MACWHIP_INTEGRATION_CHECK"
            let exitCode = await IntegrationCheckRunner.run(commandPhrase: phrase)
            Foundation.exit(exitCode)
        }

        let application = NSApplication.shared
        let delegate = AppDelegate()
        application.delegate = delegate
        application.run()
        Foundation.exit(EXIT_SUCCESS)
    }
}
