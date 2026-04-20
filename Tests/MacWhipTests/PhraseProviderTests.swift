import Testing
@testable import MacWhipCore

@Suite struct PhraseProviderTests {
    @Test func returnsPresetPhrase() {
        let phrase = PhraseProvider.phrase(for: "continue", customPhrase: "")
        #expect(phrase.contains("Continue"))
    }

    @Test func returnsCustomPhraseWhenSelected() {
        let phrase = PhraseProvider.phrase(for: "custom", customPhrase: "hello")
        #expect(phrase == "hello")
    }

    @Test func targetDefaultsMapToPresetAndMode() {
        #expect(AgentTarget.claude.defaultPresetID == "replan")
        #expect(AgentTarget.codex.defaultPresetID == "focus")
        #expect(AgentTarget.opencode.defaultPresetID == "slow-path")
        #expect(AgentTarget.custom.defaultActionMode == .promptOnly)
    }
}
