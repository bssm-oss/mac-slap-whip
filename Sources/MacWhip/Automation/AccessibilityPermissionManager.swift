import AppKit
@preconcurrency import ApplicationServices
import Foundation

@MainActor
protocol AccessibilityPermissionManaging {
    func isTrusted(prompt: Bool) -> Bool
    func openSystemSettings()
}

@MainActor
struct AccessibilityPermissionManager: AccessibilityPermissionManaging {
    func isTrusted(prompt: Bool) -> Bool {
        if prompt {
            let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
            let options = [promptKey: true] as CFDictionary
            return AXIsProcessTrustedWithOptions(options)
        }

        return AXIsProcessTrusted()
    }

    func openSystemSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else {
            return
        }

        NSWorkspace.shared.open(url)
    }
}
