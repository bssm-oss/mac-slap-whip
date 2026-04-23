import Foundation

enum SPUSensorProbe {
    static func summary() -> String {
        guard ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 13 else {
            return "macOS 13 이상 필요"
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/ioreg")
        process.arguments = ["-l", "-w0"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return "센서 확인 실패"
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        return output.contains("AppleSPUHIDDevice")
            ? "AppleSPUHIDDevice 확인됨"
            : "AppleSPUHIDDevice 없음"
    }
}
