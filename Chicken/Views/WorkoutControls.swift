import SwiftUI

struct WorkoutControls: View {
    let isPaused: Bool
    let isLastMove: Bool
    let onTogglePause: () -> Void
    let onNext: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onTogglePause) {
                Group {
                    if isPaused {
                        Image(systemName: "play.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(Theme.ink)
                    } else {
                        Image("IconPause")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                    }
                }
                .frame(width: 72, height: 72)
                .background(.white, in: RoundedRectangle(cornerRadius: 25.125, style: .continuous))
            }
            .buttonStyle(.plain)
            .shadow(color: .black.opacity(0.1), radius: 1.35, x: 0, y: 0.9)
            .accessibilityLabel(isPaused ? "Resume" : "Pause")

            Button(action: onNext) {
                HStack(spacing: 12) {
                    Text(isLastMove ? "Done" : "Next")
                        .font(.workear(size: 20, relativeTo: .title3))
                        .foregroundStyle(Theme.buttonCream)
                    if !isLastMove {
                        Image("IconArrow")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 72)
                .background(Theme.coral, in: RoundedRectangle(cornerRadius: 25.125, style: .continuous))
            }
            .buttonStyle(.plain)
            .shadow(color: .black.opacity(0.1), radius: 1.35, x: 0, y: 0.9)
        }
    }
}
