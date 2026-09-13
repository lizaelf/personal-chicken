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

            media
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, 23)
                .padding(.bottom, 8)

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

    @ViewBuilder
    private var media: some View {
        let move = session.currentMove
        GeometryReader { geo in
            let inset: CGFloat = move.media.isVideo ? 0 : 16
            ChickenMediaView(media: move.media, isPlaying: !session.isPaused)
                .id(move.id)
                .frame(width: geo.size.width - inset * 2, height: geo.size.height)
                .scaleEffect(move.media.isVideo ? move.media.displayScale : 1)
                .offset(x: move.media.isVideo ? move.media.nudgeX : 0)
                .frame(width: geo.size.width, height: geo.size.height)
        }
        .clipped()
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
    }
}
