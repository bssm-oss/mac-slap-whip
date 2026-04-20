import Foundation

final class MockSlapEventSource: SlapEventSource {
    private var continuation: AsyncStream<SlapEvent>.Continuation?
    private(set) lazy var events: AsyncStream<SlapEvent> = {
        AsyncStream { [weak self] continuation in
            self?.continuation = continuation
        }
    }()

    func start() async throws {}

    func stop() {}

    func emit(_ event: SlapEvent) {
        continuation?.yield(event)
    }
}
