import Foundation

struct SlapEvent: Sendable {
    let timestamp: Date
    let intensity: Double
    let score: Double
    let axisX: Double?
    let axisY: Double?
    let axisZ: Double?

    static func manualTest(intensity: Double = 1.0) -> SlapEvent {
        SlapEvent(
            timestamp: Date(),
            intensity: intensity,
            score: intensity,
            axisX: nil,
            axisY: nil,
            axisZ: nil
        )
    }
}
