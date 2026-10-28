import SwiftUI

struct WorkoutControls: View {
    let isPaused: Bool
    let canGoBack: Bool
    var layoutScale: CGFloat = 1
    let onPrevious: () -> Void
    let onTogglePause: () -> Void
    let onNext: () -> Void

    var body: some View {
        let side = 76 * layoutScale
        let pause = 100 * layoutScale
        let corner = Theme.Radius.sm * layoutScale
        let pauseCorner = Theme.Radius.lg * layoutScale

        HStack(spacing: 40 * layoutScale) {
            Button(action: onPrevious) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 26 * layoutScale, weight: .semibold))
                    .foregroundStyle(canGoBack ? Theme.ink : Theme.fgRest)
                    .frame(width: side, height: side)
                    .background(
                        canGoBack ? Theme.white : Theme.bgMuted,
                        in: RoundedRectangle(cornerRadius: corner, style: .continuous)
                    )
            }
            .buttonStyle(.plain)
            .disabled(!canGoBack)
            .chickenShadow()
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
                .frame(width: 40 * layoutScale, height: 40 * layoutScale)
                .frame(width: pause, height: pause)
                .background(Theme.white, in: RoundedRectangle(cornerRadius: pauseCorner, style: .continuous))
            }
            .buttonStyle(.plain)
            .chickenShadow()
            .accessibilityLabel(isPaused ? "Resume" : "Pause")

            Button(action: onNext) {
                Image(systemName: "arrow.right")
                    .font(.system(size: 26 * layoutScale, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                    .frame(width: side, height: side)
                    .background(Theme.white, in: RoundedRectangle(cornerRadius: corner, style: .continuous))
            }
            .buttonStyle(.plain)
            .chickenShadow()
            .accessibilityLabel("Next")
        }
        .frame(maxWidth: .infinity)
    }
}
