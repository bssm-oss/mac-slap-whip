import Testing
@testable import MacWhipCore

@Suite struct PhraseProviderTests {
    @Test func exposesQuickWhipPhrase() {
        #expect(PhraseProvider.quickWhipPhrase == "더 빨리!!")
    }

    @Test func activeTerminalStillUsesInterruptAndPrompt() {
        #expect(AgentTarget.activeTerminal.defaultActionMode == .interruptAndPrompt)
    }
}
