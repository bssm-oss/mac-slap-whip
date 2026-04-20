import Foundation
import Testing
@testable import MacWhipCore

@Suite struct SlapDebouncerTests {
    @Test func blocksEventsInsideCooldownWindow() {
        let debouncer = SlapDebouncer()
        let start = Date()

        #expect(debouncer.shouldAccept(at: start, cooldown: 1.0))
        #expect(!debouncer.shouldAccept(at: start.addingTimeInterval(0.25), cooldown: 1.0))
        #expect(debouncer.shouldAccept(at: start.addingTimeInterval(1.1), cooldown: 1.0))
    }
}
