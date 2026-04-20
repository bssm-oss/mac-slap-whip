import Foundation

struct PhrasePreset: Identifiable, Sendable, Equatable {
    let id: String
    let localizedTitle: String
    let phrase: String
}

struct PhraseProvider {
    static let presets: [PhrasePreset] = [
        PhrasePreset(
            id: "continue",
            localizedTitle: "계속 진행",
            phrase: "Continue. Keep it concise and move to the next concrete step."
        ),
        PhrasePreset(
            id: "replan",
            localizedTitle: "짧게 재계획 후 실행",
            phrase: "Interrupting: summarize current state briefly, then continue with the smallest next action."
        ),
        PhrasePreset(
            id: "slow-path",
            localizedTitle: "느린 경로 중단",
            phrase: "Stop the slow path. Re-plan in 3 bullets and execute the next step."
        ),
        PhrasePreset(
            id: "focus",
            localizedTitle: "설명 줄이고 코드 진행",
            phrase: "Focus. Avoid long explanation and proceed with the code change."
        ),
        PhrasePreset(
            id: "recover",
            localizedTitle: "직전 지점부터 복구",
            phrase: "Recover from the last point and continue."
        )
    ]

    static func phrase(for presetID: String, customPhrase: String) -> String {
        if presetID == "custom" {
            return customPhrase.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return presets.first(where: { $0.id == presetID })?.phrase ?? presets[0].phrase
    }
}
