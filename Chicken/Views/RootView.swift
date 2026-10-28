import SwiftUI
import UIKit

struct RootView: View {
    @State private var session = WorkoutSession()
    @State private var log = FitnessLog()
    @State private var showSplash = true

    var body: some View {
        phaseStack
            .animation(.spring(duration: 0.5, bounce: 0.08), value: session.currentIndex)
            .animation(session.phase == .countdown ? nil : .spring(duration: 0.5, bounce: 0.08), value: session.phase)
            .animation(.easeInOut(duration: 0.45), value: showSplash)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background { rootBackground }
            .overlay {
                HomeBar()
                    .ignoresSafeArea()
            }
            .task { await dismissSplash() }
            .onChange(of: session.phase) { _, phase in
                if phase == .complete { log.recordWorkout() }
                keepScreenAwake(phase)
            }
            .onAppear { keepScreenAwake(session.phase) }
    }

    private var phaseStack: some View {
        ZStack {
            switch session.phase {
            case .home:
                HomeView(session: session, log: log)
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .identity
                    ))
            case .countdown:
                CountdownView(session: session)
                    .background { PaperBackground() }
                    .transition(.asymmetric(insertion: .identity, removal: .opacity))
                    .zIndex(2)
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
        PaperBackground()
    }

    private func keepScreenAwake(_ phase: WorkoutSession.Phase) {
        UIApplication.shared.isIdleTimerDisabled = phase == .countdown || phase == .workout
    }

    private func dismissSplash() async {
        try? await Task.sleep(for: .milliseconds(2000))
        let leave = UIImpactFeedbackGenerator(style: .soft)
        leave.impactOccurred(intensity: 0.55)
        withAnimation(.easeInOut(duration: 0.45)) {
            showSplash = false
        }
    }
}

#Preview {
    RootView()
}

private struct HomeBar: View {
    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            Capsule()
                .fill(Color.black)
                .frame(width: 140, height: 5)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 8)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct SplashView: View {
    @State private var popped = false

    var body: some View {
        VStack(spacing: 20) {
            ChickenMediaView(media: .video("SequenceAbs"), isPlaying: true)
                .frame(width: 288, height: 336)
                .offset(x: -34)
                .scaleEffect(popped ? 1 : 0.86)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background { PaperBackground() }
        .onAppear {
            let pop = UIImpactFeedbackGenerator(style: .medium)
            pop.prepare()
            withAnimation(.spring(duration: 0.7, bounce: 0.18)) {
                popped = true
            }
            Task {
                try? await Task.sleep(for: .milliseconds(160))
                pop.impactOccurred(intensity: 0.9)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Fit Coco")
    }
}

private struct CountdownView: View {
    let session: WorkoutSession
    @State private var count = 3
    @State private var runID = UUID()

    var body: some View {
        Text("\(count)")
            .font(Theme.Text.countdown)
            .foregroundStyle(Theme.ink)
            .id(count)
            .transition(.asymmetric(
                insertion: .scale(scale: 0.55).combined(with: .opacity),
                removal: .scale(scale: 1.18).combined(with: .opacity)
            ))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.spring(duration: 0.38, bounce: 0.18), value: count)
            .task(id: runID) {
                for n in [3, 2, 1] {
                    withAnimation(.spring(duration: 0.38, bounce: 0.18)) {
                        count = n
                    }
                    if session.soundsEnabled {
                        WorkoutCue.speakSet(n)
                    }
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
