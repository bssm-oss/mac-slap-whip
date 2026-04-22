import AppKit
import SwiftUI

@MainActor
final class MenuBarController: NSObject {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let popover = NSPopover()
    private let appState: AppState

    init(appState: AppState) {
        self.appState = appState
        super.init()
    }

    func start() {
        if let button = statusItem.button {
            if let iconURL = Bundle.module.url(forResource: "MenuBarIconTemplate", withExtension: "png"),
               let image = NSImage(contentsOf: iconURL) {
                image.isTemplate = true
                image.size = NSSize(width: 18, height: 18)
                button.image = image
                button.imagePosition = .imageOnly
            } else {
                button.title = "MW"
            }
            button.toolTip = "MacWhip"
            button.target = self
            button.action = #selector(togglePopover(_:))
        }

        popover.behavior = .semitransient
        popover.contentSize = NSSize(width: 360, height: 520)
        popover.contentViewController = NSHostingController(rootView: StatusMenuView(appState: appState))
    }

    @objc private func togglePopover(_ sender: AnyObject?) {
        guard let button = statusItem.button else { return }

        if popover.isShown {
            popover.performClose(sender)
        } else {
            appState.captureCurrentExternalTarget()
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
}
