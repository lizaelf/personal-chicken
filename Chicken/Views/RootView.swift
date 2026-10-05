import SwiftUI

struct RootView: View {
    @State private var session = WorkoutSession()
    @State private var showSplash = true

    var body: some View {
        phaseStack
            .animation(.spring(duration: 0.5, bounce: 0.08), value: session.currentIndex)
            .animation(.spring(duration: 0.5, bounce: 0.08), value: session.phase)
            .animation(.easeInOut(duration: 0.45), value: showSplash)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background { rootBackground }
            .task { await dismissSplash() }
            .sensoryFeedback(.impact(weight: .medium), trigger: session.phase)
    }

    private var phaseStack: some View {
        ZStack {
            switch session.phase {
            case .home:
                HomeView(session: session)
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            case .countdown:
                CountdownView(session: session)
                    .transition(.opacity)
            case .workout:
                WorkoutView(session: session)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            case .complete:
                CompletionView(onRestart: {
                    withAnimation(.spring(duration: 0.5, bounce: 0.08)) {
                        session.restart()
                    }
                })
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            }

            if showSplash {
                SplashView()
                    .transition(.opacity)
                    .zIndex(10)
            }
        }
    }

    @ViewBuilder
    private var rootBackground: some View {
        if session.phase == .home && !showSplash {
            Theme.canvas.ignoresSafeArea()
        } else if showSplash {
            Theme.cream.ignoresSafeArea()
        } else {
            ZStack {
                PaperBackground()
                PaperOverlay()
            }
        }
    }

    private func dismissSplash() async {
        try? await Task.sleep(for: .milliseconds(2000))
        withAnimation(.easeInOut(duration: 0.45)) {
            showSplash = false
        }
    }
}

#Preview {
    RootView()
}

private struct SplashView: View {
    @State private var popped = false

    var body: some View {
        VStack(spacing: 20) {
            ChickenMediaView(media: .video("SequenceHome"), isPlaying: true)
                .frame(width: 240, height: 280)
                .scaleEffect(popped ? 1 : 0.86)

            VStack(spacing: 8) {
                Text("Chicken")
                    .font(.workear(size: 40, relativeTo: .largeTitle))
                    .foregroundStyle(Theme.fgPrimary)
                Text("Let’s worko-ko!")
                    .font(.workear(size: 16, relativeTo: .body))
                    .foregroundStyle(Theme.fgSecondary)
            }
            .opacity(popped ? 1 : 0)
            .offset(y: popped ? 0 : 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.cream.ignoresSafeArea())
        .onAppear {
            withAnimation(.spring(duration: 0.7, bounce: 0.18)) {
                popped = true
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Chicken")
    }
}

private struct CountdownView: View {
    let session: WorkoutSession
    @State private var count = 3
    @State private var tick = 0
    @State private var runID = UUID()

    var body: some View {
        Text("\(count)")
            .font(.workear(size: 128, relativeTo: .largeTitle))
            .foregroundStyle(Theme.ink)
            .id(count)
            .transition(.asymmetric(
                insertion: .scale(scale: 0.55).combined(with: .opacity),
                removal: .scale(scale: 1.18).combined(with: .opacity)
            ))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.spring(duration: 0.38, bounce: 0.18), value: count)
            .sensoryFeedback(.impact(flexibility: .rigid, intensity: 0.9), trigger: tick)
            .task(id: runID) {
                for n in [3, 2, 1] {
                    withAnimation(.spring(duration: 0.38, bounce: 0.18)) {
                        count = n
                    }
                    if session.soundsEnabled {
                        WorkoutCue.speakSet(n)
                    }
                    tick += 1
                    try? await Task.sleep(for: .seconds(1))
                    guard !Task.isCancelled else { return }
                }
                withAnimation(.spring(duration: 0.5, bounce: 0.08)) {
                    session.startWorkout()
                }
            }
            .accessibilityLabel("Countdown \(count)")
    }
}
