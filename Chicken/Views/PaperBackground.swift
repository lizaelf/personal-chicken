import SwiftUI

struct PaperBackground: View {
    var body: some View {
        ZStack {
            Theme.canvas
            Image("PaperTexture")
                .resizable()
                .scaledToFill()
                .blendMode(.multiply)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

/// Full-screen paper fill, matching Figma screen backgrounds.
struct PaperOverlay: View {
    var body: some View {
        PaperBackground()
    }
}
