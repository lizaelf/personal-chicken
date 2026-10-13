import SwiftUI

struct PaperBackground: View {
    var body: some View {
        Theme.cream
            .ignoresSafeArea()
    }
}

/// Full-screen paper multiply, matching the web prototype so cream-backed
/// H.264 clips still sit on the same texture as the rest of the screen.
struct PaperOverlay: View {
    var body: some View {
        Image("PaperTexture")
            .resizable()
            .scaledToFill()
            .blendMode(.multiply)
            .opacity(0.9)
            .ignoresSafeArea()
            .allowsHitTesting(false)
    }
}
