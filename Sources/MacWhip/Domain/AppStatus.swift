import Foundation

enum AppStatus: Equatable, Sendable {
    case idle
    case listening
    case triggering
    case unsupportedHardware
    case blocked(String)

    var localizedDescription: String {
        switch self {
        case .idle: "대기 중"
        case .listening: "감지 중"
        case .triggering: "동작 실행 중"
        case .unsupportedHardware: "지원되는 물리 센서를 찾지 못함"
        case .blocked(let reason): reason
        }
    }
}
