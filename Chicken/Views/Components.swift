import SwiftUI
import UIKit

struct ChickenPrimaryButton: View {
    let title: String
    var icon: String? = nil
    var height: CGFloat = 56
    var font: Font = Theme.Text.headline
    var titleColor: Color = Theme.surface
    var shadowed = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(title)
                    .font(font)
                    .foregroundStyle(titleColor)
                if let icon {
                    Image(icon)
                        .frame(width: 20, height: 20)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(Theme.coral, in: RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous))
        }
        .buttonStyle(.plain)
        .chickenShadow(shadowed)
    }
}

struct ChickenBackButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.system(size: Theme.Size.iconSm, weight: .semibold))
                .foregroundStyle(Theme.fgPrimary)
                .frame(width: 32, height: 32)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Back")
    }
}

struct ChickenCloseButton: View {
    var size: CGFloat = 40
    var iconSize: CGFloat = 13
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: iconSize, weight: .semibold))
                .foregroundStyle(Theme.ink)
                .frame(width: size, height: size)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Close")
    }
}

struct ChickenAvatarButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image("AvatarChicken")
                .resizable()
                .scaledToFill()
                .frame(width: 40, height: 40)
                .background(Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous))
        }
        .buttonStyle(.plain)
        .chickenShadow()
        .accessibilityLabel("Settings")
    }
}

struct ChickenPageHeader<Leading: View, Trailing: View>: View {
    let leading: Leading
    let trailing: Trailing

    init(
        @ViewBuilder leading: () -> Leading,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.leading = leading()
        self.trailing = trailing()
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            leading
            Spacer(minLength: 0)
            trailing
        }
        .padding(.horizontal, Theme.Space.gutter)
        .frame(maxWidth: .infinity)
    }
}

struct ChickenScreenHeader<Trailing: View>: View {
    let title: String
    let onBack: () -> Void
    let trailing: Trailing

    init(
        title: String,
        onBack: @escaping () -> Void,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.title = title
        self.onBack = onBack
        self.trailing = trailing()
    }

    var body: some View {
        ChickenPageHeader {
            ChickenBackButton(action: onBack)
            Text(title)
                .font(Theme.Text.title2)
                .foregroundStyle(Theme.fgPrimary)
        } trailing: {
            trailing
        }
    }
}

extension ChickenScreenHeader where Trailing == EmptyView {
    init(title: String, onBack: @escaping () -> Void) {
        self.init(title: title, onBack: onBack) { EmptyView() }
    }
}

struct WeekDayChip: View {
    let label: String
    let copy: String
    var selected = false
    var isToday = false
    var isFree = false
    var isFuture = false

    var body: some View {
        let fillInner = isToday
        HStack(spacing: 9) {
            Text(label)
                .font(Theme.Text.chip)
                .foregroundStyle(fillInner ? Theme.white : Theme.fgSecondary)
                .frame(width: 36, height: 37)
                .background {
                    Capsule().fill(fillInner ? Theme.fgAccent : (isFree ? Theme.bgSoft : Color.clear))
                }
                .overlay {
                    if !fillInner {
                        Capsule().stroke(isFuture ? Theme.fgSecondary.opacity(0.45) : Theme.strokeFree, lineWidth: 1)
                    }
                }

            Text(copy)
                .font(Theme.Text.body)
                .foregroundStyle(selected || !isFree ? Theme.fgPrimary : Theme.fgSecondary)
                .lineLimit(1)
                .fixedSize()
        }
        .padding(.leading, 4)
        .padding(.trailing, 20)
        .padding(.vertical, 4)
        .frame(height: 47)
        .fixedSize(horizontal: true, vertical: true)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous)
                .stroke(isToday ? Theme.borderAccent : Theme.strokeFreeChip, lineWidth: 1)
        }
    }
}

struct WeekDayDot: View {
    let label: String
    let date: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
            Text(date)
        }
        .font(Theme.Text.body)
        .foregroundStyle(color)
        .frame(width: 36, height: 56)
    }
}

struct ChickenChip: View {
    let title: String
    var icon: String? = nil

    var body: some View {
        HStack(spacing: 6) {
            if let icon {
                Image(icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: icon == "IconTime" ? 24 : 20, height: icon == "IconTime" ? 24 : 20)
            }
            Text(title)
                .font(Theme.Text.body)
                .foregroundStyle(Theme.fgPrimary)
        }
        .padding(.leading, 8)
        .padding(.trailing, 12)
        .frame(height: 36)
        .overlay {
            RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                .stroke(Theme.strokeMuted, lineWidth: 1)
        }
    }
}

struct ChickenChoiceChip: View {
    let title: String
    var selected = false
    var selectedFill: Color = Theme.chipFill
    var selectedForeground: Color = Theme.fgInverse
    var expands = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.Text.callout)
                .foregroundStyle(selected ? selectedForeground : Theme.fgSecondary)
                .padding(.horizontal, expands ? 0 : Theme.Space.gutter)
                .frame(maxWidth: expands ? .infinity : nil)
                .frame(height: 36)
                .background(
                    selected ? selectedFill : Theme.bgSoft,
                    in: Capsule()
                )
        }
        .buttonStyle(.plain)
    }
}

struct ChickenDayChip: View {
    let title: String
    var selected = false
    let action: () -> Void

    var body: some View {
        ChickenChoiceChip(
            title: title,
            selected: selected,
            selectedFill: Theme.coral,
            selectedForeground: Theme.surface,
            expands: true,
            action: action
        )
    }
}

/// Lays chips out on the 7-column Workout days grid so shorter rows keep the same chip width.
struct ChickenDayChipRow<Item: Hashable>: View {
    let items: [Item]
    let title: (Item) -> String
    let isSelected: (Item) -> Bool
    let action: (Item) -> Void

    var body: some View {
        HStack(spacing: 8) {
            ForEach(items, id: \.self) { item in
                ChickenDayChip(title: title(item), selected: isSelected(item)) {
                    action(item)
                }
            }
            ForEach(0..<max(0, 7 - items.count), id: \.self) { _ in
                Color.clear
                    .frame(maxWidth: .infinity)
                    .frame(height: 1)
                    .accessibilityHidden(true)
            }
        }
    }
}

struct ChickenPlusButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image("IconPlus")
                .frame(width: 19, height: 19)
                .frame(width: 51, height: 51)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                        .fill(Theme.white)
                )
                .chickenShadow()
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add weight")
    }
}

struct ChickenSurfaceCard<Content: View>: View {
    var radius: CGFloat = Theme.Radius.xl
    let content: Content

    init(radius: CGFloat = Theme.Radius.xl, @ViewBuilder content: () -> Content) {
        self.radius = radius
        self.content = content()
    }

    var body: some View {
        content
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
    }
}

struct SettingsGroup<Content: View>: View {
    let title: String?
    let content: Content

    init(title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title {
                Text(title)
                    .font(Theme.Text.callout)
                    .foregroundStyle(Theme.fgSecondary)
                    .padding(.horizontal, 8)
            }
            VStack(spacing: 0) {
                content
            }
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.xl, style: .continuous))
        }
    }
}

struct SettingsToggleRow: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            Text(title)
                .font(Theme.Text.row)
                .foregroundStyle(Theme.fgPrimary)
        }
        .tint(Theme.coral)
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }
}

struct SettingsValueRow: View {
    let title: String
    var value: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        let row = HStack {
            Text(title)
                .font(Theme.Text.row)
                .foregroundStyle(Theme.fgPrimary)
            Spacer()
            if let value, !value.isEmpty {
                Text(value)
                    .font(Theme.Text.callout)
                    .foregroundStyle(Theme.fgSecondary)
                    .contentTransition(.numericText())
            }
            if action != nil {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.fgSecondary)
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .contentShape(Rectangle())

        if let action {
            Button(action: action) { row }
                .buttonStyle(.plain)
        } else {
            row
        }
    }
}

struct DuneCardBackground: View {
    var referenceHeight: CGFloat = 525
    var duneY: CGFloat = 271
    var duneHeight: CGFloat = 257
    var centerPeach = true
    var showDune = true

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack {
                if !centerPeach || showDune {
                    Image("CardFill")
                        .resizable()
                        .interpolation(.high)
                        .frame(width: size.width, height: size.height)
                } else {
                    Theme.canvas
                }
                if showDune {
                    Image("CardDune")
                        .resizable()
                        .interpolation(.high)
                        .frame(
                            width: size.width * 612 / 395,
                            height: size.height * duneHeight / referenceHeight
                        )
                        .position(
                            x: size.width * (-108 + 612 / 2) / 395,
                            y: size.height * (duneY + duneHeight / 2) / referenceHeight
                        )
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
        }
    }
}

struct ChickenTabBar: View {
    @Binding var selected: HomeTab

    var body: some View {
        VStack(spacing: 0) {
            Color.clear
                .frame(height: Theme.Space.tabTop)
                .allowsHitTesting(false)

            HStack(spacing: Theme.Space.tabGap) {
                ForEach(HomeTab.allCases) { tab in
                    Button {
                        withAnimation(.easeOut(duration: 0.12)) {
                            selected = tab
                        }
                    } label: {
                        Text(tab.title)
                            .font(Theme.Text.body)
                            .foregroundStyle(tab == selected ? Theme.fgInverse : Theme.fgSecondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: Theme.Space.tabHeight)
                            .padding(.horizontal, Theme.Space.md)
                            .background(
                                tab == selected ? Theme.tabOn : Color.clear,
                                in: RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                            )
                            .chickenShadow(tab == selected)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Theme.Space.gutter)
            .padding(.bottom, Theme.Space.homeBar - 32)
            .animation(.easeOut(duration: 0.12), value: selected)
        }
        .ignoresSafeArea(edges: .bottom)
        .background(alignment: .top) {
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [Theme.canvas.opacity(0), Theme.canvas],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: Theme.Space.tabTop)
                Theme.canvas
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .accessibilityElement(children: .contain)
    }
}

enum HomeTab: String, CaseIterable, Identifiable {
    case home, workouts, statistics

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: return "Home"
        case .workouts: return "Workouts"
        case .statistics: return "Statistics"
        }
    }
}

struct WeightLogSheet: View {
    let unit: String
    let onLog: (Double) -> Void
    let onClose: () -> Void
    @State private var whole: Int
    @State private var tenth: Int
    @State private var choice: WeightWheelReadout
    @State private var dragY: CGFloat = 0

    init(initialKg: Double, unit: String, onLog: @escaping (Double) -> Void, onClose: @escaping () -> Void) {
        self.unit = unit
        self.onLog = onLog
        self.onClose = onClose
        let display = unit == "lb" ? initialKg * 2.2046226218 : initialKg
        let rounded = (display * 10).rounded() / 10
        let whole = min(200, max(30, Int(rounded.rounded(.down))))
        let tenth = Int((rounded * 10).rounded()) % 10
        _whole = State(initialValue: whole)
        _tenth = State(initialValue: tenth)
        _choice = State(initialValue: WeightWheelReadout(whole: whole, tenth: tenth))
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                Capsule()
                    .fill(Theme.fgSecondary.opacity(0.35))
                    .frame(width: 36, height: 5)
                    .padding(.top, 8)

                Text("Your current weight")
                    .font(Theme.Text.title2)
                    .foregroundStyle(Theme.fgPrimary)
                    .padding(.top, 15)
                    .padding(.bottom, 20)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { dragY = max(0, $0.translation.height) }
                    .onEnded { value in
                        if value.translation.height > 100 || value.predictedEndTranslation.height > 240 {
                            onClose()
                        } else {
                            withAnimation(.spring(duration: 0.3, bounce: 0)) { dragY = 0 }
                        }
                    }
            )

            HStack(spacing: 2) {
                WeightDrum(values: Array(30...200), selection: $whole, choice: choice, part: .whole)
                    .frame(width: 96, height: 220)

                Text(".")
                    .font(Theme.Text.pickerMark)
                    .foregroundStyle(Theme.fgPrimary)

                WeightDrum(values: Array(0...9), selection: $tenth, choice: choice, part: .tenth)
                    .frame(width: 56, height: 220)

                Text(unit)
                    .font(Theme.Text.title2)
                    .foregroundStyle(Theme.fgPrimary)
                    .padding(.leading, 4)
            }
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            ChickenPrimaryButton(
                title: "Log weight",
                height: 72,
                font: Theme.Text.title3,
                titleColor: Theme.buttonCream
            ) {
                let display = Double(choice.whole) + Double(choice.tenth) / 10
                let kg = unit == "lb" ? display / 2.2046226218 : display
                onLog(kg)
                onClose()
            }
            .padding(.bottom, 12)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity)
        .frame(height: 424)
        .background(alignment: .top) {
            UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28, style: .continuous)
                .fill(Theme.surface)
                .ignoresSafeArea(edges: .bottom)
        }
        .offset(y: dragY)
    }
}

private final class WeightWheelReadout {
    var whole: Int
    var tenth: Int

    init(whole: Int, tenth: Int) {
        self.whole = whole
        self.tenth = tenth
    }
}

private struct WeightDrum: UIViewRepresentable {
    enum Part { case whole, tenth }

    let values: [Int]
    @Binding var selection: Int
    let choice: WeightWheelReadout
    let part: Part

    func makeUIView(context: Context) -> DrumColumn {
        let column = DrumColumn(values: values)
        column.onValue = { value in
            switch part {
            case .whole: choice.whole = value
            case .tenth: choice.tenth = value
            }
            if selection != value { selection = value }
        }
        column.select(values.firstIndex(of: selection) ?? 0)
        return column
    }

    func updateUIView(_ column: DrumColumn, context: Context) {
        column.onValue = { value in
            switch part {
            case .whole: choice.whole = value
            case .tenth: choice.tenth = value
            }
            if selection != value { selection = value }
        }
    }
}

private final class DrumColumn: UIScrollView, UIScrollViewDelegate {
    private let values: [Int]
    private let rowHeight: CGFloat = 44
    private var labels: [UILabel] = []
    private var pendingIndex = 0
    private var placed = false
    private var lastIndex: Int?
    private let selectionFeedback = UISelectionFeedbackGenerator()
    var onValue: ((Int) -> Void)?

    init(values: [Int]) {
        self.values = values
        super.init(frame: .zero)
        showsVerticalScrollIndicator = false
        alwaysBounceVertical = true
        decelerationRate = .fast
        clipsToBounds = true
        delegate = self
        let font = UIFont(name: "Workear Font", size: 34) ?? .systemFont(ofSize: 34)
        labels = values.map { value in
            let label = UILabel()
            label.text = "\(value)"
            label.textAlignment = .center
            label.font = font
            label.textColor = Self.secondary
            label.isUserInteractionEnabled = false
            addSubview(label)
            return label
        }
    }

    required init?(coder: NSCoder) { nil }

    func select(_ index: Int) {
        pendingIndex = min(max(index, 0), max(values.count - 1, 0))
        placed = false
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let width = bounds.width
        let inset = max(0, (bounds.height - rowHeight) / 2)
        contentInset = UIEdgeInsets(top: inset, left: 0, bottom: inset, right: 0)
        for (index, label) in labels.enumerated() {
            label.frame = CGRect(x: 0, y: CGFloat(index) * rowHeight, width: width, height: rowHeight)
        }
        contentSize = CGSize(width: width, height: CGFloat(values.count) * rowHeight)
        if !placed, bounds.height > 0 {
            placed = true
            contentOffset = offset(for: pendingIndex)
        }
        recolor()
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        selectionFeedback.prepare()
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        recolor()
        guard let value = centeredValue() else { return }
        let index = values.firstIndex(of: value)
        if let index, index != lastIndex {
            if lastIndex != nil {
                selectionFeedback.selectionChanged()
                selectionFeedback.prepare()
            }
            lastIndex = index
        }
        onValue?(value)
    }

    func scrollViewWillEndDragging(
        _ scrollView: UIScrollView,
        withVelocity velocity: CGPoint,
        targetContentOffset: UnsafeMutablePointer<CGPoint>
    ) {
        let index = index(at: targetContentOffset.pointee.y)
        targetContentOffset.pointee.y = offset(for: index).y
    }

    private func centeredValue() -> Int? {
        guard !values.isEmpty else { return nil }
        return values[index(at: contentOffset.y)]
    }

    private func index(at offsetY: CGFloat) -> Int {
        let center = offsetY + bounds.height / 2
        let raw = ((center - rowHeight / 2) / rowHeight).rounded()
        return min(max(Int(raw), 0), values.count - 1)
    }

    private func offset(for index: Int) -> CGPoint {
        CGPoint(x: 0, y: CGFloat(index) * rowHeight - contentInset.top)
    }

    private func recolor() {
        let center = contentOffset.y + bounds.height / 2
        var closest: UILabel?
        var best = CGFloat.greatestFiniteMagnitude
        for label in labels {
            let distance = abs(label.frame.midY - center)
            if distance < best {
                best = distance
                closest = label
            }
        }
        for label in labels {
            let color = label === closest ? Self.primary : Self.secondary
            if label.textColor != color { label.textColor = color }
        }
    }

    private static let primary = UIColor(Theme.fgPrimary)
    private static let secondary = UIColor(Theme.fgSecondary.opacity(0.55))
}
