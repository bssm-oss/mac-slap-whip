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
}
