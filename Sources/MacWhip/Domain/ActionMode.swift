import Foundation

enum ActionMode: String, CaseIterable, Identifiable, Sendable {
    case interruptOnly
    case interruptAndPrompt
    case promptOnly

    var id: String { rawValue }

    var localizedTitle: String {
        switch self {
        case .interruptOnly: "중단만"
        case .interruptAndPrompt: "중단 후 문구"
        case .promptOnly: "문구만"
        }
    }
}
