import Foundation

struct DispatchConfiguration: Sendable {
    let target: AgentTarget
    let actionMode: ActionMode
    let phrase: String
    let allowAnyFocusedApp: Bool
    let fallbackTarget: FrontmostAppInfo?
}

enum AgentCommandError: LocalizedError {
    case accessibilityPermissionRequired
    case noFrontmostApp
    case invalidTargetApp(String)
    case dispatchFailed(String)

    var errorDescription: String? {
        switch self {
        case .accessibilityPermissionRequired:
            "손쉬운 사용 권한이 필요합니다."
        case .noFrontmostApp:
            "현재 포커스된 앱을 찾지 못했습니다."
        case .invalidTargetApp(let name):
            "현재 포커스가 터미널이 아닙니다: \(name)"
        case .dispatchFailed(let reason):
            "키보드 매크로 전송 실패: \(reason)"
        }
    }
}

struct AgentCommandDispatcher {
    let permissionManager: AccessibilityPermissionManaging
    let frontmostAppDetector: FrontmostAppDetecting
    let keyboardSender: KeyboardMacroSending

    @MainActor
    func performSlapAction(configuration: DispatchConfiguration, intensity: Double) async -> Result<DispatchResult, AgentCommandError> {
        guard permissionManager.isTrusted(prompt: false) else {
            return .failure(.accessibilityPermissionRequired)
        }

        guard var targetApp = frontmostAppDetector.current() ?? configuration.fallbackTarget else {
            return .failure(.noFrontmostApp)
        }

        if targetApp.isMacWhip, let fallbackTarget = configuration.fallbackTarget {
            _ = frontmostAppDetector.activate(fallbackTarget)
            try? await Task.sleep(for: .milliseconds(200))
            targetApp = frontmostAppDetector.current() ?? fallbackTarget
        }

        if !configuration.allowAnyFocusedApp && !targetApp.isTerminalLike {
            return .failure(.invalidTargetApp(targetApp.name))
        }

        do {
            switch configuration.actionMode {
            case .interruptOnly:
                try await keyboardSender.sendControlC()
            case .interruptAndPrompt:
                try await keyboardSender.sendControlC()
                try await Task.sleep(for: .milliseconds(300))
                try await keyboardSender.sendText(configuration.phrase)
                try await keyboardSender.sendReturn()
            case .promptOnly:
                try await keyboardSender.sendText(configuration.phrase)
                try await keyboardSender.sendReturn()
            }

            let message = "강도 \(String(format: "%.2f", intensity)) · \(targetApp.name) · \(configuration.actionMode.localizedTitle)"
            return .success(DispatchResult(success: true, frontmostApp: targetApp.name, message: message))
        } catch {
            return .failure(.dispatchFailed(error.localizedDescription))
        }
    }
}
