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
        Color.clear
            .ignoresSafeArea()
            .overlay {
                Image("PaperTexture")
                    .resizable()
                    .scaledToFill()
            }
            .clipped()
            .blendMode(.multiply)
            .opacity(0.9)
            .allowsHitTesting(false)
    }
}
