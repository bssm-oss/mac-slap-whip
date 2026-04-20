import Foundation

struct DispatchResult: Sendable {
    let success: Bool
    let frontmostApp: String
    let message: String
}
