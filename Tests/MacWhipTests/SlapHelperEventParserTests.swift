import Testing
@testable import MacWhipCore

@Suite struct SlapHelperEventParserTests {
    @Test func parsesSlapAmplitudeLine() {
        let event = SlapHelperEventParser.parse(
            "slap timestamp=2026-04-23T10:00:00Z amplitude=0.123000 severity=hard",
            fallbackIntensity: 0.05
        )

        #expect(event?.intensity == 0.123)
        #expect(event?.score == 0.123)
    }

    @Test func ignoresNonSlapLines() {
        let event = SlapHelperEventParser.parse("ready", fallbackIntensity: 0.05)
        #expect(event == nil)
    }
}
