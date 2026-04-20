import SwiftUI

struct PermissionView: View {
    let accessibilityGranted: Bool
    let detectorStatusText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("손쉬운 사용: \(accessibilityGranted ? "허용됨" : "필요")")
            Text("물리 센서: \(detectorStatusText)")
        }
        .font(.caption)
    }
}
