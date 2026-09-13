import SwiftUI

struct PaperBackground: View {
    var body: some View {
        Theme.cream
            .ignoresSafeArea()
    }
}

/// Full-screen paper multiply, matching the web prototype so cream-backed
/// clips still sit on the same texture as the rest of the screen.
struct PaperOverlay: View {
    var body: some View {
        Color.clear
            .ignoresSafeArea()
            .overlay {
                GeometryReader { geo in
                    Image("PaperTexture")
                        .resizable()
                        .frame(width: geo.size.width, height: geo.size.height)
                }
            }
            .blendMode(.multiply)
            .opacity(0.9)
            .allowsHitTesting(false)
    }
}
