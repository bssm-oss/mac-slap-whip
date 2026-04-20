import Foundation

@MainActor
final class EventLogStore: ObservableObject {
    @Published private(set) var entries: [EventLogEntry] = []

    func append(_ entry: EventLogEntry) {
        entries.insert(entry, at: 0)
        if entries.count > 50 {
            entries = Array(entries.prefix(50))
        }
    }
}
