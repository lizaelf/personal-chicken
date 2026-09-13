import SwiftUI

struct ProgressPips: View {
    let total: Int
    let filled: Int

    var body: some View {
        GeometryReader { geo in
            let spacing: CGFloat = 10
            let count = CGFloat(max(total, 1))
            let pipWidth = max(0, (geo.size.width - spacing * (count - 1)) / count)

            HStack(spacing: spacing) {
                ForEach(0..<total, id: \.self) { index in
                    Capsule()
                        .fill(index < filled ? Theme.coral : Color.clear)
                        .overlay {
                            Capsule().stroke(Theme.coral, lineWidth: 1)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(width: pipWidth, height: 8)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 8)
    }
}
