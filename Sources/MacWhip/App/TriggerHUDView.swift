import SwiftUI

struct TriggerHUDView: View {
    let payload: HUDPayload

    @State private var isVisible = false

    private var accentColor: Color {
        switch payload.kind {
        case .success:
            Color(red: 1.00, green: 0.62, blue: 0.04)
        case .ignored:
            Color(red: 0.60, green: 0.60, blue: 0.60)
        case .blocked:
            Color(red: 1.00, green: 0.23, blue: 0.19)
        }
    }

    var body: some View {
        HStack(spacing: 18) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.04))

                WhipStrikeMark(tint: accentColor, isVisible: isVisible)
                    .padding(18)
            }
            .frame(width: 132, height: 116)

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Text(payload.title)
                        .font(.system(size: 17, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.white)

                    Text(kindLabel)
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(accentColor.opacity(0.16), in: Capsule())
                        .overlay(
                            Capsule()
                                .stroke(accentColor.opacity(0.32), lineWidth: 1)
                        )
                        .foregroundStyle(accentColor)
                }

                if payload.kind == .success {
                    Text("\"\(PhraseProvider.quickWhipPhrase)\"")
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.white)
                }

                Text(payload.subtitle)
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.74))
                    .lineLimit(2)

                VStack(alignment: .leading, spacing: 6) {
                    Text("IMPACT \(String(format: "%.2f", payload.intensity))")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.55))

                    ImpactMeter(intensity: payload.intensity, tint: accentColor)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(18)
        .frame(width: 440, height: 156, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(red: 0.13, green: 0.11, blue: 0.11))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
        .overlay(alignment: .bottomLeading) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [accentColor.opacity(0.55), accentColor.opacity(0.0)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 3)
                .clipShape(Capsule())
                .padding(.horizontal, 18)
                .padding(.bottom, 10)
        }
        .shadow(color: accentColor.opacity(0.14), radius: 18, y: 10)
        .scaleEffect(isVisible ? 1.0 : 0.96)
        .opacity(isVisible ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.78)) {
                isVisible = true
            }
        }
    }

    private var kindLabel: String {
        switch payload.kind {
        case .success:
            "WHIP"
        case .ignored:
            "WAIT"
        case .blocked:
            "BLOCKED"
        }
    }
}

private struct ImpactMeter: View {
    let intensity: Double
    let tint: Color

    private var progress: Double {
        min(max(intensity, 0), 1.5) / 1.5
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.08))

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [tint.opacity(0.75), tint],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * progress)
            }
        }
        .frame(height: 8)
    }
}

private struct WhipStrikeMark: View {
    let tint: Color
    let isVisible: Bool

    var body: some View {
        ZStack {
            WhipStrikeShape()
                .trim(from: 0, to: isVisible ? 1.0 : 0.16)
                .stroke(
                    tint.opacity(0.28),
                    style: StrokeStyle(lineWidth: 9, lineCap: .round, lineJoin: .round)
                )
                .blur(radius: 8)

            WhipStrikeShape()
                .trim(from: 0, to: isVisible ? 1.0 : 0.08)
                .stroke(
                    tint,
                    style: StrokeStyle(lineWidth: 5.5, lineCap: .round, lineJoin: .round)
                )

            Circle()
                .fill(tint)
                .frame(width: isVisible ? 16 : 6, height: isVisible ? 16 : 6)
                .blur(radius: isVisible ? 0 : 5)
                .offset(x: 28, y: 18)

            ForEach(0..<5, id: \.self) { index in
                Capsule()
                    .fill(tint.opacity(isVisible ? 0.95 : 0.0))
                    .frame(width: 22, height: 3)
                    .rotationEffect(.degrees(Double(index) * 26 - 42))
                    .offset(x: 42 + CGFloat(index * 2), y: 22 - CGFloat(index * 6))
            }
        }
        .animation(.easeOut(duration: 0.26), value: isVisible)
    }
}

private struct WhipStrikeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.16, y: rect.minY + rect.height * 0.78))
        path.addCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.48, y: rect.minY + rect.height * 0.20),
            control1: CGPoint(x: rect.minX + rect.width * 0.24, y: rect.minY + rect.height * 0.74),
            control2: CGPoint(x: rect.minX + rect.width * 0.34, y: rect.minY + rect.height * 0.18)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.82, y: rect.minY + rect.height * 0.70),
            control1: CGPoint(x: rect.minX + rect.width * 0.62, y: rect.minY + rect.height * 0.24),
            control2: CGPoint(x: rect.minX + rect.width * 0.72, y: rect.minY + rect.height * 0.58)
        )
        return path
    }
}
