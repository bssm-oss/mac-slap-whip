import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let appState = AppState()
    private var menuBarController: MenuBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        menuBarController = MenuBarController(appState: appState)
        menuBarController?.start()
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        appState.refreshPermissions()
    }

    func applicationWillTerminate(_ notification: Notification) {
        appState.stopListening()
    }
}
