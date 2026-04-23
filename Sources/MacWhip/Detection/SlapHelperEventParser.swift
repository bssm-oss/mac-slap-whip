import Foundation

enum SlapHelperEventParser {
    static func parse(_ line: String, fallbackIntensity: Double) -> SlapEvent? {
        guard line.hasPrefix("slap ") else { return nil }

        let amplitude = line
            .split(separator: " ")
            .first { $0.hasPrefix("amplitude=") }
            .flatMap { Double($0.dropFirst("amplitude=".count)) }
            ?? fallbackIntensity

        return SlapEvent(
            timestamp: Date(),
            intensity: amplitude,
            score: amplitude,
            axisX: nil,
            axisY: nil,
            axisZ: nil
        )
    }
}
