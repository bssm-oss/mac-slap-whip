import SwiftUI

struct TriggerHUDView: View {
    let payload: HUDPayload
    let target: AgentTarget
    let actionMode: ActionMode

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(payload.title)
                .font(.headline)
            Text(payload.subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
            ProgressView(value: min(max(payload.intensity, 0), 1.5), total: 1.5)
            Text("\(target.localizedTitle) · \(actionMode.localizedTitle)")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(width: 360, height: 96, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }
}
