import Foundation

protocol SlapEventSource: AnyObject {
    var events: AsyncStream<SlapEvent> { get }
    func start() async throws
    func stop()
}

enum SlapEventSourceError: LocalizedError {
    case noSupportedSensor

    var errorDescription: String? {
        switch self {
        case .noSupportedSensor:
            "지원되는 AppleSPUHIDDevice 가속도 센서를 찾지 못했습니다."
        }
    }
}
