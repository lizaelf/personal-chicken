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

            ChickenMediaView(media: session.currentMove.media, isPlaying: !session.isPaused)
                .id(session.currentMove.id)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, 12)
                .padding(.bottom, 8)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

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
            .zIndex(1)
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
    }
}
