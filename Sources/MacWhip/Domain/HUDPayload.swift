import Foundation

struct HUDPayload: Sendable {
    enum Kind: Sendable {
        case success
        case ignored
        case blocked
    }

    let kind: Kind
    let title: String
    let subtitle: String
    let intensity: Double
}
