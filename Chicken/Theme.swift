import SwiftUI

enum Theme {
    static let cream = Color("Cream")
    static let coral = Color("Coral")
    static let ink = Color("Ink")
    static let moveLabel = Color("MoveLabel")
    static let charmInk = Color("CharmInk")
    static let buttonCream = Color("ButtonCream")

    static let canvas = Color(red: 242 / 255, green: 230 / 255, blue: 218 / 255)
    static let fgPrimary = Color(red: 44 / 255, green: 31 / 255, blue: 28 / 255)
    static let fgSecondary = Color(red: 151 / 255, green: 138 / 255, blue: 130 / 255)
    static let fgAccent = Color(red: 232 / 255, green: 92 / 255, blue: 92 / 255)
    static let fgPositive = Color(red: 62 / 255, green: 174 / 255, blue: 111 / 255)
    static let fgInverse = Color(red: 58 / 255, green: 42 / 255, blue: 38 / 255)
    static let bgMuted = Color(red: 240 / 255, green: 228 / 255, blue: 216 / 255)
    static let surface = Color(red: 255 / 255, green: 248 / 255, blue: 241 / 255)
    static let borderAccent = Color(red: 232 / 255, green: 160 / 255, blue: 154 / 255)
}

extension Font {
    static func workear(size: CGFloat, relativeTo textStyle: Font.TextStyle) -> Font {
        .custom("Workear Font", size: size, relativeTo: textStyle)
    }
}
