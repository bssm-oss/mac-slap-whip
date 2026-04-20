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

    var defaultPresetID: String {
        switch self {
        case .activeTerminal: "continue"
        case .claude: "replan"
        case .codex: "focus"
        case .opencode: "slow-path"
        case .custom: "custom"
        }
    }

    var defaultActionMode: ActionMode {
        switch self {
        case .custom: .promptOnly
        case .activeTerminal, .claude, .codex, .opencode: .interruptAndPrompt
        }
    }

    var guidanceText: String {
        switch self {
        case .activeTerminal:
            "현재 포커스된 일반 터미널 세션에 맞는 기본 프롬프트를 사용합니다."
        case .claude:
            "Claude Code 세션에 맞춰 중단 후 짧게 재계획하는 기본 프롬프트를 사용합니다."
        case .codex:
            "Codex 세션에 맞춰 설명을 줄이고 코드 진행을 재촉하는 기본 프롬프트를 사용합니다."
        case .opencode:
            "OpenCode 세션에 맞춰 느린 경로를 끊고 다음 단계를 재촉하는 기본 프롬프트를 사용합니다."
        case .custom:
            "사용자 지정 문구와 모드로 직접 동작을 결정합니다."
        }
    }
}
