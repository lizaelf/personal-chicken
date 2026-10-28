import SwiftUI

struct WorkoutView: View {
    let session: WorkoutSession
    @State private var stepTick = 0

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let scale = width / 402
            let gutter = Theme.Space.gutter * scale

            VStack(spacing: 0) {
                HStack(alignment: .pipRow, spacing: 16 * scale) {
                    ChickenCloseButton(size: 40 * scale, iconSize: 13 * scale) {
                        withAnimation(.spring(duration: 0.5, bounce: 0.08)) {
                            session.restart()
                        }
                    }
                    .alignmentGuide(.pipRow) { $0[VerticalAlignment.center] }

                    if session.moves.count > 1 {
                        VStack(spacing: 8 * scale) {
                            Text("\(session.currentIndex + 1)/\(session.moves.count)")
                                .font(.workear(size: Theme.Size.callout * scale, relativeTo: .caption))
                                .foregroundStyle(Theme.ink)
                                .frame(maxWidth: .infinity)
                                .contentTransition(.numericText())
                                .monospacedDigit()
                                .accessibilityLabel("Move \(session.currentIndex + 1) of \(session.moves.count)")

                            HStack(spacing: 8 * scale) {
                                ForEach(0..<session.moves.count, id: \.self) { index in
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
                            }
                            .alignmentGuide(.pipRow) { $0[VerticalAlignment.center] }
                        }
                    } else {
                        Spacer(minLength: 0)
                    }

                    Button {
                        session.toggleSounds()
                    } label: {
                        Image(systemName: session.soundsEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                            .font(.system(size: 15 * scale, weight: .semibold))
                            .foregroundStyle(Theme.ink)
                            .frame(width: 40 * scale, height: 40 * scale)
                    }
                    .buttonStyle(.plain)
                    .alignmentGuide(.pipRow) { $0[VerticalAlignment.center] }
                    .accessibilityLabel(session.soundsEnabled ? "Mute sounds" : "Unmute sounds")
                    .accessibilityAddTraits(.isToggle)
                    .accessibilityValue(session.soundsEnabled ? "On" : "Off")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, gutter)
                .padding(.top, 8 * scale)

                VStack(spacing: 7 * scale) {
                    Text("\(session.currentSet)")
                        .font(.workear(size: Theme.Size.display * scale, relativeTo: .largeTitle))
                        .foregroundStyle(Theme.ink)
                        .minimumScaleFactor(0.4)
                        .lineLimit(1)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.horizontal, gutter)
                        .accessibilityLabel("Sets remaining \(session.currentSet)")

                    Text(session.currentMove.name)
                        .id("name-\(session.currentMove.id)")
                        .font(.workear(size: Theme.Size.title3 * scale, relativeTo: .title3))
                        .foregroundStyle(Theme.fgMuted)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, Theme.Space.xl * scale)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                }
                .padding(.top, 49 * scale)

                Spacer(minLength: 23 * scale)

                ChickenMediaView(media: session.currentMove.media, isPlaying: session.isAnnouncing || !session.isPaused)
                    .id(session.currentMove.id)
                    .frame(width: width * 0.8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))

                Spacer(minLength: 8 * scale)

                WorkoutControls(
                    isPaused: session.isPaused,
                    canGoBack: session.currentIndex > 0,
                    layoutScale: scale,
                    onPrevious: {
                        stepTick += 1
                        withAnimation(.spring(duration: 0.5, bounce: 0.08)) {
                            session.skipToPrevious()
                        }
                    },
                    onTogglePause: { session.togglePause() },
                    onNext: {
                        stepTick += 1
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
            .overlay(alignment: .bottomTrailing) {
                if session.isLastSet {
                    Image("OneMore")
                        .resizable()
                        .scaledToFit()
                        .frame(width: width)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                        .ignoresSafeArea(edges: [.bottom, .trailing])
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: session.isLastSet)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sensoryFeedback(.impact(weight: .light), trigger: session.isPaused)
        .sensoryFeedback(.impact(weight: .medium), trigger: stepTick)
    }
}

private extension VerticalAlignment {
    enum PipRow: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            context[VerticalAlignment.center]
        }
    }

    static let pipRow = VerticalAlignment(PipRow.self)
}
