import Testing
@testable import MacWhipCore

@MainActor
private struct PermissionManagerStub: AccessibilityPermissionManaging {
    let trusted: Bool
    func isTrusted(prompt: Bool) -> Bool { trusted }
    func openSystemSettings() {}
}

@MainActor
private final class KeyboardSenderSpy: KeyboardMacroSending {
    private(set) var calls: [String] = []

    func sendControlC() async throws { calls.append("ctrl+c") }
    func sendText(_ text: String) async throws { calls.append("text:\(text)") }
    func sendReturn() async throws { calls.append("return") }
}

@MainActor
private struct FrontmostDetectorStub: FrontmostAppDetecting {
    let app: FrontmostAppInfo?
    func current() -> FrontmostAppInfo? { app }
    func activate(_ app: FrontmostAppInfo) -> Bool { true }
}

@Suite @MainActor struct MockDispatcherTests {
    @Test func interruptAndPromptSendsExpectedSequence() async {
        let keyboard = KeyboardSenderSpy()
        let dispatcher = AgentCommandDispatcher(
            permissionManager: PermissionManagerStub(trusted: true),
            frontmostAppDetector: FrontmostDetectorStub(app: .init(
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

        if case .success = result {
            #expect(keyboard.calls == ["ctrl+c", "text:Continue.", "return"])
        } else {
            Issue.record("Expected successful dispatch")
        }
    }

    @Test func blocksNonTerminalAppsByDefault() async {
        let dispatcher = AgentCommandDispatcher(
            permissionManager: PermissionManagerStub(trusted: true),
            frontmostAppDetector: FrontmostDetectorStub(app: .init(
                processIdentifier: 2,
                name: "Safari",
                bundleIdentifier: "com.apple.Safari"
            )),
            keyboardSender: KeyboardSenderSpy()
        )

        let result = await dispatcher.performSlapAction(
            configuration: DispatchConfiguration(
                target: .activeTerminal,
                actionMode: .interruptOnly,
                phrase: "",
                allowAnyFocusedApp: false,
                fallbackTarget: nil
            ),
            intensity: 0.8
        )

        if case .failure(let error) = result {
            #expect(error.localizedDescription.contains("터미널"))
        } else {
            Issue.record("Expected terminal validation failure")
        }
    }
}
