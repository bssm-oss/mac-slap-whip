import Foundation

final class SlapDebouncer {
    private var lastAcceptedAt: Date?

    func shouldAccept(at date: Date, cooldown: TimeInterval) -> Bool {
        guard let lastAcceptedAt else {
            self.lastAcceptedAt = date
            return true
        }

        guard date.timeIntervalSince(lastAcceptedAt) >= cooldown else {
            return false
        }

        self.lastAcceptedAt = date
        return true
    }

    func reset() {
        lastAcceptedAt = nil
    }
}
