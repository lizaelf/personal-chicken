import SwiftUI

struct WorkoutView: View {
    let session: WorkoutSession

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Move \(session.currentIndex + 1) of \(session.moves.count)")
                    .font(.workear(size: 12, relativeTo: .caption))
                    .foregroundStyle(Theme.moveLabel)
                    .contentTransition(.numericText())

                ProgressPips(total: session.moves.count, filled: session.completedPipCount)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            VStack(spacing: 7) {
                Text(session.timeLabel)
                    .font(.workear(size: 84, relativeTo: .largeTitle))
                    .foregroundStyle(Theme.ink)
                    .minimumScaleFactor(0.4)
                    .lineLimit(1)
                    .monospacedDigit()

                Text(session.currentMove.name)
                    .id("name-\(session.currentMove.id)")
                    .font(.workear(size: 20, relativeTo: .title3))
                    .foregroundStyle(Color.black.opacity(0.4))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            }
            .padding(.top, 49)

            Spacer(minLength: 23)

            ChickenMediaView(media: session.currentMove.media, isPlaying: !session.isPaused)
                .id(session.currentMove.id)
                .frame(maxWidth: .infinity)
                .frame(height: 336)
                .scaleEffect(session.currentMove.media.displayScale)
                .offset(x: session.currentMove.media.nudgeX)
                .padding(.horizontal, 16)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

            Spacer(minLength: 8)

            WorkoutControls(
                isPaused: session.isPaused,
                isLastMove: session.currentIndex == session.moves.count - 1,
                onTogglePause: { session.togglePause() },
                onNext: {
                    withAnimation(.spring(duration: 0.5, bounce: 0.08)) {
                        session.skipToNext()
                    }
                }
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
    }
}
