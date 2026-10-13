import SwiftUI

struct CompletionView: View {
    let onRestart: () -> Void

    var body: some View {
        GeometryReader { geo in
            let scale = geo.size.width / 402

            ZStack(alignment: .top) {
                ChickenMediaView(media: .video("SequenceCharm"))
                    .frame(width: 348 * scale, height: 432 * scale)
                    .scaleEffect(ChickenMedia.video("SequenceCharm").displayScale)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 132 * scale)

                VStack {
                    Spacer()
                    Text("I’ll charm you\ninto coming back!")
                        .font(.workear(size: 32 * scale, relativeTo: .title))
                        .lineSpacing(6 * scale)
                        .foregroundStyle(Theme.charmInk)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 373 * scale)
                        .padding(.horizontal, 16 * scale)
                        .padding(.bottom, 116 * scale)
                }

                HStack {
                    Spacer()
                    Button(action: onRestart) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16 * scale, weight: .semibold))
                            .foregroundStyle(Theme.ink)
                            .frame(width: 56 * scale, height: 56 * scale)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Close")
                }
                .padding(.top, 52 * scale)
                .padding(.horizontal, 16 * scale)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture(perform: onRestart)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel("I’ll charm you into coming back! Tap to start again.")
    }
}
