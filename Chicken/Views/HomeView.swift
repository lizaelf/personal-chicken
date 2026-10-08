import SwiftUI

struct HomeView: View {
    let session: WorkoutSession
    @State private var selectedTab: HomeTab = .home
    @State private var selectedDay = Self.currentWeekdayId()
    @State private var showingSettings = false
    @State private var showingNotifications = false
    @State private var unreadNoteIDs: Set<String> = []
    @State private var weightUnit = "kg"
    @State private var showingWeightSheet = false
    @State private var currentWeightKg = 62.4
    @State private var lastWeekWeightKg = 63.2

    var body: some View {
        GeometryReader { geo in
            let cardWidth = geo.size.width - 32

            VStack(spacing: 0) {
                if showingSettings {
                    settingsContent
                } else if showingNotifications {
                    notificationsContent
                } else {
                    ZStack(alignment: .bottom) {
                        Group {
                            switch selectedTab {
                            case .home:
                                VStack(alignment: .leading, spacing: 16) {
                                    weeklyPlan
                                    dayPager(cardWidth: cardWidth)
                                    weightCard
                                }
                            case .workouts:
                                workoutsContent(cardWidth: cardWidth)
                            case .statistics:
                                statisticsContent
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        .padding(.top, 4)
                        .padding(.bottom, 88)

                        tabBar
                    }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.canvas.ignoresSafeArea())
        .ignoresSafeArea(.container, edges: .bottom)
        .sheet(isPresented: $showingWeightSheet) {
            WeightLogSheet(
                initialKg: currentWeightKg,
                unit: weightUnit,
                onLog: { currentWeightKg = $0 }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(28)
            .presentationBackground(Theme.surface)
        }
        .sensoryFeedback(.selection, trigger: selectedTab)
        .sensoryFeedback(.selection, trigger: selectedDay)
        .sensoryFeedback(.selection, trigger: weightUnit)
        .sensoryFeedback(.selection, trigger: session.soundsEnabled)
        .sensoryFeedback(.success, trigger: currentWeightKg)
        .sensoryFeedback(.impact(weight: .light), trigger: showingSettings)
        .sensoryFeedback(.impact(weight: .light), trigger: showingNotifications)
        .sensoryFeedback(.impact(weight: .light), trigger: showingWeightSheet)
        .sensoryFeedback(.impact(weight: .light), trigger: unreadNoteIDs.isEmpty) { wasEmpty, isEmpty in
            !wasEmpty && isEmpty
        }
    }

    private var weeklyPlan: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center) {
                Text("Today")
                    .font(.workear(size: 24, relativeTo: .title2))
                    .foregroundStyle(Theme.fgPrimary)
                Spacer()
                HStack(spacing: 14) {
                    iconButton(asset: "IconNotification", size: 18)
                    iconButton(asset: "IconSettings", size: 20)
                }
            }
            .padding(.horizontal, 16)

            weekDays
        }
    }

    private var weekDays: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(WeekDay.week(starting: todayDay)) { day in
                        Button {
                            selectedDay = day.id
                        } label: {
                            if day.id == selectedDay, let copy = dayCopy(for: day) {
                                labeledDayChip(day, copy: copy)
                            } else {
                                dayDot(day, accent: day.id == todayDay)
                            }
                        }
                        .buttonStyle(.plain)
                        .id(day.id)
                        .accessibilityAddTraits(day.id == selectedDay ? .isSelected : [])
                    }
                }
            }
            .contentMargins(.horizontal, 16, for: .scrollContent)
            .onAppear {
                DispatchQueue.main.async {
                    proxy.scrollTo(selectedDay, anchor: .leading)
                }
            }
            .onChange(of: selectedDay) { _, day in
                withAnimation(.easeInOut(duration: 0.35)) {
                    proxy.scrollTo(day, anchor: .leading)
                }
            }
        }
    }

    private func dayCopy(for day: WeekDay) -> String? {
        if day.id == todayDay { return "Let’s work. Cluck cluck" }
        if day.showsBorder { return "Future trainings" }
        return "Free day"
    }

    private func labeledDayChip(_ day: WeekDay, copy: String) -> some View {
        let selected = day.id == selectedDay
        let isToday = day.id == todayDay
        let isFree = !isToday && !day.showsBorder
        let fillInner = (selected || isToday) && !isFree
        return HStack(spacing: 8) {
            Text(day.label)
                .font(.workear(size: 12, relativeTo: .caption))
                .foregroundStyle(fillInner ? Color.white : Theme.fgSecondary)
                .frame(width: 34, height: 34)
                .background {
                    Circle().fill(fillInner ? Theme.fgAccent : (isFree ? Theme.fgSecondary.opacity(0.2) : Color.clear))
                }
                .overlay {
                    if !fillInner {
                        if day.showsBorder {
                            Circle().stroke(Theme.borderAccent, lineWidth: 1)
                        } else if isFree {
                            Circle().stroke(Theme.fgSecondary.opacity(0.24), lineWidth: 1)
                        }
                    }
                }

            Text(copy)
                .font(.workear(size: 14, relativeTo: .body))
                .foregroundStyle(selected || !isFree ? Theme.fgPrimary : Theme.fgSecondary)
                .lineLimit(1)
                .fixedSize()
                .padding(.trailing, 11)
        }
        .padding(.leading, 4)
        .padding(.vertical, 4)
        .frame(height: 44)
        .fixedSize(horizontal: true, vertical: true)
        .background(Theme.surface, in: Capsule())
        .overlay {
            Capsule().stroke(isFree ? Theme.fgSecondary.opacity(0.28) : Theme.borderAccent, lineWidth: 1)
        }
    }

    private var todayDay: String { Self.currentWeekdayId() }

    private static func currentWeekdayId() -> String {
        let map = [1: "Su", 2: "Mo", 3: "Tu", 4: "We", 5: "Th", 6: "Fr", 7: "Sa"]
        let weekday = Calendar.current.component(.weekday, from: Date())
        return map[weekday] ?? "Mo"
    }

    private func dayDot(_ day: WeekDay, accent: Bool) -> some View {
        Text(day.label)
            .font(.workear(size: 14, relativeTo: .body))
            .foregroundStyle(accent ? Color.white : day.foreground)
            .frame(width: 34, height: 34)
            .background {
                Circle().fill(accent ? Theme.fgAccent : day.fill)
            }
            .overlay {
                if !accent {
                    Circle().stroke(
                        day.showsBorder ? Theme.borderAccent : Theme.fgSecondary.opacity(0.24),
                        lineWidth: 1
                    )
                }
            }
    }

    private func dayPager(cardWidth: CGFloat) -> some View {
        TabView(selection: $selectedDay) {
            ForEach(WeekDay.week(starting: todayDay)) { day in
                dayPage(for: day, width: cardWidth)
                    .padding(.horizontal, 16)
                    .tag(day.id)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .animation(.easeInOut(duration: 0.35), value: selectedDay)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func dayPage(for day: WeekDay, width: CGFloat) -> some View {
        let kind = pageKind(for: day)
        return Group {
            switch kind {
            case .train(let live, let title, let image):
                workoutCard(width: width, title: title, live: live, image: image)
            case .rest(let title):
                restCard(width: width, title: title)
            }
        }
    }

    private func pageKind(for day: WeekDay) -> DayPageKind {
        if day.id == todayDay {
            return .train(live: true, title: "Abs & Glutes", image: "ChickenAbs")
        }
        if day.showsBorder {
            let wing = day.id == "Fr"
            return .train(
                live: false,
                title: wing ? "Wing press" : "Abs & Glutes",
                image: wing ? "ChickenShoulderPress" : "ChickenAbs"
            )
        }
        return .rest(title: "Free day")
    }

    private func workoutCard(width: CGFloat, title: String, live: Bool, image: String) -> some View {
        let wing = title == "Wing press"
        return VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 11) {
                Text(title)
                    .font(.workear(size: 26, relativeTo: .title))
                    .foregroundStyle(Theme.fgPrimary)

                HStack(spacing: 6) {
                    chip(wing ? "18 min" : "20 min")
                    if wing {
                        chip("Dumbbells", icon: "IconDumbbells")
                    } else {
                        chip("Kettlebells", icon: "IconDumbbells")
                        chip("Mat", icon: "IconYogaMat")
                    }
                }
            }
            .padding(.top, 24)
            .padding(.horizontal, 24)

            Group {
                if live {
                    ChickenMediaView(media: .video("SequenceHome"), isPlaying: true)
                } else {
                    Image(image)
                        .resizable()
                        .scaledToFit()
                }
            }
            .padding(.horizontal, 4)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Button(action: startWorkout) {
                HStack(spacing: 10) {
                    Text(live ? "Start" : "Open workout")
                        .font(.workear(size: 16, relativeTo: .headline))
                        .foregroundStyle(Theme.surface)
                    if live {
                        Image("IconStartArrow")
                            .frame(width: 18, height: 18)
                    }
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

    private func restCard(width: CGFloat, title: String) -> some View {
        ZStack(alignment: .bottom) {
            ChickenMediaView(media: .video("SequenceFreeDay"), isPlaying: true, fillsBounds: true)
                .scaleEffect(0.8, anchor: .bottom)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .clipped()
        }
        .frame(width: width)
        .frame(maxHeight: .infinity)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(alignment: .topLeading) {
            Text(title)
                .font(.workear(size: 26, relativeTo: .title))
                .foregroundStyle(Theme.fgPrimary)
                .padding(.top, 24)
                .padding(.horizontal, 24)
                .accessibilityAddTraits(.isHeader)
        }
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
        .background(Theme.fgSecondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Theme.fgSecondary.opacity(0.24), lineWidth: 1)
        }
    }

    private var hasWeightForSelectedDay: Bool {
        selectedDay == todayDay
    }

    private var weightCard: some View {
        HStack(alignment: .bottom, spacing: 16) {
            if hasWeightForSelectedDay {
                weightFilled
                weightAddButton
            } else {
                weightEmpty
            }
        }
        .frame(minHeight: 55, alignment: .center)
        .padding(24)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .padding(.horizontal, 16)
        .animation(.easeInOut(duration: 0.25), value: selectedDay)
    }

    private var weightFilled: some View {
        HStack(alignment: .bottom, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text("My weight")
                    .font(.workear(size: 14, relativeTo: .body))
                    .foregroundStyle(Theme.fgSecondary)
                Text(formattedWeight(currentWeightKg))
                    .font(.workear(size: 22, relativeTo: .title2))
                    .foregroundStyle(Theme.fgPrimary)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: currentWeightKg)
            }

            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 4) {
                    Text(formattedDelta)
                        .font(.workear(size: 14, relativeTo: .body))
                        .foregroundStyle(Theme.fgPositive)
                    Image("IconDeltaDown")
                        .frame(width: 6, height: 6.4)
                }
                Text("vs last week")
                    .font(.workear(size: 14, relativeTo: .body))
                    .foregroundStyle(Theme.fgSecondary)
            }

            WeightSparkline()
                .frame(maxWidth: .infinity)
                .frame(height: 44)
        }
    }

    private var weightEmpty: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("My weight")
                .font(.workear(size: 14, relativeTo: .body))
                .foregroundStyle(Theme.fgSecondary)
            Text("We’ll see… in the future.")
                .font(.workear(size: 22, relativeTo: .title2))
                .foregroundStyle(Theme.fgSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var weightAddButton: some View {
        Button {
            showingWeightSheet = true
        } label: {
            Image("IconPlus")
                .frame(width: 18, height: 18)
                .frame(width: 48, height: 48)
                .background(.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .shadow(color: .black.opacity(0.1), radius: 2.7, x: 0, y: 0.9)
        .accessibilityLabel("Add weight")
    }

    private func workoutsContent(cardWidth: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center) {
                Text("Extra workouts")
                    .font(.workear(size: 24, relativeTo: .title2))
                    .foregroundStyle(Theme.fgPrimary)
                Spacer()
                HStack(spacing: 14) {
                    iconButton(asset: "IconNotification", size: 18)
                    iconButton(asset: "IconSettings", size: 20)
                }
            }
            .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(ExtraWorkout.all) { item in
                        extraWorkoutCard(item, width: cardWidth)
                    }
                }
                .scrollTargetLayout()
                .padding(.leading, 16)
                .padding(.trailing, 16)
            }
            .scrollTargetBehavior(.viewAligned)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func extraWorkoutCard(_ item: ExtraWorkout, width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("\(item.line1) \(item.line2)")
                .font(.workear(size: 40, relativeTo: .largeTitle))
                .foregroundStyle(Theme.fgPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.top, 24)
                .padding(.horizontal, 24)

            Image(item.image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    chip(item.duration)
                    ForEach(item.equipment) { gear in
                        chip(gear.title, icon: gear.icon)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)

            Button(action: startWorkout) {
                Text("Open workout")
                    .font(.workear(size: 16, relativeTo: .headline))
                    .foregroundStyle(Theme.surface)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Theme.coral, in: Capsule())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .frame(width: width)
        .frame(maxHeight: .infinity)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var statisticsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center) {
                Text("Statistics")
                    .font(.workear(size: 24, relativeTo: .title2))
                    .foregroundStyle(Theme.fgPrimary)
                Spacer()
                HStack(spacing: 14) {
                    iconButton(asset: "IconNotification", size: 18)
                    iconButton(asset: "IconSettings", size: 20)
                }
            }
            .padding(.horizontal, 16)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 8) {
                    StatsTrendCard(
                        title: "Calories",
                        value: "12,480 kcal",
                        delta: "+840 this week",
                        values: FitnessStats.calorieTrend,
                        startLabel: "Jul 4"
                    )
                    StatsTrendCard(
                        title: "Weight",
                        value: formattedWeight(currentWeightKg),
                        delta: formattedWeightLoss,
                        values: FitnessStats.weightTrend(endingAt: currentWeightKg),
                        startLabel: "Jan"
                    )
                    statsCalendarCard
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var statsCalendarCard: some View {
        VStack(spacing: 24) {
            ForEach(FitnessStats.yearMonths) { month in
                VStack(spacing: 12) {
                    Text(month.name)
                        .font(.workear(size: 16, relativeTo: .headline))
                        .foregroundStyle(Theme.fgPrimary)

                    HStack {
                        ForEach(Array(FitnessStats.weekdayLetters.enumerated()), id: \.offset) { _, day in
                            Text(day)
                                .font(.workear(size: 12, relativeTo: .caption))
                                .foregroundStyle(Theme.fgSecondary)
                                .frame(maxWidth: .infinity)
                        }
                    }

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 8) {
                        ForEach(month.cells) { cell in
                            statsDayCell(cell)
                        }
                    }
                }
            }
        }
        .padding(24)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private func statsDayCell(_ cell: FitnessDay) -> some View {
        ZStack {
            Circle()
                .fill(cell.day == nil ? Color.clear : (cell.workedOut ? Theme.cream : Theme.bgSoft))
            if let day = cell.day {
                if cell.workedOut {
                    Image("CalendarChicken")
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(0.59)
                        .accessibilityHidden(true)
                } else {
                    Text("\(day)")
                        .font(.workear(size: 12, relativeTo: .caption))
                        .foregroundStyle(Theme.fgSecondary)
                }
            }
        }
        .frame(height: 32)
        .overlay {
            if cell.workedOut {
                Circle().stroke(Theme.coral, lineWidth: 1.5)
            } else if cell.isToday {
                Circle().stroke(Theme.fgPrimary.opacity(0.35), lineWidth: 1.5)
            }
        }
        .accessibilityLabel(cell.accessibilityLabel)
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
                            tab == selectedTab ? Theme.surface : Theme.bgSoft,
                            in: Capsule()
                        )
                        .overlay {
                            if tab != selectedTab {
                                Capsule().stroke(Theme.fgSecondary.opacity(0.24), lineWidth: 1)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 16)
        .padding(.horizontal, 16)
        .padding(.bottom, 32)
        .background {
            ZStack {
                Rectangle().fill(.ultraThinMaterial)
                LinearGradient(
                    colors: [Theme.canvas.opacity(0), Theme.canvas],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .ignoresSafeArea(edges: .bottom)
        }
    }

    private var notificationsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showingNotifications = false
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.fgPrimary)
                        .frame(width: 32, height: 32)
                        .background(Theme.bgMuted, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back")

                Text("Notifications")
                    .font(.workear(size: 24, relativeTo: .title2))
                    .foregroundStyle(Theme.fgPrimary)
                Spacer()
                if !unreadNoteIDs.isEmpty {
                    Button("Read all") {
                        unreadNoteIDs.removeAll()
                    }
                    .font(.workear(size: 14, relativeTo: .body))
                    .foregroundStyle(Theme.fgSecondary)
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)

            VStack(spacing: 8) {
                Image("IconNotification")
                    .frame(width: 24, height: 24)
                    .frame(width: 64, height: 64)
                    .background(Theme.bgMuted, in: Circle())
                    .padding(.bottom, 8)
                    .accessibilityHidden(true)
                Text("No new notifications")
                    .font(.workear(size: 20, relativeTo: .title3))
                    .foregroundStyle(Theme.fgPrimary)
                Text("Not even one egg in the nest.")
                    .font(.workear(size: 14, relativeTo: .body))
                    .foregroundStyle(Theme.fgSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(.top, 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func noteSection(title: String, items: [AppNote]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.workear(size: 14, relativeTo: .body))
                .foregroundStyle(Theme.fgSecondary)
                .padding(.horizontal, 8)
            VStack(spacing: 0) {
                ForEach(items) { note in
                    noteRow(note)
                }
            }
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        }
    }

    private func noteRow(_ note: AppNote) -> some View {
        let unread = unreadNoteIDs.contains(note.id)
        return HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(note.title)
                    .font(.workear(size: 16, relativeTo: .headline))
                    .foregroundStyle(Theme.fgPrimary)
                Text(note.body)
                    .font(.workear(size: 14, relativeTo: .body))
                    .foregroundStyle(Theme.fgSecondary)
                    .multilineTextAlignment(.leading)
                Text(note.time)
                    .font(.workear(size: 14, relativeTo: .body))
                    .foregroundStyle(Theme.fgSecondary.opacity(0.8))
                if note.startsWorkout {
                    Button("Continue") {
                        unreadNoteIDs.remove(note.id)
                        startWorkout()
                    }
                    .font(.workear(size: 14, relativeTo: .body))
                    .foregroundStyle(Theme.coral)
                    .buttonStyle(.plain)
                }
            }
            Spacer(minLength: 0)
            Circle()
                .fill(unread ? Theme.coral : Color.clear)
                .frame(width: 8, height: 8)
                .padding(.top, 6)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .contentShape(Rectangle())
        .onTapGesture {
            unreadNoteIDs.remove(note.id)
        }
    }

    private var settingsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showingSettings = false
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.fgPrimary)
                        .frame(width: 32, height: 32)
                        .background(Theme.bgMuted, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back")

                Text("Settings")
                    .font(.workear(size: 24, relativeTo: .title2))
                    .foregroundStyle(Theme.fgPrimary)
                Spacer()
            }
            .padding(.horizontal, 16)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    settingsGroup(title: "Preferences") {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Weight")
                                .font(.workear(size: 16, relativeTo: .headline))
                                .foregroundStyle(Theme.fgPrimary)
                            HStack(spacing: 8) {
                                ForEach(["kg", "lb"], id: \.self) { unit in
                                    Button {
                                        weightUnit = unit
                                    } label: {
                                        Text(unit)
                                            .font(.workear(size: 14, relativeTo: .body))
                                            .foregroundStyle(unit == weightUnit ? Theme.fgInverse : Theme.fgSecondary)
                                            .padding(.horizontal, 16)
                                            .frame(height: 36)
                                            .background(
                                                unit == weightUnit ? Theme.canvas : Theme.bgSoft,
                                                in: Capsule()
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)

                        settingsToggle("Sounds", isOn: Bindable(session).soundsEnabled)
                    }

                    settingsGroup(title: "About") {
                        settingsInfo("Version", value: "beta")
                    }

                    Text("made by Lisa Pasichnyk")
                        .font(.workear(size: 14, relativeTo: .body))
                        .foregroundStyle(Theme.fgSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)
                        .padding(.bottom, 8)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
        }
        .padding(.top, 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func settingsGroup<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.workear(size: 14, relativeTo: .body))
                .foregroundStyle(Theme.fgSecondary)
                .padding(.horizontal, 8)
            VStack(spacing: 0) {
                content()
            }
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        }
    }

    private func settingsToggle(_ title: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Text(title)
                .font(.workear(size: 16, relativeTo: .headline))
                .foregroundStyle(Theme.fgPrimary)
        }
        .tint(Theme.coral)
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    private func settingsInfo(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.workear(size: 16, relativeTo: .headline))
                .foregroundStyle(Theme.fgPrimary)
            Spacer()
            Text(value)
                .font(.workear(size: 14, relativeTo: .body))
                .foregroundStyle(Theme.fgSecondary)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    private func iconButton(asset: String, size: CGFloat) -> some View {
        Button {
            if asset == "IconSettings" {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showingNotifications = false
                    showingSettings = true
                }
            } else if asset == "IconNotification" {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showingSettings = false
                    showingNotifications = true
                }
            }
        } label: {
            Image(asset)
                .frame(width: size, height: size)
                .frame(width: 32, height: 32)
                .background(Theme.bgMuted, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(asset == "IconNotification" ? "Notifications" : "Settings")
    }

    private var formattedDelta: String {
        let delta = displayWeight(currentWeightKg) - displayWeight(lastWeekWeightKg)
        let sign = delta > 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", delta)) \(weightUnit)"
    }

    private var formattedWeightLoss: String {
        let loss = displayWeight(FitnessStats.startWeightKg) - displayWeight(currentWeightKg)
        return "−\(String(format: "%.1f", abs(loss))) \(weightUnit)"
    }

    private func displayWeight(_ kg: Double) -> Double {
        weightUnit == "lb" ? kg * 2.2046226218 : kg
    }

    private func formattedWeight(_ kg: Double) -> String {
        "\(String(format: "%.1f", displayWeight(kg))) \(weightUnit)"
    }

    private func startWorkout() {
        withAnimation(.spring(duration: 0.5, bounce: 0.08)) {
            session.beginCountdown()
        }
    }
}

private struct WeightLogSheet: View {
    let unit: String
    let onLog: (Double) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var whole: Int
    @State private var tenth: Int

    init(initialKg: Double, unit: String, onLog: @escaping (Double) -> Void) {
        self.unit = unit
        self.onLog = onLog
        let display = unit == "lb" ? initialKg * 2.2046226218 : initialKg
        let rounded = (display * 10).rounded() / 10
        _whole = State(initialValue: min(200, max(30, Int(rounded.rounded(.down)))))
        _tenth = State(initialValue: Int((rounded * 10).rounded()) % 10)
    }

    var body: some View {
        VStack(spacing: 0) {
            Text("Your current weight")
                .font(.workear(size: 24, relativeTo: .title2))
                .foregroundStyle(Theme.fgPrimary)
                .padding(.top, 28)
                .padding(.bottom, 20)

            HStack(spacing: 2) {
                Picker("Kilograms", selection: $whole) {
                    ForEach(30...200, id: \.self) { value in
                        Text("\(value)")
                            .font(.workear(size: 34, relativeTo: .largeTitle))
                            .tag(value)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 96)
                .sensoryFeedback(.selection, trigger: whole)

                Text(".")
                    .font(.workear(size: 40, relativeTo: .largeTitle))
                    .foregroundStyle(Theme.fgPrimary)

                Picker("Decimal", selection: $tenth) {
                    ForEach(0...9, id: \.self) { value in
                        Text("\(value)")
                            .font(.workear(size: 34, relativeTo: .largeTitle))
                            .tag(value)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 56)
                .sensoryFeedback(.selection, trigger: tenth)

                Text(unit)
                    .font(.workear(size: 22, relativeTo: .title3))
                    .foregroundStyle(Theme.fgPrimary)
                    .padding(.leading, 4)
            }
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Button {
                let display = Double(whole) + Double(tenth) / 10
                let kg = unit == "lb" ? display / 2.2046226218 : display
                onLog(kg)
                dismiss()
            } label: {
                Text("Log weight")
                    .font(.workear(size: 20, relativeTo: .title3))
                    .foregroundStyle(Theme.buttonCream)
                    .frame(maxWidth: .infinity)
                    .frame(height: 72)
                    .background(Theme.coral, in: RoundedRectangle(cornerRadius: 25, style: .continuous))
                    .shadow(color: .black.opacity(0.1), radius: 1.35, x: 0, y: 0.9)
            }
            .buttonStyle(.plain)
            .padding(.bottom, 28)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.surface.ignoresSafeArea())
    }
}

private struct AppNote: Identifiable {
    let id: String
    let title: String
    let body: String
    let time: String
    let startsWorkout: Bool

    static let today: [AppNote] = [
        AppNote(
            id: "workout",
            title: "Don’t chicken out",
            body: "Abs & Glutes is waiting. 20 min on the mat.",
            time: "2h ago",
            startsWorkout: true
        ),
        AppNote(
            id: "streak",
            title: "4-day streak",
            body: "Peck today or the streak resets.",
            time: "5h ago",
            startsWorkout: false
        ),
    ]

    static let yesterday: [AppNote] = [
        AppNote(
            id: "weight",
            title: "Weight logged",
            body: "62.4 kg · −0.8 vs last week.",
            time: "Yesterday",
            startsWorkout: false
        ),
        AppNote(
            id: "club",
            title: "Joined Core Club",
            body: "Daily abs, 18 minutes. Hatch a habit.",
            time: "Yesterday",
            startsWorkout: false
        ),
    ]
}

private struct FitnessDay: Identifiable {
    let id: Int
    let day: Int?
    let workedOut: Bool
    let isToday: Bool
    let monthName: String

    var accessibilityLabel: String {
        guard let day else { return "Empty" }
        if workedOut { return "\(monthName) \(day), workout done" }
        return "\(monthName) \(day)"
    }
}

private struct FitnessMonth: Identifiable {
    let id: Int
    let name: String
    let cells: [FitnessDay]
}

private enum FitnessStats {
    static let startWeightKg = 65.6
    static let weekdayLetters = ["M", "T", "W", "T", "F", "S", "S"]
    static let monthNames = [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December",
    ]
    static let calorieTrend: [Double] = [980, 1120, 1340, 1510, 1680, 1840, 2040, 2200]
    static let workoutDays: Set<Int> = [1, 3, 5, 8, 10, 12, 15, 17, 19, 22, 24, 26, 28, 29, 30]
    private static let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2
        return cal
    }()

    static var yearMonths: [FitnessMonth] {
        let currentMonth = calendar.component(.month, from: Date())
        let order = (0..<12).map { offset in
            ((currentMonth - 1 - offset + 12) % 12) + 1
        }
        return order.map { month in
            FitnessMonth(id: month, name: monthNames[month - 1], cells: cells(year: 2026, month: month))
        }
    }

    static func cells(year: Int, month: Int) -> [FitnessDay] {
        var firstParts = DateComponents()
        firstParts.year = year
        firstParts.month = month
        firstParts.day = 1
        guard let first = calendar.date(from: firstParts),
              let dayRange = calendar.range(of: .day, in: .month, for: first) else { return [] }

        let weekday = calendar.component(.weekday, from: first)
        let leading = (weekday - calendar.firstWeekday + 7) % 7
        let monthName = monthNames[month - 1]
        let today = calendar.startOfDay(for: Date())
        let todayParts = calendar.dateComponents([.year, .month, .day], from: today)

        var result: [FitnessDay] = (0..<leading).map { blank in
            FitnessDay(
                id: year * 10000 + month * 100 - blank - 1,
                day: nil,
                workedOut: false,
                isToday: false,
                monthName: monthName
            )
        }

        result += dayRange.map { day in
            var parts = DateComponents()
            parts.year = year
            parts.month = month
            parts.day = day
            let date = calendar.date(from: parts)
            let isFuture = date.map { calendar.startOfDay(for: $0) > today } ?? false
            return FitnessDay(
                id: year * 10000 + month * 100 + day,
                day: day,
                workedOut: !isFuture && workoutDays.contains(day),
                isToday: year == todayParts.year && month == todayParts.month && day == todayParts.day,
                monthName: monthName
            )
        }
        return result
    }

    static var chartEndLabel: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMM d"
        return formatter.string(from: Date())
    }

    static func weightTrend(endingAt current: Double) -> [Double?] {
        [65.6, 65.4, 65.1, 64.8, 64.5, 64.1, 63.8, 63.3, current, nil, nil, nil]
    }
}

private struct StatsTrendCard: View {
    let title: String
    let value: String
    let delta: String
    let values: [Double?]
    let startLabel: String

    init(title: String, value: String, delta: String, values: [Double], startLabel: String) {
        self.title = title
        self.value = value
        self.delta = delta
        self.values = values.map { Optional($0) }
        self.startLabel = startLabel
    }

    init(title: String, value: String, delta: String, values: [Double?], startLabel: String) {
        self.title = title
        self.value = value
        self.delta = delta
        self.values = values
        self.startLabel = startLabel
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top, spacing: 10) {
                    Text(title)
                        .font(.workear(size: 16, relativeTo: .headline))
                        .foregroundStyle(Theme.fgPrimary)
                    Spacer()
                    Text(value)
                        .font(.workear(size: 28, relativeTo: .title))
                        .foregroundStyle(Theme.fgPrimary)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                }

                Text(delta)
                    .font(.workear(size: 14, relativeTo: .body))
                    .foregroundStyle(Theme.fgPositive)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }

            WeightTrendChart(values: values)
                .frame(height: 120)

            HStack {
                Text(startLabel)
                Spacer()
                Text(FitnessStats.chartEndLabel)
            }
            .font(.workear(size: 12, relativeTo: .caption))
            .foregroundStyle(Theme.fgSecondary)
        }
        .padding(24)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}

private struct WeightSparkline: View {
    private static let viewBox = CGSize(width: 52, height: 44)
    private static let points: [CGPoint] = [
        CGPoint(x: 1.83236, y: 14.5),
        CGPoint(x: 10.9943, y: 18.5),
        CGPoint(x: 18.3238, y: 16.5),
        CGPoint(x: 27.4857, y: 26.5),
        CGPoint(x: 36.6476, y: 22.5),
        CGPoint(x: 49.4743, y: 32.5),
    ]

    var body: some View {
        GeometryReader { geo in
            let sx = geo.size.width / Self.viewBox.width
            let sy = geo.size.height / Self.viewBox.height
            let scaled = Self.points.map { CGPoint(x: $0.x * sx, y: $0.y * sy) }

            Path { path in
                guard let first = scaled.first else { return }
                path.move(to: first)
                scaled.dropFirst().forEach { path.addLine(to: $0) }
            }
            .stroke(
                Theme.fgPositive,
                style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round)
            )

            if let last = scaled.last {
                Circle()
                    .fill(Theme.fgPositive)
                    .frame(width: 8, height: 8)
                    .position(last)
            }
        }
        .accessibilityHidden(true)
    }
}

private struct WeightTrendChart: View {
    let values: [Double?]

    init(values: [Double]) {
        self.values = values.map { Optional($0) }
    }

    init(values: [Double?]) {
        self.values = values
    }

    var body: some View {
        GeometryReader { geo in
            let known = values.compactMap { $0 }
            let rawMin = known.min() ?? 0
            let rawMax = known.max() ?? 1
            let pad = max((rawMax - rawMin) * 0.08, 0.2)
            let minV = rawMin - pad
            let maxV = rawMax + pad
            let span = max(maxV - minV, 0.1)
            let slots = max(known.count - 1, 1)
            let dotRadius: CGFloat = 4
            let insetX = dotRadius
            let insetY = dotRadius
            let plotW = geo.size.width - 2 * insetX
            let plotH = geo.size.height - 2 * insetY
            let points: [CGPoint] = known.enumerated().map { index, value in
                CGPoint(
                    x: insetX + plotW * CGFloat(index) / CGFloat(slots),
                    y: insetY + plotH * (1 - CGFloat((value - minV) / span))
                )
            }

            Path { path in
                guard let first = points.first else { return }
                path.move(to: CGPoint(x: first.x, y: geo.size.height))
                path.addLine(to: first)
                points.dropFirst().forEach { path.addLine(to: $0) }
                if let last = points.last {
                    path.addLine(to: CGPoint(x: last.x, y: geo.size.height))
                }
                path.closeSubpath()
            }
            .fill(Theme.coral.opacity(0.16))

            Path { path in
                guard let first = points.first else { return }
                path.move(to: first)
                points.dropFirst().forEach { path.addLine(to: $0) }
            }
            .stroke(Theme.coral, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))

            if let last = points.last {
                Circle()
                    .fill(Theme.coral)
                    .frame(width: 8, height: 8)
                    .position(last)
            }
        }
        .accessibilityHidden(true)
    }
}

private struct ExtraGear: Identifiable {
    let id: String
    let title: String
    let icon: String
}

private struct ExtraWorkout: Identifiable {
    let id: String
    let line1: String
    let line2: String
    let image: String
    let duration: String
    let equipment: [ExtraGear]

    static let all: [ExtraWorkout] = [
        ExtraWorkout(
            id: "butt",
            line1: "Fit",
            line2: "butt",
            image: "ChickenAbs",
            duration: "4 min",
            equipment: [
                ExtraGear(id: "mat", title: "Mat", icon: "IconYogaMat"),
            ]
        ),
        ExtraWorkout(
            id: "wings",
            line1: "Wing",
            line2: "press",
            image: "ChickenShoulderPress",
            duration: "4 min",
            equipment: [
                ExtraGear(id: "db", title: "Dumbbells", icon: "IconDumbbells"),
            ]
        ),
    ]
}

private enum DayPageKind {
    case train(live: Bool, title: String, image: String)
    case rest(title: String)
}

private enum HomeTab: String, CaseIterable, Identifiable {
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

private struct WeekDay: Identifiable {
    let id: String
    let label: String
    let fill: Color
    let foreground: Color
    let showsBorder: Bool

    static let all: [WeekDay] = [
        WeekDay(id: "Mo", label: "Mo", fill: Theme.bgSoft, foreground: Theme.fgSecondary, showsBorder: false),
        WeekDay(id: "Tu", label: "Tu", fill: Theme.bgSoft, foreground: Theme.fgSecondary, showsBorder: false),
        WeekDay(id: "We", label: "We", fill: .clear, foreground: Theme.fgSecondary, showsBorder: true),
        WeekDay(id: "Th", label: "Th", fill: Theme.bgSoft, foreground: Theme.fgSecondary, showsBorder: false),
        WeekDay(id: "Fr", label: "Fr", fill: .clear, foreground: Theme.fgSecondary, showsBorder: true),
        WeekDay(id: "Sa", label: "Sa", fill: Theme.bgSoft, foreground: Theme.fgSecondary, showsBorder: false),
        WeekDay(id: "Su", label: "Su", fill: Theme.bgSoft, foreground: Theme.fgSecondary, showsBorder: false),
    ]

    static func week(starting today: String) -> [WeekDay] {
        guard let index = all.firstIndex(where: { $0.id == today }) else { return all }
        return Array(all[index...]) + Array(all[..<index])
    }
}

#Preview {
    HomeView(session: WorkoutSession())
}
