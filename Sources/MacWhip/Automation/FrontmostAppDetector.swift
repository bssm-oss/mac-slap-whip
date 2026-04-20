import AppKit
import Foundation

struct FrontmostAppInfo: Sendable, Equatable {
    let processIdentifier: pid_t
    let name: String
    let bundleIdentifier: String?

    var isMacWhip: Bool {
        bundleIdentifier == Bundle.main.bundleIdentifier
    }

    var isTerminalLike: Bool {
        guard let bundleIdentifier else { return false }
        return Self.terminalBundleIdentifiers.contains(bundleIdentifier)
    }

    static let terminalBundleIdentifiers: Set<String> = [
        "com.apple.Terminal",
        "com.googlecode.iterm2",
        "com.github.wez.wezterm",
        "org.alacritty",
        "net.kovidgoyal.kitty",
        "com.microsoft.VSCode",
        "com.todesktop.230313mzl4w4u92",
        "com.todesktop.230313mzl4w4u92.opencode",
        "com.visualstudio.code.oss",
        "com.vscodium",
        "com.cursor.Cursor"
    ]
}

@MainActor
protocol FrontmostAppDetecting {
    func current() -> FrontmostAppInfo?
    func activate(_ app: FrontmostAppInfo) -> Bool
}

@MainActor
struct FrontmostAppDetector: FrontmostAppDetecting {
    func current() -> FrontmostAppInfo? {
        guard let app = NSWorkspace.shared.frontmostApplication else { return nil }
        return FrontmostAppInfo(
            processIdentifier: app.processIdentifier,
            name: app.localizedName ?? "Unknown App",
            bundleIdentifier: app.bundleIdentifier
        )
    }

    func activate(_ app: FrontmostAppInfo) -> Bool {
        guard let runningApp = NSRunningApplication(processIdentifier: app.processIdentifier) else {
            return false
        }

        return runningApp.activate(options: [.activateIgnoringOtherApps])
    }
}
