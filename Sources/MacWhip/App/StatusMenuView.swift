import SwiftUI

struct StatusMenuView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            QuickWhipCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("MACWHIP")
                                .font(.system(size: 19, weight: .bold, design: .monospaced))
                                .foregroundStyle(.white)

                            Text(appState.selectedPhrase)
                                .font(.system(size: 28, weight: .bold, design: .monospaced))
                                .foregroundStyle(Color(red: 1.00, green: 0.62, blue: 0.04))
                        }

                        Spacer()

                        StatusBadge(
                            text: appState.isListening ? "감지 중" : "대기",
                            tint: appState.isListening
                                ? Color(red: 0.19, green: 0.82, blue: 0.34)
                                : Color.white.opacity(0.42)
                        )
                    }

                    Button(appState.isListening ? "감지 중지" : "감지 시작") {
                        appState.toggleListening()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(red: 1.00, green: 0.62, blue: 0.04))
                }
            }

            QuickWhipCard {
                VStack(alignment: .leading, spacing: 10) {
                    StatusRow(
                        title: "현재 상태",
                        value: appState.status.localizedDescription,
                        tint: Color(red: 0.00, green: 0.48, blue: 1.00)
                    )
                    StatusRow(
                        title: "손쉬운 사용",
                        value: appState.accessibilityGranted ? "허용됨" : "필요",
                        tint: appState.accessibilityGranted
                            ? Color(red: 0.19, green: 0.82, blue: 0.34)
                            : Color(red: 1.00, green: 0.23, blue: 0.19)
                    )
                    StatusRow(
                        title: "물리 센서",
                        value: appState.detectorStatusText,
                        tint: Color(red: 1.00, green: 0.62, blue: 0.04)
                    )

                    HStack {
                        Button("권한 확인") {
                            appState.refreshPermissions(prompt: true)
                        }
                        Button("설정 열기") {
                            appState.openAccessibilitySettings()
                        }
                    }
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                }
            }

            QuickWhipCard {
                DisclosureGroup("감도 / 쿨다운 조절") {
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("민감도 \(String(format: "%.2f", appState.sensitivity))")
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundStyle(Color.white.opacity(0.70))
                            Slider(value: $appState.sensitivity, in: 0.05...0.5)
                                .tint(Color(red: 1.00, green: 0.62, blue: 0.04))
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("쿨다운 \(String(format: "%.1f", appState.cooldown))초")
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundStyle(Color.white.opacity(0.70))
                            Slider(value: $appState.cooldown, in: 0.75...3.0)
                                .tint(Color(red: 0.00, green: 0.48, blue: 1.00))
                        }
                    }
                    .padding(.top, 10)
                }
                .tint(Color.white)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white)
            }

            HStack {
                Button("채찍 테스트") {
                    appState.triggerManualTest()
                }
                Button("최근 이벤트") {
                    appState.showRecentEvents()
                }
                Spacer()
                Button("종료") {
                    appState.quit()
                }
            }
            .font(.system(size: 12, weight: .medium, design: .monospaced))
        }
        .padding(14)
        .frame(width: 392)
        .background(Color(red: 0.13, green: 0.11, blue: 0.11))
        .preferredColorScheme(.dark)
    }
}

private struct QuickWhipCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            content
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(red: 0.19, green: 0.17, blue: 0.17))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

private struct StatusBadge: View {
    let text: String
    let tint: Color

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold, design: .monospaced))
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(tint.opacity(0.12), in: Capsule())
            .overlay(
                Capsule()
                    .stroke(tint.opacity(0.26), lineWidth: 1)
            )
    }
}

private struct StatusRow: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(title)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.54))
                .frame(width: 76, alignment: .leading)

            Text(value)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(.white)
                .lineLimit(2)

            Spacer(minLength: 0)

            Circle()
                .fill(tint)
                .frame(width: 8, height: 8)
                .shadow(color: tint.opacity(0.4), radius: 5)
        }
    }
}
