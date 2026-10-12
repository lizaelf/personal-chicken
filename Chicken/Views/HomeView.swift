import SwiftUI

struct HomeView: View {
    let session: WorkoutSession
    @State private var selectedTab: HomeTab = .home

    var body: some View {
        GeometryReader { geo in
            let cardWidth = geo.size.width - 32

            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 16) {
                    weeklyPlan

                    workoutCarousel(cardWidth: cardWidth)

                    weightCard
                }
                .padding(.top, 4)
                .padding(.bottom, 16)

                tabBar
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.canvas.ignoresSafeArea())
        .ignoresSafeArea(.container, edges: .bottom)
    }

    private var weeklyPlan: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("4")
                        .font(.workear(size: 24, relativeTo: .title2))
                        .foregroundStyle(Theme.fgPrimary)
                    Text("days streak")
                        .font(.workear(size: 14, relativeTo: .body))
                        .foregroundStyle(Theme.fgSecondary)
                }
                Spacer()
                HStack(spacing: 14) {
                    iconButton(asset: "IconNotification", size: 18)
                    iconButton(asset: "IconSettings", size: 20)
                }
            }

            weekDays
        }
        .padding(.horizontal, 16)
    }

    private var weekDays: some View {
        HStack(spacing: 8) {
            todayChip
                .fixedSize(horizontal: true, vertical: true)
            ForEach(WeekDay.rest) { day in
                dayDot(day)
            }
        }
    }

    private var todayChip: some View {
        HStack(spacing: 8) {
            Text("Mo")
                .font(.workear(size: 12, relativeTo: .caption))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(Theme.fgAccent, in: Circle())

            Text("Let’s worko-ko!")
                .font(.workear(size: 14, relativeTo: .body))
                .foregroundStyle(Theme.fgPrimary)
                .lineLimit(1)
                .fixedSize()
                .padding(.trailing, 11)
        }
        .padding(.leading, 4)
        .padding(.vertical, 4)
        .background(Theme.surface, in: Capsule())
        .overlay {
            Capsule().stroke(Theme.borderAccent, lineWidth: 1)
        }
    }

    private func dayDot(_ day: WeekDay) -> some View {
        Text(day.label)
            .font(.workear(size: 14, relativeTo: .body))
            .foregroundStyle(day.foreground)
            .frame(width: 34, height: 34)
            .background {
                Circle().fill(day.fill)
            }
            .overlay {
                if day.showsBorder {
                    Circle().stroke(Theme.borderAccent, lineWidth: 1)
                }
            }
    }

    private func workoutCarousel(cardWidth: CGFloat) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                workoutCard(width: cardWidth)
                workoutCard(width: cardWidth)
            }
            .padding(.leading, 16)
            .padding(.trailing, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func workoutCard(width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 11) {
                Text("Abs & Glutes")
                    .font(.workear(size: 26, relativeTo: .title))
                    .foregroundStyle(Theme.fgPrimary)

                HStack(spacing: 6) {
                    chip("20 min")
                    chip("Kettlebells", icon: "IconDumbbells")
                    chip("Mat", icon: "IconYogaMat")
                }
            }
            .padding(.top, 24)
            .padding(.horizontal, 24)

            Image("HomeHeroChicken")
                .resizable()
                .scaledToFit()
                .padding(.horizontal, 4)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            Button(action: startWorkout) {
                HStack(spacing: 10) {
                    Text("Start")
                        .font(.workear(size: 16, relativeTo: .headline))
                        .foregroundStyle(Theme.surface)
                    Image("IconStartArrow")
                        .frame(width: 18, height: 18)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Theme.coral, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
            .shadow(color: .black.opacity(0.1), radius: 1.35, x: 0, y: 0.9)
            .padding(24)
        }
        .frame(width: width)
        .frame(maxHeight: .infinity)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private func chip(_ title: String, icon: String? = nil) -> some View {
        HStack(spacing: 6) {
            if let icon {
                Image(icon)
                    .frame(width: 18, height: 18)
            }
            Text(title)
                .font(.workear(size: 14, relativeTo: .body))
                .foregroundStyle(Theme.fgSecondary)
        }
        .padding(.leading, 10)
        .padding(.trailing, 12)
        .padding(.vertical, 8)
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Theme.fgSecondary.opacity(0.1), lineWidth: 1)
        }
    }

    private var weightCard: some View {
        HStack(alignment: .bottom, spacing: 16) {
            HStack(alignment: .bottom, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("My weight")
                        .font(.workear(size: 14, relativeTo: .body))
                        .foregroundStyle(Theme.fgSecondary)
                    Text("62.4 kg")
                        .font(.workear(size: 22, relativeTo: .title2))
                        .foregroundStyle(Theme.fgPrimary)
                }

                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 4) {
                        Text("-0.8 kg")
                            .font(.workear(size: 14, relativeTo: .body))
                            .foregroundStyle(Theme.fgPositive)
                        Image("IconDeltaDown")
                            .frame(width: 6, height: 6.4)
                    }
                    Text("vs last week")
                        .font(.workear(size: 14, relativeTo: .body))
                        .foregroundStyle(Theme.fgSecondary)
                }

                Image("WeightSparkline")
                    .frame(width: 52, height: 44)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: {}) {
                Image("IconPlus")
                    .frame(width: 18, height: 18)
                    .frame(width: 48, height: 48)
                    .background(.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
            .shadow(color: .black.opacity(0.1), radius: 2.7, x: 0, y: 0.9)
            .accessibilityLabel("Add weight")
        }
        .padding(24)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .padding(.horizontal, 16)
    }

    private var tabBar: some View {
        HStack(spacing: 8) {
            ForEach(HomeTab.allCases) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    Text(tab.title)
                        .font(.workear(size: 14, relativeTo: .body))
                        .foregroundStyle(tab == selectedTab ? Theme.fgInverse : Theme.fgSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(
                            tab == selectedTab ? Theme.surface : Theme.fgSecondary.opacity(0.1),
                            in: Capsule()
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 32)
    }

    private func iconButton(asset: String, size: CGFloat) -> some View {
        Button(action: {}) {
            Image(asset)
                .frame(width: size, height: size)
                .frame(width: 32, height: 32)
                .background(Theme.bgMuted, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(asset == "IconNotification" ? "Notifications" : "Settings")
    }

    private func startWorkout() {
        withAnimation(.spring(duration: 0.5, bounce: 0.08)) {
            session.startWorkout()
        }
    }
}

private enum HomeTab: String, CaseIterable, Identifiable {
    case home, challenges, statistics

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: return "Home"
        case .challenges: return "Challenges"
        case .statistics: return "Statistics"
        }
    }
}

private struct WeekDay: Identifiable {
    let id: String
    let label: String
    let fill: Color
    let foreground: Color
    let showsBorder: Bool

    static let rest: [WeekDay] = [
        WeekDay(id: "Tu", label: "Tu", fill: Theme.fgSecondary.opacity(0.1), foreground: Theme.fgSecondary, showsBorder: false),
        WeekDay(id: "We", label: "We", fill: .clear, foreground: Theme.fgSecondary, showsBorder: true),
        WeekDay(id: "Th", label: "Th", fill: Theme.fgSecondary.opacity(0.1), foreground: Theme.fgSecondary, showsBorder: false),
        WeekDay(id: "Fr", label: "Fr", fill: .clear, foreground: Theme.fgSecondary, showsBorder: true),
        WeekDay(id: "Sa", label: "Sa", fill: Theme.fgSecondary.opacity(0.1), foreground: Theme.fgSecondary, showsBorder: false),
        WeekDay(id: "Su", label: "Su", fill: Theme.fgSecondary.opacity(0.1), foreground: Theme.fgSecondary.opacity(0.1), showsBorder: false),
    ]
}

#Preview {
    HomeView(session: WorkoutSession())
}
