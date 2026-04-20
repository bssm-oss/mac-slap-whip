import Foundation

enum SelfCheckRunner {
    @MainActor
    static func run() async {
        let debouncer = SlapDebouncer()
        let start = Date()
        precondition(debouncer.shouldAccept(at: start, cooldown: 1.0))
        precondition(!debouncer.shouldAccept(at: start.addingTimeInterval(0.5), cooldown: 1.0))
        precondition(debouncer.shouldAccept(at: start.addingTimeInterval(1.2), cooldown: 1.0))
        precondition(!PhraseProvider.phrase(for: "continue", customPhrase: "").isEmpty)
        precondition(PhraseProvider.phrase(for: "custom", customPhrase: "hello") == "hello")

        let keyboard = SelfCheckKeyboardSender()
        let dispatcher = AgentCommandDispatcher(
            permissionManager: SelfCheckPermissionManager(trusted: true),
            frontmostAppDetector: SelfCheckFrontmostDetector(app: FrontmostAppInfo(
                processIdentifier: 1,
                name: "Terminal",
                bundleIdentifier: "com.apple.Terminal"
            )),
            keyboardSender: keyboard
        )

        let result = await dispatcher.performSlapAction(
            configuration: DispatchConfiguration(
                target: .claude,
                actionMode: .interruptAndPrompt,
                phrase: "Continue.",
                allowAnyFocusedApp: false,
                fallbackTarget: nil
            ),
            intensity: 1.0
        )

        precondition({
            if case .success = result, keyboard.calls == ["ctrl+c", "text:Continue.", "return"] {
                return true
            }
            return false
        }())

        print("MacWhip self-check passed")
    }
}

@MainActor
private struct SelfCheckPermissionManager: AccessibilityPermissionManaging {
    let trusted: Bool
    func isTrusted(prompt: Bool) -> Bool { trusted }
    func openSystemSettings() {}
}

@MainActor
private struct SelfCheckFrontmostDetector: FrontmostAppDetecting {
    let app: FrontmostAppInfo?
    func current() -> FrontmostAppInfo? { app }
    func activate(_ app: FrontmostAppInfo) -> Bool { true }
}

@MainActor
private final class SelfCheckKeyboardSender: KeyboardMacroSending {
    private(set) var calls: [String] = []

    func sendControlC() async throws { calls.append("ctrl+c") }
    func sendText(_ text: String) async throws { calls.append("text:\(text)") }
    func sendReturn() async throws { calls.append("return") }
}
