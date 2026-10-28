import SwiftUI

struct ProgressPips: View {
    let total: Int
    let filled: Int
    var onSelect: ((Int) -> Void)? = nil

    var body: some View {
        HStack(spacing: 10) {
            ForEach(0..<total, id: \.self) { index in
                Capsule()
                    .fill(index < filled ? Theme.coral : Color.clear)
                    .overlay {
                        Capsule().stroke(Theme.coral, lineWidth: 1)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 8)
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onSelect?(index)
                    }
            }
        }
        .frame(maxWidth: .infinity)
        .fixedSize(horizontal: false, vertical: true)
    }
}
