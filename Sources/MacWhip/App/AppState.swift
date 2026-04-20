import AppKit
import Combine
import Foundation
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    @Published var isListening = false
    @Published var status: AppStatus = .idle
    @Published var target: AgentTarget = .activeTerminal {
        didSet {
            applyTargetDefaults()
        }
    }
    @Published var actionMode: ActionMode = .interruptAndPrompt
    @Published var sensitivity: Double = 0.12
    @Published var cooldown: Double = 0.9
    @Published var allowAnyFocusedApp = false
    @Published var selectedPresetID = AgentTarget.activeTerminal.defaultPresetID
    @Published var customPhrase = ""
    @Published var accessibilityGranted = false
    @Published var detectorStatusText = "미확인"
    @Published var lastHUDPayload: HUDPayload?

    let eventLogStore = EventLogStore()

    private let permissionManager: AccessibilityPermissionManaging
    private let frontmostAppDetector: FrontmostAppDetecting
    private let keyboardSender: KeyboardMacroSending
    private let hudController: HUDWindowController
    private let recentEventsController: RecentEventsWindowController
    private let debouncer = SlapDebouncer()
    private var eventSource: SlapEventSource?
    private var listenTask: Task<Void, Never>?
    private var lastExternalTarget: FrontmostAppInfo?

    init(
        permissionManager: AccessibilityPermissionManaging = AccessibilityPermissionManager(),
        frontmostAppDetector: FrontmostAppDetecting = FrontmostAppDetector(),
        keyboardSender: KeyboardMacroSending = KeyboardMacroSender(),
        hudController: HUDWindowController = HUDWindowController(),
        recentEventsController: RecentEventsWindowController? = nil
    ) {
        self.permissionManager = permissionManager
        self.frontmostAppDetector = frontmostAppDetector
        self.keyboardSender = keyboardSender
        self.hudController = hudController
        self.recentEventsController = recentEventsController ?? RecentEventsWindowController(eventLogStore: eventLogStore)
        applyTargetDefaults()
        refreshPermissions()
        refreshDetectorStatus()
    }

    var selectedPhrase: String {
        PhraseProvider.phrase(for: selectedPresetID, customPhrase: customPhrase)
    }

    func refreshPermissions(prompt: Bool = false) {
        accessibilityGranted = permissionManager.isTrusted(prompt: prompt)
    }

    func openAccessibilitySettings() {
        permissionManager.openSystemSettings()
    }

    func captureCurrentExternalTarget() {
        guard let app = frontmostAppDetector.current(), !app.isMacWhip else { return }
        lastExternalTarget = app
    }

    func toggleListening() {
        if isListening {
            stopListening()
        } else {
            Task {
                await startListening()
            }
        }
    }

    func startListening() async {
        guard !isListening else { return }
        refreshPermissions()
        let source = MiyeonSlapPetAdapter(configuration: .init(
            sensitivityThreshold: sensitivity,
            cooldown: cooldown,
            baselineCalibrationDuration: 2.0
        ))

        do {
            try await source.start()
            detectorStatusText = "물리 센서 연결됨"
            eventSource = source
            isListening = true
            status = .listening
            debouncer.reset()

            listenTask = Task { [weak self, weak source] in
                guard let self, let source else { return }
                for await event in source.events {
                    await self.handleIncomingEvent(event)
                }
            }
        } catch {
            detectorStatusText = error.localizedDescription
            status = .unsupportedHardware
            isListening = false
        }
    }

    func stopListening() {
        listenTask?.cancel()
        listenTask = nil
        eventSource?.stop()
        eventSource = nil
        isListening = false
        status = .idle
    }

    func triggerManualTest() {
        captureCurrentExternalTarget()
        Task {
            await handleIncomingEvent(.manualTest())
        }
    }

    func showRecentEvents() {
        recentEventsController.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func quit() {
        NSApp.terminate(nil)
    }

    func refreshDetectorStatus() {
        detectorStatusText = "대기 중"
    }

    private func applyTargetDefaults() {
        actionMode = target.defaultActionMode
        if target == .custom {
            selectedPresetID = "custom"
        } else {
            selectedPresetID = target.defaultPresetID
        }
    }

    private func handleIncomingEvent(_ event: SlapEvent) async {
        guard debouncer.shouldAccept(at: event.timestamp, cooldown: cooldown) else {
            publishHUD(
                HUDPayload(kind: .ignored, title: "무시됨", subtitle: "쿨다운 적용 중", intensity: event.intensity)
            )
            return
        }

        status = .triggering
        let dispatcher = AgentCommandDispatcher(
            permissionManager: permissionManager,
            frontmostAppDetector: frontmostAppDetector,
            keyboardSender: keyboardSender
        )

        let config = DispatchConfiguration(
            target: target,
            actionMode: actionMode,
            phrase: selectedPhrase,
            allowAnyFocusedApp: allowAnyFocusedApp,
            fallbackTarget: lastExternalTarget
        )

        let result = await dispatcher.performSlapAction(configuration: config, intensity: event.intensity)
        switch result {
        case .success(let dispatchResult):
            status = isListening ? .listening : .idle
            let payload = HUDPayload(
                kind: .success,
                title: "SLAP detected",
                subtitle: dispatchResult.message,
                intensity: event.intensity
            )
            publishHUD(payload)
            eventLogStore.append(
                EventLogEntry(
                    timestamp: event.timestamp,
                    intensity: event.intensity,
                    target: target,
                    actionMode: actionMode,
                    frontmostApp: dispatchResult.frontmostApp,
                    success: true,
                    failureReason: nil
                )
            )
        case .failure(let error):
            status = .blocked(error.localizedDescription)
            let payload = HUDPayload(
                kind: .blocked,
                title: "실행 실패",
                subtitle: error.localizedDescription,
                intensity: event.intensity
            )
            publishHUD(payload)
            eventLogStore.append(
                EventLogEntry(
                    timestamp: event.timestamp,
                    intensity: event.intensity,
                    target: target,
                    actionMode: actionMode,
                    frontmostApp: frontmostAppDetector.current()?.name ?? lastExternalTarget?.name ?? "Unknown App",
                    success: false,
                    failureReason: error.localizedDescription
                )
            )
        }
    }

    private func publishHUD(_ payload: HUDPayload) {
        lastHUDPayload = payload
        hudController.show(payload: payload, target: target, actionMode: actionMode)
    }
}
