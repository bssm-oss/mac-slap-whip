import SwiftUI

struct StatusMenuView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Button(appState.isListening ? "감지 중지" : "감지 시작") {
                    appState.toggleListening()
                }
                .buttonStyle(.borderedProminent)

                Text("현재 상태: \(appState.status.localizedDescription)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            GroupBox("대상 / 동작") {
                VStack(alignment: .leading, spacing: 10) {
                    Picker("대상 에이전트", selection: $appState.target) {
                        ForEach(AgentTarget.allCases) { target in
                            Text(target.localizedTitle).tag(target)
                        }
                    }

                    Picker("동작 모드", selection: $appState.actionMode) {
                        ForEach(ActionMode.allCases) { mode in
                            Text(mode.localizedTitle).tag(mode)
                        }
                    }

                    Toggle("포커스 앱 제한 해제", isOn: $appState.allowAnyFocusedApp)
                        .font(.caption)
                }
            }

            GroupBox("프롬프트") {
                VStack(alignment: .leading, spacing: 10) {
                    Picker("프리셋 문구", selection: $appState.selectedPresetID) {
                        ForEach(PhraseProvider.presets) { preset in
                            Text(preset.localizedTitle).tag(preset.id)
                        }
                        Text("사용자 지정").tag("custom")
                    }

                    if appState.target == .custom || appState.selectedPresetID == "custom" {
                        TextField("사용자 지정 문구", text: $appState.customPhrase)
                            .textFieldStyle(.roundedBorder)
                    }
                }
            }

            GroupBox("튜닝") {
                VStack(alignment: .leading, spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("민감도 \(String(format: "%.2f", appState.sensitivity))")
                            .font(.caption)
                        Slider(value: $appState.sensitivity, in: 0.05...0.5)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("쿨다운 \(String(format: "%.1f", appState.cooldown))초")
                            .font(.caption)
                        Slider(value: $appState.cooldown, in: 0.75...3.0)
                    }
                }
            }

            GroupBox("권한 / 센서 상태") {
                VStack(alignment: .leading, spacing: 6) {
                    Text("손쉬운 사용: \(appState.accessibilityGranted ? "허용됨" : "필요")")
                        .font(.caption)
                    Text("물리 센서: \(appState.detectorStatusText)")
                        .font(.caption)
                    HStack {
                        Button("권한 확인") {
                            appState.refreshPermissions(prompt: true)
                        }
                        Button("설정 열기") {
                            appState.openAccessibilitySettings()
                        }
                    }
                }
            }

            HStack {
                Button("슬랩 테스트") {
                    appState.triggerManualTest()
                }
                Button("최근 이벤트 보기") {
                    appState.showRecentEvents()
                }
                Spacer()
                Button("종료") {
                    appState.quit()
                }
            }
        }
        .padding(14)
        .frame(width: 360)
    }
}
