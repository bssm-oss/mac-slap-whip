import AppKit
import SwiftUI

@MainActor
final class HUDWindowController {
    private lazy var panel: NSPanel = {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 96),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .statusBar
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.collectionBehavior = [.canJoinAllSpaces, .transient, .fullScreenAuxiliary]
        panel.ignoresMouseEvents = true
        return panel
    }()

    private var hideTask: Task<Void, Never>?

    func show(payload: HUDPayload, target: AgentTarget, actionMode: ActionMode) {
        let rootView = TriggerHUDView(payload: payload, target: target, actionMode: actionMode)
        panel.contentViewController = NSHostingController(rootView: rootView)
        positionPanel()
        panel.orderFrontRegardless()

        hideTask?.cancel()
        hideTask = Task { [weak panel] in
            try? await Task.sleep(for: .seconds(1.2))
            await MainActor.run {
                panel?.orderOut(nil)
            }
        }
    }

    private func positionPanel() {
        guard let screen = NSScreen.main else { return }
        let frame = screen.visibleFrame
        let origin = NSPoint(x: frame.midX - 180, y: frame.maxY - 140)
        panel.setFrameOrigin(origin)
    }
}
