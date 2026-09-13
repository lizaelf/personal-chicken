import SwiftUI

struct RootView: View {
    @State private var session = WorkoutSession()

    var body: some View {
        ZStack {
            PaperBackground()

            ZStack {
                switch session.phase {
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
            }
            .animation(.spring(duration: 0.5, bounce: 0.08), value: session.currentIndex)
            .animation(.spring(duration: 0.5, bounce: 0.08), value: session.phase)
        }
    }
}

#Preview {
    RootView()
}
