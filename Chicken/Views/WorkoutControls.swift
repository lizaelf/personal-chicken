import SwiftUI

struct WorkoutControls: View {
    let isPaused: Bool
    let isLastMove: Bool
    var layoutScale: CGFloat = 1
    let onTogglePause: () -> Void
    let onNext: () -> Void

    var body: some View {
        let buttonHeight = 72 * layoutScale
        let iconSize = 32 * layoutScale
        let corner = 25.125 * layoutScale

        HStack(spacing: 12 * layoutScale) {
            Button(action: onTogglePause) {
                Group {
                    if isPaused {
                        Image(systemName: "play.fill")
                            .font(.system(size: 22 * layoutScale, weight: .semibold))
                            .foregroundStyle(Theme.ink)
                    } else {
                        Image("IconPause")
                            .resizable()
                            .scaledToFit()
                            .frame(width: iconSize, height: iconSize)
                    }
                }
                .frame(width: buttonHeight, height: buttonHeight)
                .background(.white, in: RoundedRectangle(cornerRadius: corner, style: .continuous))
            }
            .buttonStyle(.plain)
            .shadow(color: .black.opacity(0.1), radius: 1.35 * layoutScale, x: 0, y: 0.9 * layoutScale)
            .accessibilityLabel(isPaused ? "Resume" : "Pause")

            Button(action: onNext) {
                HStack(spacing: 12 * layoutScale) {
                    Text(isLastMove ? "Done" : "Next")
                        .font(.workear(size: 20 * layoutScale, relativeTo: .title3))
                        .foregroundStyle(Theme.buttonCream)
                    if !isLastMove {
                        Image("IconArrow")
                            .resizable()
                            .scaledToFit()
                            .frame(width: iconSize, height: iconSize)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: buttonHeight)
                .background(Theme.coral, in: RoundedRectangle(cornerRadius: corner, style: .continuous))
            }
            .buttonStyle(.plain)
            .shadow(color: .black.opacity(0.1), radius: 1.35 * layoutScale, x: 0, y: 0.9 * layoutScale)
        }
        .frame(maxWidth: .infinity)
    }
}
