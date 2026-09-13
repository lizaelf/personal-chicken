import SwiftUI

struct WorkoutView: View {
    let session: WorkoutSession

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let scale = width / 402
            let gutter = 16 * scale

            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 10 * scale) {
                    Text("Move \(session.currentIndex + 1) of \(session.moves.count)")
                        .font(.workear(size: 12 * scale, relativeTo: .caption))
                        .foregroundStyle(Theme.moveLabel)
                        .contentTransition(.numericText())

                    ProgressPips(total: session.moves.count, filled: session.completedPipCount)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, gutter)
                .padding(.top, 8 * scale)

                VStack(spacing: 7 * scale) {
                    Text(session.timeLabel)
                        .font(.workear(size: 84 * scale, relativeTo: .largeTitle))
                        .foregroundStyle(Theme.ink)
                        .minimumScaleFactor(0.4)
                        .lineLimit(1)
                        .monospacedDigit()
                        .frame(maxWidth: .infinity)

                    Text(session.currentMove.name)
                        .id("name-\(session.currentMove.id)")
                        .font(.workear(size: 20 * scale, relativeTo: .title3))
                        .foregroundStyle(Color.black.opacity(0.4))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 24 * scale)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                }
                .padding(.top, 36 * scale)

                ChickenMediaView(media: session.currentMove.media, isPlaying: !session.isPaused)
                    .id(session.currentMove.id)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .offset(x: session.currentMove.media.nudgeX)
                    .clipped()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))

                WorkoutControls(
                    isPaused: session.isPaused,
                    isLastMove: session.currentIndex == session.moves.count - 1,
                    layoutScale: scale,
                    onTogglePause: { session.togglePause() },
                    onNext: {
                        withAnimation(.spring(duration: 0.5, bounce: 0.08)) {
                            session.skipToNext()
                        }
                    }
                )
                .zIndex(1)
                .padding(.horizontal, gutter)
                .padding(.bottom, 32 * scale)
            }
            .frame(width: width, height: geo.size.height)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
