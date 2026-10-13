import SwiftUI

struct WorkoutControls: View {
    let isPaused: Bool
    let canGoBack: Bool
    let isLastMove: Bool
    var layoutScale: CGFloat = 1
    let onPrevious: () -> Void
    let onTogglePause: () -> Void
    let onNext: () -> Void

    var body: some View {
        let side = 56 * layoutScale
        let pause = 72 * layoutScale
        let corner = 20 * layoutScale

        HStack(spacing: 20 * layoutScale) {
            Button(action: onPrevious) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 18 * layoutScale, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                    .frame(width: side, height: side)
                    .background(.white, in: RoundedRectangle(cornerRadius: corner, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(!canGoBack)
            .opacity(canGoBack ? 1 : 0.35)
            .shadow(color: .black.opacity(0.08), radius: 1.2 * layoutScale, y: 0.8 * layoutScale)
            .accessibilityLabel("Previous")

            Button(action: onTogglePause) {
                Group {
                    if isPaused {
                        Image("IconPlay")
                            .resizable()
                            .scaledToFit()
                    } else {
                        Image("IconPause")
                            .resizable()
                            .scaledToFit()
                    }
                }
                .frame(width: 28 * layoutScale, height: 28 * layoutScale)
                .frame(width: pause, height: pause)
                .background(.white, in: RoundedRectangle(cornerRadius: 24 * layoutScale, style: .continuous))
            }
            .buttonStyle(.plain)
            .shadow(color: .black.opacity(0.08), radius: 1.2 * layoutScale, y: 0.8 * layoutScale)
            .accessibilityLabel(isPaused ? "Resume" : "Pause")

            Button(action: onNext) {
                Image(systemName: isLastMove ? "checkmark" : "arrow.right")
                    .font(.system(size: 18 * layoutScale, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                    .frame(width: side, height: side)
                    .background(.white, in: RoundedRectangle(cornerRadius: corner, style: .continuous))
            }
            .buttonStyle(.plain)
            .shadow(color: .black.opacity(0.08), radius: 1.2 * layoutScale, y: 0.8 * layoutScale)
            .accessibilityLabel(isLastMove ? "Done" : "Next")
        }
        .frame(maxWidth: .infinity)
    }
}
