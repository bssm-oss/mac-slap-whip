import Foundation

enum IntegrationCheckRunner {
    @MainActor
    static func run(commandPhrase: String) async -> Int32 {
        let dispatcher = AgentCommandDispatcher(
            permissionManager: AccessibilityPermissionManager(),
            frontmostAppDetector: FrontmostAppDetector(),
            keyboardSender: KeyboardMacroSender()
        )

        let result = await dispatcher.performSlapAction(
            configuration: DispatchConfiguration(
                target: .activeTerminal,
                actionMode: .interruptAndPrompt,
                phrase: commandPhrase,
                allowAnyFocusedApp: false,
                fallbackTarget: nil
            ),
            intensity: 1.0
        )

        switch result {
        case .success(let dispatchResult):
            print("MacWhip integration-check dispatched: \(dispatchResult.message)")
            return EXIT_SUCCESS
        case .failure(let error):
            fputs("MacWhip integration-check failed: \(error.localizedDescription)\n", stderr)
            return EXIT_FAILURE
        }
    }
}
