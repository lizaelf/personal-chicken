import SwiftUI
import UIKit

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
        Image("PaperTexture")
            .resizable()
            .frame(width: Self.screenSize.width, height: Self.screenSize.height)
            .blendMode(.multiply)
            .opacity(0.9)
            .ignoresSafeArea()
            .allowsHitTesting(false)
    }

    private static var screenSize: CGSize {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first
        if let window = scene?.windows.first(where: \.isKeyWindow) ?? scene?.windows.first {
            return window.bounds.size
        }
        return scene?.screen.bounds.size ?? CGSize(width: 402, height: 874)
    }
}
