import SwiftUI

struct CompletionView: View {
    let onRestart: () -> Void

    var body: some View {
        ZStack(alignment: .top) {
            ChickenMediaView(media: .video("SequenceCharm"))
                .aspectRatio(ChickenMedia.video("SequenceCharm").aspectRatio, contentMode: .fit)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
                .padding(.top, 132)

            VStack {
                Spacer()
                Text("I’ll charm you\ninto coming back!")
                    .font(.workear(size: 32, relativeTo: .title))
                    .lineSpacing(6)
                    .foregroundStyle(Theme.charmInk)
                    .multilineTextAlignment(.center)
                    .frame(width: 373)
                    .padding(.bottom, 116)
            }

            HStack {
                Spacer()
                Button(action: onRestart) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                        .frame(width: 56, height: 56)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close")
            }
            .padding(.top, 52)
            .padding(.horizontal, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture(perform: onRestart)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel("I’ll charm you into coming back! Tap to start again.")
    }
}
