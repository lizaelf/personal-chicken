import SwiftUI

enum Theme {
    static let cream = Color("Cream")
    static let coral = Color("Coral")
    static let ink = Color("Ink")
    static let moveLabel = Color("MoveLabel")
    static let charmInk = Color("CharmInk")
    static let buttonCream = Color("ButtonCream")
}

extension Font {
    static func workear(size: CGFloat, relativeTo textStyle: Font.TextStyle) -> Font {
        .custom("Workear Font", size: size, relativeTo: textStyle)
    }
}
