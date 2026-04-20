import Foundation
import IOKit
import IOKit.hid

final class MiyeonSlapPetAdapter: NSObject, SlapEventSource {
    struct Configuration: Sendable {
        var sensitivityThreshold: Double
        var cooldown: TimeInterval
        var baselineCalibrationDuration: TimeInterval

        static let `default` = Configuration(
            sensitivityThreshold: 0.12,
            cooldown: 0.9,
            baselineCalibrationDuration: 2.0
        )
    }

    private enum Constants {
        static let pageVendor: Int64 = 0xFF00
        static let usageAccelerometer: Int64 = 3
        static let imuReportLength = 22
        static let imuDataOffset = 6
        static let reportBufferSize = 4096
        static let reportIntervalMicros: Int32 = 1000
        static let accelScale = 65536.0
        static let decimation = 2
        static let baselineSmoothing = 0.08
    }

    private var devices: [IOHIDDevice] = []
    private var reportBuffers: [UnsafeMutablePointer<UInt8>] = []
    private var callbackContext: UnsafeMutableRawPointer?
    private var baselineMagnitude: Double?
    private var decimationCounter = 0
    private var lastAcceptedAt: TimeInterval = 0
    private var calibrationStartedAt: TimeInterval = 0
    private var started = false
    private var continuation: AsyncStream<SlapEvent>.Continuation?

    private(set) lazy var events: AsyncStream<SlapEvent> = {
        AsyncStream { [weak self] continuation in
            self?.continuation = continuation
        }
    }()

    var configuration: Configuration

    init(configuration: Configuration = .default) {
        self.configuration = configuration
    }

    deinit {
        stop()
    }

    func start() async throws {
        guard !started else { return }
        started = true
        calibrationStartedAt = ProcessInfo.processInfo.systemUptime
        callbackContext = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())

        wakeSPUDrivers()
        registerDevices()

        if devices.isEmpty {
            stop()
            throw SlapEventSourceError.noSupportedSensor
        }
    }

    func stop() {
        guard started else { return }
        started = false

        for device in devices {
            IOHIDDeviceUnscheduleFromRunLoop(device, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
            IOHIDDeviceClose(device, IOOptionBits(kIOHIDOptionsTypeNone))
        }

        devices.removeAll()
        reportBuffers.forEach { $0.deallocate() }
        reportBuffers.removeAll()
        callbackContext = nil
        baselineMagnitude = nil
        decimationCounter = 0
        lastAcceptedAt = 0
        calibrationStartedAt = 0
    }

    private func wakeSPUDrivers() {
        guard let matching = IOServiceMatching("AppleSPUHIDDriver") else { return }

        var iterator: io_iterator_t = 0
        let status = IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator)
        guard status == KERN_SUCCESS else { return }
        defer { IOObjectRelease(iterator) }

        while true {
            let service = IOIteratorNext(iterator)
            if service == 0 { break }
            defer { IOObjectRelease(service) }

            set(service: service, key: "SensorPropertyReportingState", value: 1)
            set(service: service, key: "SensorPropertyPowerState", value: 1)
            set(service: service, key: "ReportInterval", value: Constants.reportIntervalMicros)
        }
    }

    private func registerDevices() {
        guard let matching = IOServiceMatching("AppleSPUHIDDevice") else { return }

        var iterator: io_iterator_t = 0
        let status = IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator)
        guard status == KERN_SUCCESS else { return }
        defer { IOObjectRelease(iterator) }

        while true {
            let service = IOIteratorNext(iterator)
            if service == 0 { break }
            defer { IOObjectRelease(service) }

            let usagePage = integerProperty(for: service, key: "PrimaryUsagePage") ?? -1
            let usage = integerProperty(for: service, key: "PrimaryUsage") ?? -1
            guard usagePage == Constants.pageVendor, usage == Constants.usageAccelerometer else {
                continue
            }

            guard let hidDevice = IOHIDDeviceCreate(kCFAllocatorDefault, service) else {
                continue
            }

            let openStatus = IOHIDDeviceOpen(hidDevice, IOOptionBits(kIOHIDOptionsTypeNone))
            guard openStatus == kIOReturnSuccess else {
                continue
            }

            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: Constants.reportBufferSize)
            buffer.initialize(repeating: 0, count: Constants.reportBufferSize)

            reportBuffers.append(buffer)
            devices.append(hidDevice)

            IOHIDDeviceRegisterInputReportCallback(
                hidDevice,
                buffer,
                Constants.reportBufferSize,
                reportCallback,
                callbackContext
            )
            IOHIDDeviceScheduleWithRunLoop(hidDevice, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
        }
    }

    private func set(service: io_registry_entry_t, key: String, value: Int32) {
        var mutableValue = value
        guard let cfNumber = CFNumberCreate(kCFAllocatorDefault, .sInt32Type, &mutableValue) else {
            return
        }

        _ = IORegistryEntrySetCFProperty(service, key as CFString, cfNumber)
    }

    private func integerProperty(for service: io_registry_entry_t, key: String) -> Int64? {
        guard let property = IORegistryEntryCreateCFProperty(service, key as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() else {
            return nil
        }

        return (property as? NSNumber)?.int64Value
    }

    fileprivate func handleReport(_ report: UnsafeMutablePointer<UInt8>?, length: CFIndex) {
        guard started, let report, length == Constants.imuReportLength else { return }

        decimationCounter += 1
        guard decimationCounter >= Constants.decimation else { return }
        decimationCounter = 0

        let buffer = UnsafeBufferPointer(start: report, count: length)
        guard buffer.count >= Constants.imuDataOffset + 12 else { return }

        let base = Constants.imuDataOffset
        let xRaw = int32LE(buffer, offset: base)
        let yRaw = int32LE(buffer, offset: base + 4)
        let zRaw = int32LE(buffer, offset: base + 8)

        let x = Double(xRaw) / Constants.accelScale
        let y = Double(yRaw) / Constants.accelScale
        let z = Double(zRaw) / Constants.accelScale
        let magnitude = sqrt((x * x) + (y * y) + (z * z))

        if let existingBaseline = baselineMagnitude {
            baselineMagnitude = existingBaseline + ((magnitude - existingBaseline) * Constants.baselineSmoothing)
        } else {
            baselineMagnitude = magnitude
        }

        let now = ProcessInfo.processInfo.systemUptime
        guard now - calibrationStartedAt >= configuration.baselineCalibrationDuration else {
            return
        }

        guard let baselineMagnitude else { return }
        let impulse = abs(magnitude - baselineMagnitude)

        guard impulse >= configuration.sensitivityThreshold else { return }
        guard now - lastAcceptedAt >= configuration.cooldown else { return }
        lastAcceptedAt = now

        continuation?.yield(
            SlapEvent(
                timestamp: Date(),
                intensity: impulse,
                score: impulse,
                axisX: x,
                axisY: y,
                axisZ: z
            )
        )
    }

    private func int32LE(_ buffer: UnsafeBufferPointer<UInt8>, offset: Int) -> Int32 {
        let b0 = UInt32(buffer[offset])
        let b1 = UInt32(buffer[offset + 1]) << 8
        let b2 = UInt32(buffer[offset + 2]) << 16
        let b3 = UInt32(buffer[offset + 3]) << 24
        return Int32(bitPattern: b0 | b1 | b2 | b3)
    }
}

private let reportCallback: IOHIDReportCallback = {
    context,
    result,
    _,
    _,
    _,
    report,
    reportLength in

    guard result == kIOReturnSuccess, let context else {
        return
    }

    let detector = Unmanaged<MiyeonSlapPetAdapter>.fromOpaque(context).takeUnretainedValue()
    detector.handleReport(report, length: reportLength)
}
