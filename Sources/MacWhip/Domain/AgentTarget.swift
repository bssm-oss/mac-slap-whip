import Foundation

enum AgentTarget: String, CaseIterable, Identifiable, Sendable {
    case activeTerminal
    case claude
    case codex
    case opencode
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .activeTerminal: "Active Terminal"
        case .claude: "Claude Code"
        case .codex: "Codex"
        case .opencode: "OpenCode"
        case .custom: "Custom"
        }
    }

    var localizedTitle: String {
        switch self {
        case .activeTerminal: "활성 터미널"
        case .claude: "Claude Code"
        case .codex: "Codex"
        case .opencode: "OpenCode"
        case .custom: "사용자 지정"
        }
    }
}
