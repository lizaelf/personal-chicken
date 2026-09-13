import SwiftUI

struct PaperBackground: View {
    var body: some View {
        Theme.cream
            .overlay {
                Image("PaperTexture")
                    .resizable()
                    .scaledToFill()
                    .blendMode(.multiply)
                    .opacity(0.9)
            }
            .ignoresSafeArea()
    }
}
