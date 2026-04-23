import Foundation

protocol SlapEventSource: AnyObject {
    var events: AsyncStream<SlapEvent> { get }
    func start() async throws
    func stop()
}

enum SlapEventSourceError: LocalizedError {
    case noSupportedSensor
    case helperMissing(String)
    case privilegedHelperLaunchFailed(String)

    var errorDescription: String? {
        switch self {
        case .noSupportedSensor:
            "지원되는 AppleSPUHIDDevice 가속도 센서를 찾지 못했습니다."
        case .helperMissing(let path):
            "slap-mac helper를 찾지 못했습니다: \(path)"
        case .privilegedHelperLaunchFailed(let reason):
            if reason.isEmpty {
                "관리자 권한 slap helper를 시작하지 못했습니다."
            } else {
                "관리자 권한 slap helper를 시작하지 못했습니다: \(reason)"
            }
        }
    }
}
