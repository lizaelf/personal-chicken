import SwiftUI

@main
struct ChickenApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.light)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
        }
    }
}
