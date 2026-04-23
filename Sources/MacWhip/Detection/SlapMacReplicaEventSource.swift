import Foundation

final class SlapMacReplicaEventSource: SlapEventSource, @unchecked Sendable {
    struct Configuration: Sendable {
        var sensitivityThreshold: Double
        var cooldown: TimeInterval

        static let `default` = Configuration(
            sensitivityThreshold: 0.05,
            cooldown: 0.75
        )
    }

    private let configuration: Configuration
    private let helperURL: URL
    private let runtimeDirectory: URL
    private var continuation: AsyncStream<SlapEvent>.Continuation?
    private var pollTimer: Timer?
    private var lastReadOffset = 0
    private var started = false

    private var eventFileURL: URL { runtimeDirectory.appendingPathComponent("events.log") }
    private var readyFileURL: URL { runtimeDirectory.appendingPathComponent("ready") }
    private var stopFileURL: URL { runtimeDirectory.appendingPathComponent("stop") }
    private var launchLogURL: URL { runtimeDirectory.appendingPathComponent("launch.log") }

    private(set) lazy var events: AsyncStream<SlapEvent> = {
        AsyncStream { [weak self] continuation in
            self?.continuation = continuation
        }
    }()

    init(
        configuration: Configuration = .default,
        helperURL: URL? = SlapMacReplicaEventSource.defaultHelperURL(),
        runtimeDirectory: URL = FileManager.default.temporaryDirectory.appendingPathComponent("macwhip-slap-helper", isDirectory: true)
    ) {
        self.configuration = configuration
        self.helperURL = helperURL ?? URL(fileURLWithPath: "/Applications/MacWhip.app/Contents/Resources/MacWhipSlapHelper")
        self.runtimeDirectory = runtimeDirectory
    }

    deinit {
        stop()
    }

    func start() async throws {
        guard !started else { return }
        started = true
        lastReadOffset = 0

        try prepareRuntimeDirectory()
        try launchPrivilegedHelper()
        try await waitForReadySignal()
        startPollingEvents()
    }

    func stop() {
        guard started else { return }
        started = false
        pollTimer?.invalidate()
        pollTimer = nil
        try? FileManager.default.createDirectory(at: runtimeDirectory, withIntermediateDirectories: true)
        FileManager.default.createFile(atPath: stopFileURL.path, contents: Data())
    }

    private static func defaultHelperURL() -> URL? {
        Bundle.main.url(forResource: "MacWhipSlapHelper", withExtension: nil)
    }

    private func prepareRuntimeDirectory() throws {
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: runtimeDirectory, withIntermediateDirectories: true)

        for url in [eventFileURL, readyFileURL, stopFileURL, launchLogURL] {
            if fileManager.fileExists(atPath: url.path) {
                try fileManager.removeItem(at: url)
            }
        }

        fileManager.createFile(atPath: eventFileURL.path, contents: Data())
    }

    private func launchPrivilegedHelper() throws {
        guard FileManager.default.isExecutableFile(atPath: helperURL.path) else {
            throw SlapEventSourceError.helperMissing(helperURL.path)
        }

        let command = [
            shellQuoted(helperURL.path),
            "--threshold", shellQuoted(String(format: "%.4f", configuration.sensitivityThreshold)),
            "--cooldown", shellQuoted("\(Int(configuration.cooldown * 1000))ms"),
            "--event-file", shellQuoted(eventFileURL.path),
            "--ready-file", shellQuoted(readyFileURL.path),
            "--stop-file", shellQuoted(stopFileURL.path),
            ">>", shellQuoted(launchLogURL.path),
            "2>&1",
            "&"
        ].joined(separator: " ")

        let script = "do shell script \(appleScriptQuoted(command)) with administrator privileges"
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]

        let errorPipe = Pipe()
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let errorText = String(data: errorData, encoding: .utf8) ?? ""
            throw SlapEventSourceError.privilegedHelperLaunchFailed(errorText.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }

    private func waitForReadySignal() async throws {
        let deadline = Date().addingTimeInterval(6)
        while Date() < deadline {
            if FileManager.default.fileExists(atPath: readyFileURL.path) {
                return
            }

            if let errorLine = latestHelperErrorLine() {
                throw SlapEventSourceError.privilegedHelperLaunchFailed(errorLine)
            }

            try await Task.sleep(for: .milliseconds(150))
        }

        throw SlapEventSourceError.privilegedHelperLaunchFailed("helper did not become ready")
    }

    private func startPollingEvents() {
        pollTimer?.invalidate()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 0.12, repeats: true) { [weak self] _ in
            self?.pollEvents()
        }
    }

    private func pollEvents() {
        guard started,
              let data = try? Data(contentsOf: eventFileURL),
              data.count >= lastReadOffset
        else {
            return
        }

        let newData = data.dropFirst(lastReadOffset)
        lastReadOffset = data.count

        guard let text = String(data: newData, encoding: .utf8) else { return }
        for line in text.split(separator: "\n") {
            guard let event = parseEventLine(String(line)) else { continue }
            continuation?.yield(event)
        }
    }

    private func parseEventLine(_ line: String) -> SlapEvent? {
        SlapHelperEventParser.parse(line, fallbackIntensity: configuration.sensitivityThreshold)
    }

    private func latestHelperErrorLine() -> String? {
        guard let text = try? String(contentsOf: eventFileURL, encoding: .utf8) else { return nil }
        return text
            .split(separator: "\n")
            .last { $0.hasPrefix("error ") }
            .map(String.init)
    }

    private func appleScriptQuoted(_ value: String) -> String {
        "\"\(value.replacingOccurrences(of: "\"", with: "\\\""))\""
    }

    private func shellQuoted(_ value: String) -> String {
        "'\(value.replacingOccurrences(of: "'", with: "'\\''"))'"
    }
}
