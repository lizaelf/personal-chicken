import SwiftUI

enum Theme {
    // MARK: Color — keep in sync with `web/index.html` :root

    static let cream = Color("Cream")
    /// #EF6856
    static let coral = Color("Coral")
    static let ink = Color("Ink")
    static let moveLabel = Color("MoveLabel")
    static let charmInk = Color("CharmInk")
    static let buttonCream = Color("ButtonCream")

    /// #FDF6EC
    static let canvas = Color(red: 253 / 255, green: 246 / 255, blue: 236 / 255)
    /// #2C1F1C
    static let fgPrimary = Color(red: 44 / 255, green: 31 / 255, blue: 28 / 255)
    /// #978A82
    static let fgSecondary = Color(red: 151 / 255, green: 138 / 255, blue: 130 / 255)
    /// #BCB4AF
    static let fgRest = Color(red: 188 / 255, green: 180 / 255, blue: 175 / 255)
    /// #E85C5C
    static let fgAccent = Color(red: 232 / 255, green: 92 / 255, blue: 92 / 255)
    /// #3EAE6F
    static let fgPositive = Color(red: 62 / 255, green: 174 / 255, blue: 111 / 255)
    /// #3A2A26
    static let fgInverse = Color(red: 58 / 255, green: 42 / 255, blue: 38 / 255)
    static let fgMuted = Color.black.opacity(0.4)
    /// #F0E4D8
    static let bgMuted = Color(red: 240 / 255, green: 228 / 255, blue: 216 / 255)
    static let bgSoft = fgSecondary.opacity(0.2)
    /// #FFF8F1
    static let surface = Color(red: 255 / 255, green: 248 / 255, blue: 241 / 255)
    /// #FDF8F1
    static let weightSurface = Color(red: 253 / 255, green: 248 / 255, blue: 241 / 255)
    /// #FFFCFA
    static let tabOn = Color(red: 255 / 255, green: 252 / 255, blue: 250 / 255)
    /// #F6EDE0 at 80%
    static let tabOff = Color(red: 246 / 255, green: 237 / 255, blue: 224 / 255).opacity(0.8)
    /// #F2E6DA
    static let chipFill = Color(red: 242 / 255, green: 230 / 255, blue: 218 / 255)
    /// #E8A09A
    static let borderAccent = Color(red: 232 / 255, green: 160 / 255, blue: 154 / 255)
    static let white = Color.white
    /// Outer stop of the workout-card radial — Figma 100:1252
    static let dunePeach = canvas
    /// #F4EBD5
    static let duneSand = Color(red: 244 / 255, green: 235 / 255, blue: 213 / 255)
    /// #CE7745
    static let duneGlow = Color(red: 206 / 255, green: 119 / 255, blue: 69 / 255)
    /// #F49E6D
    static let duneGlowSoft = Color(red: 244 / 255, green: 158 / 255, blue: 109 / 255)
    /// #FBE2E1
    static let calToday = Color(red: 251 / 255, green: 226 / 255, blue: 225 / 255)

    static let strokeMuted = fgSecondary.opacity(0.2)
    static let strokeFree = fgSecondary.opacity(0.24)
    static let strokeFreeChip = fgSecondary.opacity(0.28)
    static let strokeHairline = fgSecondary.opacity(0.12)
    static let todayRing = fgPrimary.opacity(0.35)
    static let gridWeak = fgPrimary.opacity(0.06)
    static let gridStrong = fgPrimary.opacity(0.12)
    static let chartFill = fgAccent.opacity(0.16)
    static let noteTime = fgSecondary.opacity(0.8)

    enum Space {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let gutter: CGFloat = 16
        static let cardGap: CGFloat = 8
        static let tabGap: CGFloat = 9
        static let tabTop: CGFloat = 24
        static let tabHeight: CGFloat = 43
        static let homeBar: CGFloat = 34
    }

    enum Size {
        static let countdown: CGFloat = 128
        static let display: CGFloat = 84
        static let pickerMark: CGFloat = 40
        static let picker: CGFloat = 34
        static let charm: CGFloat = 32
        static let stat: CGFloat = 30
        static let streak: CGFloat = 26
        static let title: CGFloat = 24
        static let title2: CGFloat = 22
        static let title3: CGFloat = 20
        static let headline: CGFloat = 17
        static let row: CGFloat = 16
        static let body: CGFloat = 15
        static let callout: CGFloat = 14
        static let chip: CGFloat = 13
        static let caption: CGFloat = 12
        static let iconSm: CGFloat = 14
        static let iconMd: CGFloat = 18
    }

    enum Text {
        static let countdown = Font.workear(size: Size.countdown, relativeTo: .largeTitle)
        static let display = Font.workear(size: Size.display, relativeTo: .largeTitle)
        static let pickerMark = Font.workear(size: Size.pickerMark, relativeTo: .largeTitle)
        static let picker = Font.workear(size: Size.picker, relativeTo: .largeTitle)
        static let charm = Font.workear(size: Size.charm, relativeTo: .title)
        static let stat = Font.workear(size: Size.stat, relativeTo: .title)
        static let streak = Font.workear(size: Size.streak, relativeTo: .title)
        static let title = Font.workear(size: Size.title, relativeTo: .title)
        static let title2 = Font.workear(size: Size.title2, relativeTo: .title2)
        static let title3 = Font.workear(size: Size.title3, relativeTo: .title3)
        static let headline = Font.workear(size: Size.headline, relativeTo: .headline)
        static let row = Font.workear(size: Size.row, relativeTo: .headline)
        static let body = Font.workear(size: Size.body, relativeTo: .body)
        static let callout = Font.workear(size: Size.callout, relativeTo: .body)
        static let chip = Font.workear(size: Size.chip, relativeTo: .caption)
        static let caption = Font.workear(size: Size.caption, relativeTo: .caption)
    }

    /// Figma radii: 16 chips/icon, 18 tabs, 20 CTAs, 30 cards.
    enum Radius {
        static let sm: CGFloat = 16
        static let md: CGFloat = 18
        static let lg: CGFloat = 20
        static let xl: CGFloat = 30
    }

    /// Figma `shad`: y 0.96, blur 1.92 / 2.87, spread −0.96 / 0, 10% black.
    enum Shadow {
        static let color = Color.black.opacity(0.07)
        static let y: CGFloat = 0.96
        static let tight: CGFloat = 1.2
        static let loose: CGFloat = 3.6
    }
}

extension View {
    func chickenShadow(_ enabled: Bool = true) -> some View {
        let color = enabled ? Theme.Shadow.color : .clear
        return self
            .shadow(color: color, radius: Theme.Shadow.tight, x: 0, y: Theme.Shadow.y)
            .shadow(color: color, radius: Theme.Shadow.loose, x: 0, y: Theme.Shadow.y)
    }
}

extension Font {
    static func workear(size: CGFloat, relativeTo textStyle: Font.TextStyle) -> Font {
        .custom("Workear Font", size: size, relativeTo: textStyle)
    }
}
