import AppKit
import SwiftUI

@MainActor
final class RecentEventsWindowController: NSWindowController {
    init(eventLogStore: EventLogStore) {
        let hostingController = NSHostingController(rootView: RecentEventsView(eventLogStore: eventLogStore))
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 420),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "최근 이벤트"
        window.contentViewController = hostingController
        window.isReleasedWhenClosed = false
        super.init(window: window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct RecentEventsView: View {
    @ObservedObject var eventLogStore: EventLogStore

    var body: some View {
        List(eventLogStore.entries) { entry in
            VStack(alignment: .leading, spacing: 4) {
                Text("\(entry.frontmostApp) · \(entry.target.localizedTitle) · \(entry.actionMode.localizedTitle)")
                    .font(.headline)
                Text(entry.timestamp.formatted(date: .abbreviated, time: .standard))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("강도 \(String(format: "%.3f", entry.intensity))")
                    .font(.caption)
                if let failureReason = entry.failureReason {
                    Text("실패: \(failureReason)")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            .padding(.vertical, 4)
        }
    }
}
