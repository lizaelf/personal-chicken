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
                    HStack(alignment: .center, spacing: 8 * scale) {
                        Button {
                            withAnimation(.spring(duration: 0.5, bounce: 0.08)) {
                                session.restart()
                            }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 13 * scale, weight: .semibold))
                                .foregroundStyle(Theme.ink)
                                .frame(width: 32 * scale, height: 32 * scale)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Close")

                        ForEach(0..<session.moves.count, id: \.self) { index in
                            if index == 1 {
                                Text("\(session.currentIndex + 1)/\(session.moves.count)")
                                    .font(.workear(size: 14 * scale, relativeTo: .caption))
                                    .foregroundStyle(Theme.moveLabel)
                                    .contentTransition(.numericText())
                                    .monospacedDigit()
                            }
                            Capsule()
                                .fill(index < session.completedPipCount ? Theme.coral : Color.clear)
                                .overlay {
                                    Capsule().stroke(Theme.coral, lineWidth: 1)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 8 * scale)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    withAnimation(.spring(duration: 0.5, bounce: 0.08)) {
                                        session.goTo(index)
                                    }
                                }
                        }

                        Button {
                            session.toggleSounds()
                        } label: {
                            Image(systemName: session.soundsEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                                .font(.system(size: 15 * scale, weight: .semibold))
                                .foregroundStyle(Theme.ink)
                                .frame(width: 32 * scale, height: 32 * scale)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(session.soundsEnabled ? "Mute sounds" : "Unmute sounds")
                        .accessibilityAddTraits(.isToggle)
                        .accessibilityValue(session.soundsEnabled ? "On" : "Off")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, gutter)
                .padding(.top, 8 * scale)

                VStack(spacing: 7 * scale) {
                    Text(session.remainingClock)
                        .font(.workear(size: 84 * scale, relativeTo: .largeTitle))
                        .foregroundStyle(Theme.ink)
                        .minimumScaleFactor(0.4)
                        .lineLimit(1)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.horizontal, gutter)
                        .accessibilityLabel("Time remaining \(session.remainingClock)")

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
                .padding(.top, 49 * scale)

                Spacer(minLength: 23 * scale)

                ChickenMediaView(media: session.currentMove.media, isPlaying: session.isAnnouncing || !session.isPaused)
                    .id(session.currentMove.id)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, gutter)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))

                Spacer(minLength: 8 * scale)

                WorkoutControls(
                    isPaused: session.isPaused,
                    canGoBack: session.currentIndex > 0,
                    isLastMove: session.currentIndex == session.moves.count - 1,
                    layoutScale: scale,
                    onPrevious: {
                        withAnimation(.spring(duration: 0.5, bounce: 0.08)) {
                            session.skipToPrevious()
                        }
                    },
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
        .sensoryFeedback(.impact(weight: .light), trigger: session.isPaused)
        .sensoryFeedback(.impact(weight: .medium), trigger: session.currentIndex)
        .sensoryFeedback(.selection, trigger: session.soundsEnabled)
    }
}
