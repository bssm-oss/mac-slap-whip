import Foundation

struct EventLogEntry: Identifiable, Sendable {
    let id = UUID()
    let timestamp: Date
    let intensity: Double
    let target: AgentTarget
    let actionMode: ActionMode
    let frontmostApp: String
    let success: Bool
    let failureReason: String?
}
