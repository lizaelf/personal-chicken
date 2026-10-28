import SwiftUI

struct HomeView: View {
    let session: WorkoutSession
    let log: FitnessLog
    @State private var selectedTab: HomeTab = .home
    @State private var selectedDay = Self.todayKey()
    /// Card pager position is derived from `selectedDay`. Swipes move exactly one day.
    @State private var dayStripRest: CGFloat = 0
    @State private var dayStripDrag: CGFloat = 0
    @State private var cardDrag: CGFloat = 0
    @State private var suppressWorkoutStart = false
    @State private var showingSettings = false
    @State private var showingNotifications = false
    @State private var unreadNoteIDs: Set<String> = []
    @AppStorage("weightUnit") private var weightUnit = "kg"
    @State private var showingWeightSheet = false
    @AppStorage("trainingDays") private var trainingDaysRaw = ""
    @State private var notes: [AppNote] = []
    @State private var scrollToStatsStreak = false
    @State private var trainingDayTick = 0
    @State private var noteReadTick = 0
    @State private var loggedWeightKg: Double?

    private var usesSampleWeight: Bool { log.weeklyWeightChange == nil }
    private var currentWeightKg: Double {
        loggedWeightKg ?? log.latestWeight?.kg ?? FitnessStats.baselineWeightKg
    }
    private var streakCount: Int {
        FitnessStats.streak(trainingDays: trainingDays, log: log)
    }
    private var streakLabel: String { streakCount == 1 ? "day streak" : "days streak" }
    private var shownWeeklyChange: Double? {
        if let change = log.weeklyWeightChange { return change }
        return currentWeightKg - FitnessStats.baselineLastWeekKg
    }

    var body: some View {
        GeometryReader { geo in
            let cardWidth = geo.size.width - 32

            VStack(spacing: 0) {
                if showingSettings {
                    settingsContent
                } else if showingNotifications {
                    notificationsContent
                } else {
                    Group {
                        switch selectedTab {
                        case .home:
                            VStack(alignment: .leading, spacing: Theme.Space.lg) {
                                weeklyPlan
                                VStack(alignment: .leading, spacing: Theme.Space.cardGap) {
                                    dayPager(cardWidth: cardWidth)
                                    weightCard
                                }
                            }
                        case .workouts:
                            workoutsContent(cardWidth: cardWidth)
                        case .statistics:
                            statisticsContent
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(.top, 4)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if !showingSettings && !showingNotifications {
                ChickenTabBar(selected: $selectedTab)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            seedTrainingDaysIfNeeded()
            if loggedWeightKg == nil {
                loggedWeightKg = log.latestWeight?.kg
            }
        }
        .overlay(alignment: .bottom) {
            ZStack(alignment: .bottom) {
                if showingWeightSheet {
                    Color.black.opacity(0.25)
                        .ignoresSafeArea()
                        .onTapGesture { showingWeightSheet = false }
                        .transition(.opacity)

                    WeightLogSheet(
                        initialKg: currentWeightKg,
                        unit: weightUnit,
                        onLog: { kg in
                            log.logWeight(kg)
                            loggedWeightKg = kg
                        },
                        onClose: { showingWeightSheet = false }
                    )
                    .transition(.move(edge: .bottom))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .animation(.spring(duration: 0.4, bounce: 0), value: showingWeightSheet)
        }
        .sensoryFeedback(.selection, trigger: selectedTab)
        .sensoryFeedback(.selection, trigger: selectedDay)
        .sensoryFeedback(.selection, trigger: weightUnit)
        .sensoryFeedback(.selection, trigger: session.soundsEnabled)
        .sensoryFeedback(.success, trigger: log.weights)
        .sensoryFeedback(.impact(weight: .light), trigger: showingSettings)
        .sensoryFeedback(.impact(weight: .light), trigger: showingNotifications)
        .sensoryFeedback(.impact(weight: .light), trigger: showingWeightSheet)
        .sensoryFeedback(.impact(weight: .light), trigger: unreadNoteIDs.isEmpty) { wasEmpty, isEmpty in
            !wasEmpty && isEmpty
        }
        .sensoryFeedback(.selection, trigger: trainingDayTick)
        .sensoryFeedback(.selection, trigger: noteReadTick)
    }

    private var weeklyPlan: some View {
        VStack(alignment: .leading, spacing: 16) {
            ChickenPageHeader {
                Text(homeTitle)
                    .font(Theme.Text.title2)
                    .foregroundStyle(Theme.fgPrimary)
                    .contentTransition(.opacity)
                    .animation(.easeInOut(duration: 0.2), value: homeTitle)
            } trailing: {
                headerTrailing
            }

            weekDays
        }
    }

    private var weekDays: some View {
        let index = CGFloat(homeDays.firstIndex { $0.id == selectedDay } ?? 0)
        return GeometryReader { geo in
            HStack(spacing: 9) {
                ForEach(homeDays) { day in
                    Group {
                        if day.id == selectedDay, let copy = dayCopy(for: day) {
                            labeledDayChip(day, copy: copy)
                        } else {
                            dayDot(day)
                                .frame(width: 36, height: 56)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedDay = day.id
                            dayStripRest = 0
                            dayStripDrag = 0
                            cardDrag = 0
                        }
                    }
                    .accessibilityLabel(day.id == selectedDay ? "\(day.label) \(day.dayNumber), \(dayCopy(for: day) ?? "")" : "\(day.label) \(day.dayNumber)")
                    .accessibilityAddTraits(day.id == selectedDay ? .isSelected : [])
                    .accessibilityAddTraits(.isButton)
                }
            }
            .padding(.trailing, geo.size.width)
            .offset(x: 16 - index * 45 + dayStripRest + dayStripDrag)
            .animation(.easeInOut(duration: 0.2), value: selectedDay)
            .gesture(dayStripGesture)
        }
        .frame(height: 56)
        .clipped()
    }

    private var dayStripGesture: some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { value in
                dayStripDrag = value.translation.width
            }
            .onEnded { value in
                dayStripRest += value.translation.width
                dayStripDrag = 0
            }
    }

    private func dayCopy(for day: HomeDay) -> String? {
        if day.isToday { return "Let’s worko-ko!" }
        if day.isPast && trainingDays.contains(day.label) { return "Already done" }
        if isFutureTraining(day) { return "Future trainings" }
        return "Free day"
    }

    private func labeledDayChip(_ day: HomeDay, copy: String) -> some View {
        WeekDayChip(
            label: day.label,
            copy: copy,
            selected: day.id == selectedDay,
            isToday: day.isToday,
            isFree: !isTrainingPage(day),
            isFuture: isFutureTraining(day)
        )
    }

    private var todayDay: String { Self.currentWeekdayId() }

    /// Seven days before today, today, and the six days after.
    private var homeDays: [HomeDay] {
        let calendar = FitnessLog.calendar
        let today = calendar.startOfDay(for: Date())
        return (-7...6).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: today) else { return nil }
            return HomeDay(
                id: FitnessLog.key(for: date),
                label: FitnessLog.weekdayId(for: date),
                dayNumber: "\(calendar.component(.day, from: date))",
                isToday: offset == 0,
                isPast: offset < 0
            )
        }
    }

    private var selectedHomeDay: HomeDay? {
        homeDays.first { $0.id == selectedDay }
    }

    private var homeTitle: String {
        guard let day = selectedHomeDay else { return "Today" }
        if day.isToday { return "Today" }
        let calendar = FitnessLog.calendar
        let today = calendar.startOfDay(for: Date())
        guard let date = FitnessLog.date(from: day.id) else { return day.label }
        let offset = calendar.dateComponents([.day], from: today, to: calendar.startOfDay(for: date)).day ?? 0
        switch offset {
        case -1: return "Yesterday"
        case 1: return "Tomorrow"
        default: return "\(weekdayName(day.label)) \(day.dayNumber)"
        }
    }

    private func weekdayName(_ id: String) -> String {
        switch id {
        case "Mo": return "Monday"
        case "Tu": return "Tuesday"
        case "We": return "Wednesday"
        case "Th": return "Thursday"
        case "Fr": return "Friday"
        case "Sa": return "Saturday"
        case "Su": return "Sunday"
        default: return id
        }
    }

    private var nextDayId: String {
        let ids = ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
        guard let index = ids.firstIndex(of: todayDay) else { return "We" }
        return ids[(index + 1) % ids.count]
    }

    private var trainingDays: Set<String> {
        let saved = Set(trainingDaysRaw.split(separator: ",").map(String.init).filter { !$0.isEmpty })
        var days = saved.isEmpty || saved == ["We", "Fr"]
            ? Set(Self.everyOtherTrainingDays(from: todayDay))
            : saved
        days.insert(todayDay)
        return days
    }

    private static func everyOtherTrainingDays(from today: String) -> [String] {
        let ids = ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
        guard let start = ids.firstIndex(of: today) else { return ids }
        return ids.enumerated().compactMap { index, id in
            ((index - start + 7) % 7).isMultiple(of: 2) ? id : nil
        }
    }

    private func seedTrainingDaysIfNeeded() {
        let saved = Set(trainingDaysRaw.split(separator: ",").map(String.init).filter { !$0.isEmpty })
        if saved.isEmpty || saved == ["We", "Fr"] {
            trainingDaysRaw = Self.everyOtherTrainingDays(from: todayDay).joined(separator: ",")
        }
    }

    private func isFutureTraining(_ day: HomeDay) -> Bool {
        !day.isPast && !day.isToday && trainingDays.contains(day.label) && day.label != nextDayId
    }

    private func isTrainingPage(_ day: HomeDay) -> Bool {
        day.isToday || isFutureTraining(day) || (day.isPast && trainingDays.contains(day.label))
    }

    private func toggleTrainingDay(_ id: String) {
        guard id != todayDay else { return }
        var days = trainingDays
        if days.contains(id) {
            days.remove(id)
        } else {
            days.insert(id)
        }
        trainingDaysRaw = ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
            .filter { days.contains($0) }
            .joined(separator: ",")
        trainingDayTick += 1
    }

    private static func currentWeekdayId() -> String {
        FitnessLog.weekdayId(for: Date())
    }

    private static func todayKey() -> String {
        FitnessLog.key(for: Date())
    }

    private func dayDot(_ day: HomeDay) -> some View {
        let color: Color = {
            if day.isToday { return Theme.fgAccent }
            if trainingDays.contains(day.label) { return Theme.fgSecondary }
            return Theme.fgRest
        }()
        return WeekDayDot(label: day.label, date: day.dayNumber, color: color)
    }

    private func dayPager(cardWidth: CGFloat) -> some View {
        GeometryReader { geo in
            let pageWidth = geo.size.width
            let index = homeDays.firstIndex { $0.id == selectedDay } ?? 0
            HStack(spacing: 0) {
                ForEach(homeDays) { day in
                    dayPage(for: day, width: cardWidth)
                        .padding(.horizontal, Theme.Space.gutter)
                        .frame(width: pageWidth)
                        .mask(Rectangle().padding(.vertical, -16))
                }
            }
            .offset(x: -CGFloat(index) * pageWidth + cardDrag)
            .frame(width: pageWidth, height: geo.size.height, alignment: .leading)
            .contentShape(Rectangle())
            .simultaneousGesture(cardSwipeGesture(pageWidth: pageWidth, index: index))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }

    private func cardSwipeGesture(pageWidth: CGFloat, index: Int) -> some Gesture {
        DragGesture(minimumDistance: 18)
            .onChanged { value in
                let dx = value.translation.width
                if abs(dx) > 18 { suppressWorkoutStart = true }
                let atStart = index == 0 && dx > 0
                let atEnd = index == homeDays.count - 1 && dx < 0
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    cardDrag = (atStart || atEnd) ? dx * 0.35 : dx
                }
            }
            .onEnded { value in
                let dx = value.translation.width
                let threshold = pageWidth * 0.18
                var next = index
                if dx <= -threshold { next += 1 }
                else if dx >= threshold { next -= 1 }
                next = min(max(next, 0), homeDays.count - 1)
                withAnimation(.easeInOut(duration: 0.35)) {
                    cardDrag = 0
                    selectedDay = homeDays[next].id
                    dayStripRest = 0
                    dayStripDrag = 0
                }
                if suppressWorkoutStart {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                        suppressWorkoutStart = false
                    }
                }
            }
    }

    private func dayPage(for day: HomeDay, width: CGFloat) -> some View {
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

    private func pageKind(for day: HomeDay) -> DayPageKind {
        if day.isToday {
            return .train(live: true, title: "Abs & Glutes", image: "ChickenAbs")
        }
        if (day.isPast && trainingDays.contains(day.label)) || isFutureTraining(day) {
            let wing = day.label == "Fr"
            return .train(
                live: false,
                title: wing ? "Wing press" : "Abs & Glutes",
                image: wing ? "ChickenWingPress" : "ChickenAbs"
            )
        }
        return .rest(title: "Free day")
    }

    private func workoutCard(width: CGFloat, title: String, live: Bool, image: String) -> some View {
        let wing = title == "Wing press"
        return VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 11) {
                Text(title)
                    .font(Theme.Text.title)
                    .foregroundStyle(Theme.fgPrimary)

                HStack(spacing: 6) {
                    ChickenChip(title: wing ? "18 min" : "20 min", icon: "IconTime")
                    if wing {
                        ChickenChip(title: "Dumbbells", icon: "IconDumbbells")
                    } else {
                        ChickenChip(title: "Dumbbells", icon: "IconDumbbells")
                        ChickenChip(title: "Mat", icon: "IconYogaMat")
                    }
                }
            }
            .padding(.top, 24)
            .padding(.horizontal, 24)

            Group {
                if !wing {
                    ChickenMediaView(media: .video("SequenceAbs"), isPlaying: true)
                        .offset(x: -40, y: 20)
                } else if live {
                    ChickenMediaView(media: .video("SequenceHome"), isPlaying: true)
                } else {
                    Image(image)
                        .resizable()
                        .scaledToFit()
                }
            }
            .padding(.horizontal, 4)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            ChickenPrimaryButton(
                title: live ? "Start" : "Open workout",
                icon: live ? "IconStartArrow" : nil,
                action: { startWorkout() }
            )
            .padding(24)
        }
        .frame(width: width)
        .frame(maxHeight: .infinity)
        .background {
            DuneCardBackground(centerPeach: false)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.xl, style: .continuous))
                .chickenShadow()
        }
    }

    private func restCard(width: CGFloat, title: String) -> some View {
        ZStack(alignment: .bottom) {
            ChickenMediaView(
                media: .video("SequenceFreeDay"),
                isPlaying: true,
                contentAlignment: .bottom
            )
            .scaleEffect(2, anchor: .bottom)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .frame(width: width)
        .frame(maxHeight: .infinity)
        .background {
            DuneCardBackground(showDune: false)
        }
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.xl, style: .continuous))
        .chickenShadow()
        .overlay(alignment: .topLeading) {
            Text(title)
                .font(Theme.Text.title)
                .foregroundStyle(Theme.fgPrimary)
                .padding(.top, 24)
                .padding(.horizontal, 24)
                .accessibilityAddTraits(.isHeader)
        }
    }

    private var pastWeightKg: Double? {
        guard selectedHomeDay?.isPast == true else { return nil }
        return log.weights.last { $0.day == selectedDay }?.kg
    }

    private var weightCard: some View {
        HStack(alignment: .bottom, spacing: 16) {
            if selectedHomeDay?.isToday != false {
                weightFilled(currentWeightKg)
                weightAddButton
            } else if let kg = pastWeightKg {
                weightFilled(kg, showsTrend: false)
            } else {
                weightEmpty
            }
        }
        .frame(minHeight: 55, alignment: .center)
        .padding(24)
        .background(
            Theme.weightSurface,
            in: RoundedRectangle(cornerRadius: Theme.Radius.xl, style: .continuous)
        )
        .chickenShadow()
        .padding(.horizontal, Theme.Space.gutter)
        .animation(.easeInOut(duration: 0.25), value: selectedDay)
    }

    private func weightFilled(_ kg: Double, showsTrend: Bool = true) -> some View {
        HStack(alignment: .bottom, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text("My weight")
                    .font(Theme.Text.callout)
                    .foregroundStyle(Theme.fgSecondary)
                Text(formattedWeight(kg))
                    .font(Theme.Text.title2)
                    .foregroundStyle(Theme.fgPrimary)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: kg)
            }

            if showsTrend, let change = shownWeeklyChange {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 4) {
                        Text(formattedChange(change))
                            .font(Theme.Text.callout)
                            .foregroundStyle(changeColor(change))
                        if displayChange(change) != 0 {
                            Image("IconDeltaDown")
                                .renderingMode(.template)
                                .foregroundStyle(changeColor(change))
                                .frame(width: 6, height: 6.4)
                                .rotationEffect(.degrees(change > 0 ? 180 : 0))
                        }
                    }
                    Text("vs last week")
                        .font(Theme.Text.callout)
                        .foregroundStyle(Theme.fgSecondary)
                }
            }

            if showsTrend {
                WeightSparkline(values: sparklineValues)
                    .id(sparklineValues)
                    .foregroundStyle(changeColor(shownWeeklyChange ?? 0))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
            }
        }
    }

    private var weightEmpty: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("My weight")
                .font(Theme.Text.callout)
                .foregroundStyle(Theme.fgSecondary)
            Text(selectedHomeDay?.isPast == true ? "No weigh-in that day." : "We’ll see… in the future.")
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .font(Theme.Text.title2)
                .foregroundStyle(Theme.fgSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var weightAddButton: some View {
        ChickenPlusButton { showingWeightSheet = true }
    }

    private func workoutsContent(cardWidth: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            ChickenPageHeader {
                Text("Extra workouts")
                    .font(Theme.Text.title2)
                    .foregroundStyle(Theme.fgPrimary)
            } trailing: {
                headerTrailing
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(ExtraWorkout.all) { item in
                        extraWorkoutCard(item, width: cardWidth)
                            .padding(.horizontal, Theme.Space.gutter)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func extraWorkoutCard(_ item: ExtraWorkout, width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                Text([item.line1, item.line2].filter { !$0.isEmpty }.joined(separator: " "))
                    .font(Theme.Text.streak)
                    .foregroundStyle(Theme.fgPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ChickenChip(title: item.duration, icon: "IconTime")
                        ForEach(item.equipment) { gear in
                            ChickenChip(title: gear.title, icon: gear.icon)
                        }
                    }
                }
            }
            .padding(.top, 24)
            .padding(.horizontal, 24)

            Group {
                if let video = item.video {
                    ChickenMediaView(media: .video(video), isPlaying: true)
                        .frame(width: width * 0.8)
                        .scaleEffect(video == "Sequence01" ? ChickenMedia.video("Sequence01").displayScale : 1)
                        .offset(x: video == "Sequence01" ? ChickenMedia.video("Sequence01").nudgeX : 0)
                } else {
                    Image(item.image)
                        .resizable()
                        .scaledToFit()
                        .padding(.horizontal, 36)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            ChickenPrimaryButton(title: "Open workout", shadowed: false) {
                startWorkout(move: item.move)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .frame(width: width)
        .frame(maxHeight: .infinity)
        .background {
            DuneCardBackground(
                referenceHeight: 702,
                duneY: 420,
                duneHeight: 315,
                centerPeach: false
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.xl, style: .continuous))
    }

    private var statisticsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            ChickenPageHeader {
                Text("Statistics")
                    .font(Theme.Text.title2)
                    .foregroundStyle(Theme.fgPrimary)
            } trailing: {
                headerTrailing
            }

            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 8) {
                        StatsTrendCard(
                            title: "Calories burned",
                            value: "12,480",
                            unit: "kcal",
                            delta: "+1840 kcal",
                            values: FitnessStats.calorieTrend,
                            startLabel: "Jul 12"
                        )
                        StatsTrendCard(
                            title: "Weight",
                            value: String(format: "%.1f", displayWeight(currentWeightKg)),
                            unit: weightUnit,
                            delta: formattedChange(usesSampleWeight ? currentWeightKg - FitnessStats.startWeightKg : (log.weeklyWeightChange ?? 0)),
                            deltaColor: changeColor(usesSampleWeight ? currentWeightKg - FitnessStats.startWeightKg : (log.weeklyWeightChange ?? 0)),
                            chartColor: changeColor(usesSampleWeight ? currentWeightKg - FitnessStats.startWeightKg : (log.weeklyWeightChange ?? 0)),
                            values: usesSampleWeight ? FitnessStats.weightTrend(endingAt: currentWeightKg) : recentWeightValues,
                            startLabel: usesSampleWeight ? "Jul 12" : recentWeightStartLabel
                        )
                        .id(currentWeightKg)
                        statsCalendarCard
                        Image("StatsProgress")
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, -Theme.Space.gutter)
                            .padding(.bottom, -20)
                            .id("statsStreak")
                            .accessibilityLabel("Progress looks good on you!")
                    }
                    .padding(.horizontal, Theme.Space.gutter)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onAppear { jumpToStatsStreak(proxy) }
                .onChange(of: scrollToStatsStreak) { _, go in
                    if go { jumpToStatsStreak(proxy) }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var statsCalendarCard: some View {
        VStack(spacing: 24) {
            ForEach(FitnessStats.recentMonths(count: 2, log: log)) { month in
                statsMonthBlock(month)
            }
        }
        .padding(24)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.xl, style: .continuous))
    }

    private func statsMonthBlock(_ month: FitnessMonth) -> some View {
        VStack(spacing: 12) {
            Text(month.name)
                .font(Theme.Text.row)
                .foregroundStyle(Theme.fgPrimary)
                .frame(maxWidth: .infinity)

            HStack {
                ForEach(Array(FitnessStats.weekdayLetters.enumerated()), id: \.offset) { _, day in
                    Text(day)
                        .font(Theme.Text.caption)
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

    private func statsDayCell(_ cell: FitnessDay) -> some View {
        ZStack {
            Circle()
                .fill(
                    cell.day == nil
                        ? Color.clear
                        : (cell.workedOut
                            ? Theme.calToday
                            : Theme.bgSoft)
                )
            if let day = cell.day {
                if cell.workedOut {
                    Image("CalendarChicken")
                        .resizable()
                        .scaledToFill()
                        .clipShape(Circle())
                        .accessibilityHidden(true)
                } else {
                    Text("\(day)")
                        .font(Theme.Text.caption)
                        .foregroundStyle(Theme.fgSecondary)
                }
            }
        }
        .frame(height: Theme.Space.tabHeight)
        .clipShape(Circle())
        .overlay {
            if cell.isToday && !cell.workedOut {
                Circle().stroke(Theme.todayRing, lineWidth: 1.5)
            }
        }
        .accessibilityLabel(cell.accessibilityLabel)
    }

    private var notificationsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            ChickenScreenHeader(title: "Notifications") {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showingNotifications = false
                }
            } trailing: {
                if !unreadNoteIDs.isEmpty {
                    Button("Read all") {
                        unreadNoteIDs.removeAll()
                    }
                    .font(Theme.Text.callout)
                    .foregroundStyle(Theme.fgSecondary)
                    .buttonStyle(.plain)
                }
            }

            if notes.isEmpty {
                VStack(spacing: 8) {
                    Image("IconNotification")
                        .frame(width: 24, height: 24)
                        .frame(width: 64, height: 64)
                        .background(Theme.bgMuted, in: Circle())
                        .padding(.bottom, 8)
                        .accessibilityHidden(true)
                    Text("No new notifications")
                        .font(Theme.Text.title3)
                        .foregroundStyle(Theme.fgPrimary)
                    Text("Not even one egg in the nest.")
                        .font(Theme.Text.callout)
                        .foregroundStyle(Theme.fgSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        ForEach(notes) { note in
                            noteRow(note)
                        }
                    }
                    .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.xl, style: .continuous))
                    .padding(.horizontal, Theme.Space.gutter)
                    .padding(.bottom, 32)
                }
            }
        }
        .padding(.top, 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func noteSection(title: String, items: [AppNote]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(Theme.Text.callout)
                .foregroundStyle(Theme.fgSecondary)
                .padding(.horizontal, 8)
            VStack(spacing: 0) {
                ForEach(items) { note in
                    noteRow(note)
                }
            }
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.xl, style: .continuous))
        }
    }

    private func noteRow(_ note: AppNote) -> some View {
        let unread = unreadNoteIDs.contains(note.id)
        return HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(note.title)
                    .font(Theme.Text.row)
                    .foregroundStyle(Theme.fgPrimary)
                Text(note.body)
                    .font(Theme.Text.callout)
                    .foregroundStyle(Theme.fgSecondary)
                    .multilineTextAlignment(.leading)
                Text(note.time)
                    .font(Theme.Text.callout)
                    .foregroundStyle(Theme.noteTime)
                if note.startsWorkout {
                    Button("Continue") {
                        unreadNoteIDs.remove(note.id)
                        startWorkout()
                    }
                    .font(Theme.Text.callout)
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
            let wasUnread = unreadNoteIDs.contains(note.id)
            unreadNoteIDs.remove(note.id)
            if wasUnread && !unreadNoteIDs.isEmpty {
                noteReadTick += 1
            }
        }
    }

    private var settingsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            ChickenScreenHeader(title: "Settings") {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showingSettings = false
                }
            }

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    SettingsGroup {
                        SettingsValueRow(
                            title: "Notifications",
                            value: notes.count > 0 ? "\(notes.count)" : nil
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showingSettings = false
                                showingNotifications = true
                            }
                        }
                        .accessibilityLabel(
                            notes.isEmpty ? "Notifications" : "Notifications, \(notes.count)"
                        )
                    }

                    SettingsGroup {
                        SettingsToggleRow(title: "Sounds", isOn: Bindable(session).soundsEnabled)
                    }

                    SettingsGroup {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Workout days")
                                .font(Theme.Text.row)
                                .foregroundStyle(Theme.fgPrimary)
                            ChickenDayChipRow(
                                items: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"],
                                title: { $0 },
                                isSelected: { trainingDays.contains($0) },
                                action: { toggleTrainingDay($0) }
                            )
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                    }

                    SettingsGroup {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Weight")
                                .font(Theme.Text.row)
                                .foregroundStyle(Theme.fgPrimary)
                            ChickenDayChipRow(
                                items: ["kg", "lb"],
                                title: { $0 },
                                isSelected: { $0 == weightUnit },
                                action: { weightUnit = $0 }
                            )
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                    }

                    SettingsGroup {
                        SettingsValueRow(
                            title: "Version",
                            value: "beta"
                        )
                    }
                }
                .padding(.horizontal, Theme.Space.gutter)
                .padding(.bottom, 16)
            }

            Text("made by Lisa Pasichnyk")
                .font(Theme.Text.callout)
                .foregroundStyle(Theme.fgSecondary)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 8)
        }
        .padding(.top, 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var headerTrailing: some View {
        HStack(spacing: 10) {
            streakButton
            profileButton
        }
    }

    private var streakButton: some View {
        Button {
            selectedTab = .statistics
            scrollToStatsStreak = true
        } label: {
            HStack(spacing: 4) {
                Image("IconFire")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                    .accessibilityHidden(true)
                Text("\(streakCount)")
                    .font(Theme.Text.title3)
                    .foregroundStyle(Theme.fgPrimary)
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }
            .padding(.leading, 12)
            .padding(.trailing, 20)
            .frame(height: 40)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous))
            .chickenShadow()
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(streakCount) \(streakLabel)")
        .accessibilityHint("Opens statistics")
    }

    private var profileButton: some View {
        ChickenAvatarButton {
            withAnimation(.easeInOut(duration: 0.2)) {
                showingNotifications = false
                showingSettings = true
            }
        }
    }

    private func displayChange(_ kg: Double) -> Double {
        (displayWeight(kg) * 10).rounded() / 10
    }

    private func formattedChange(_ kg: Double) -> String {
        let change = displayChange(kg)
        let sign = change > 0 ? "+" : change < 0 ? "−" : ""
        return "\(sign)\(String(format: "%.1f", abs(change))) \(weightUnit)"
    }

    private func changeColor(_ kg: Double) -> Color {
        displayChange(kg) > 0 ? Theme.fgAccent : Theme.fgPositive
    }

    private var sparklineValues: [Double] {
        if !usesSampleWeight { return log.weights.suffix(6).map(\.kg) }
        return Array((FitnessStats.baselineTrend.dropLast() + [currentWeightKg]).suffix(6))
    }

    private var recentWeightValues: [Double?] {
        let recent = log.recentWeights().map { Optional(displayWeight($0.kg)) }
        return recent.isEmpty ? [nil] : recent
    }

    private var recentWeightStartLabel: String {
        guard let first = log.recentWeights().first,
              let date = FitnessLog.date(from: first.day) else { return FitnessStats.chartEndLabel }
        return FitnessStats.shortDate(date)
    }

    private func displayWeight(_ kg: Double) -> Double {
        weightUnit == "lb" ? kg * 2.2046226218 : kg
    }

    private func formattedWeight(_ kg: Double) -> String {
        "\(String(format: "%.1f", displayWeight(kg))) \(weightUnit)"
    }

    private func jumpToStatsStreak(_ proxy: ScrollViewProxy) {
        guard scrollToStatsStreak else { return }
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 0.35)) {
                proxy.scrollTo("statsStreak", anchor: .top)
            }
            scrollToStatsStreak = false
        }
    }

    private func startWorkout(move: Move? = nil) {
        guard !suppressWorkoutStart else { return }
        session.beginCountdown(move: move)
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
    static let weekdayLetters = ["M", "T", "W", "T", "F", "S", "S"]
    static let monthNames = [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December",
    ]
    static let calorieTrend: [Double] = [980, 1120, 1340, 1510, 1680, 1840, 2040, 2200]
    static let baselineWeightKg = 62.4
    static let baselineLastWeekKg = 63.2
    static let startWeightKg = 65.6
    static let baselineTrend: [Double] = [65.6, 65.4, 65.1, 64.8, 64.5, 64.1, 63.8, 63.3, 62.4]

    static func weightTrend(endingAt current: Double) -> [Double?] {
        [65.6, 65.4, 65.1, 64.8, 64.5, 64.1, 63.8, 63.3, current, nil, nil, nil]
    }
    /// Days of every month that already show a finished workout.
    static let workoutDays: Set<Int> = [1, 3, 5, 8, 10, 12, 15, 17, 19, 22, 24, 26, 28, 29, 30]
    private static let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2
        return cal
    }()

    static func recentMonths(count: Int, log: FitnessLog) -> [FitnessMonth] {
        let today = calendar.startOfDay(for: Date())
        return (0..<count).compactMap { offset in
            guard let date = calendar.date(byAdding: .month, value: -offset, to: today) else { return nil }
            let year = calendar.component(.year, from: date)
            let month = calendar.component(.month, from: date)
            return FitnessMonth(
                id: year * 100 + month,
                name: monthNames[month - 1],
                cells: cells(year: year, month: month, log: log)
            )
        }
    }

    /// Same marks the statistics calendar draws: today, the sample days, and logged workouts.
    static func markedWorkout(on date: Date, log: FitnessLog) -> Bool {
        let day = calendar.startOfDay(for: date)
        let today = calendar.startOfDay(for: Date())
        if day > today { return false }
        let parts = calendar.dateComponents([.year, .month, .day], from: day)
        let todayParts = calendar.dateComponents([.year, .month, .day], from: today)
        let dayNumber = parts.day ?? 0
        let isToday = parts.year == todayParts.year && parts.month == todayParts.month && parts.day == todayParts.day
        return isToday
            || workoutDays.contains(dayNumber)
            || log.didWorkout(year: parts.year ?? 0, month: parts.month ?? 0, day: dayNumber)
    }

    /// Consecutive calendar marks, walking back from today. A missed training day ends it.
    static func streak(trainingDays: Set<String>, log: FitnessLog) -> Int {
        var count = 0
        var day = calendar.startOfDay(for: Date())
        var isToday = true
        for _ in 0..<800 {
            if markedWorkout(on: day, log: log) {
                count += 1
            } else if !isToday && trainingDays.contains(FitnessLog.weekdayId(for: day)) {
                break
            }
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
            isToday = false
        }
        return count
    }

    static func cells(year: Int, month: Int, log: FitnessLog) -> [FitnessDay] {
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
            let isToday = year == todayParts.year && month == todayParts.month && day == todayParts.day
            return FitnessDay(
                id: year * 10000 + month * 100 + day,
                day: day,
                workedOut: date.map { markedWorkout(on: $0, log: log) } ?? false,
                isToday: isToday,
                monthName: monthName
            )
        }
        return result
    }

    static var chartEndLabel: String { shortDate(Date()) }

    static func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    static func axisLabels(for values: [Double?]) -> [String] {
        let known = values.compactMap { $0 }
        guard let minV = known.min(), let maxV = known.max() else { return [] }
        if maxV > 100 {
            let top = (maxV / 200).rounded(.up) * 200
            let step: Double = 600
            return [top, top - step, top - 2 * step].map { formatGrouped($0) }
        }
        let top = maxV.rounded(.up)
        let bot = minV.rounded(.down)
        let mid = (top + bot) / 2
        return [top, mid, bot].map { String(format: "%.1f", $0) }
    }

    private static func formatGrouped(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: value)) ?? "\(Int(value))"
    }
}

private struct StatsTrendCard: View {
    let title: String
    let value: String
    let unit: String
    let delta: String
    let deltaColor: Color
    let chartColor: Color
    let values: [Double?]
    let startLabel: String

    init(title: String, value: String, unit: String, delta: String, deltaColor: Color = Theme.fgPositive, chartColor: Color = Theme.fgAccent, values: [Double], startLabel: String) {
        self.init(title: title, value: value, unit: unit, delta: delta, deltaColor: deltaColor, chartColor: chartColor, values: values.map { Optional($0) }, startLabel: startLabel)
    }

    init(title: String, value: String, unit: String, delta: String, deltaColor: Color = Theme.fgPositive, chartColor: Color = Theme.fgAccent, values: [Double?], startLabel: String) {
        self.title = title
        self.value = value
        self.unit = unit
        self.delta = delta
        self.deltaColor = deltaColor
        self.chartColor = chartColor
        self.values = values
        self.startLabel = startLabel
    }

    private var ticks: [String] { FitnessStats.axisLabels(for: values) }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .bottom, spacing: 4) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(Theme.Text.headline)
                        .foregroundStyle(Theme.fgPrimary)
                    Color.clear.frame(height: 2)
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(value)
                            .font(Theme.Text.stat)
                            .foregroundStyle(Theme.fgPrimary)
                            .minimumScaleFactor(0.7)
                            .lineLimit(1)
                        Text(unit)
                            .font(Theme.Text.body)
                            .foregroundStyle(Theme.fgSecondary)
                    }
                }
                Spacer(minLength: 4)
                VStack(alignment: .trailing, spacing: 2) {
                    if !delta.isEmpty {
                        Text(delta)
                            .font(Theme.Text.body)
                            .foregroundStyle(deltaColor)
                        Text("this week")
                            .font(Theme.Text.body)
                            .foregroundStyle(Theme.fgSecondary)
                    }
                }
                .padding(.bottom, 4)
            }

            HStack(alignment: .center, spacing: 6) {
                VStack(spacing: 8) {
                    WeightTrendChart(values: values, line: chartColor)
                        .frame(height: 128)
                        .clipped()
                    HStack {
                        Text(startLabel)
                        Spacer()
                        Text(FitnessStats.chartEndLabel)
                    }
                    .font(Theme.Text.caption)
                    .foregroundStyle(Theme.fgSecondary)
                }
                VStack {
                    ForEach(Array(ticks.enumerated()), id: \.offset) { index, label in
                        Text(label)
                            .font(Theme.Text.caption)
                            .foregroundStyle(Theme.fgSecondary)
                        if index < ticks.count - 1 {
                            Spacer(minLength: 0)
                        }
                    }
                }
                .frame(height: 128)
            }
        }
        .padding(.top, 20)
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.xl, style: .continuous))
    }
}

private struct WeightSparkline: View {
    let values: [Double]

    var body: some View {
        GeometryReader { geo in
            let scaled = points(in: geo.size)

            Path { path in
                guard let first = scaled.first else { return }
                path.move(to: first)
                scaled.dropFirst().forEach { path.addLine(to: $0) }
            }
            .stroke(
                .foreground,
                style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round)
            )

            if let last = scaled.last {
                Circle()
                    .fill(.foreground)
                    .frame(width: 8, height: 8)
                    .position(last)
            }
        }
        .accessibilityHidden(true)
    }

    private func points(in size: CGSize) -> [CGPoint] {
        guard values.count > 1, let minV = values.min(), let maxV = values.max() else { return [] }
        let span = max(maxV - minV, 0.5)
        let mid = (maxV + minV) / 2
        let inset: CGFloat = 4
        let plotW = size.width - 2 * inset
        let plotH = size.height * 0.5
        return values.enumerated().map { index, value in
            CGPoint(
                x: inset + plotW * CGFloat(index) / CGFloat(values.count - 1),
                y: size.height / 2 - plotH * CGFloat((value - mid) / span)
            )
        }
    }
}

private struct WeightTrendChart: View {
    let values: [Double?]
    let line: Color

    init(values: [Double], line: Color = Theme.fgAccent) {
        self.values = values.map { Optional($0) }
        self.line = line
    }

    init(values: [Double?], line: Color = Theme.fgAccent) {
        self.values = values
        self.line = line
    }

    var body: some View {
        Canvas { context, size in
            let known = values.compactMap { $0 }
            let rawMin = known.min() ?? 0
            let rawMax = known.max() ?? 1
            let pad = max((rawMax - rawMin) * 0.08, 0.2)
            let minV = rawMin - pad
            let maxV = rawMax + pad
            let span = max(maxV - minV, 0.1)
            let slots = max(known.count - 1, 1)
            let inset: CGFloat = 4
            let plotW = size.width - 2 * inset
            let plotH = size.height - 2 * inset
            let weak = Theme.gridWeak
            let strong = Theme.gridStrong
            let cell: CGFloat = 8
            var x: CGFloat = 0
            var col = 0
            while x <= size.width {
                var line = Path()
                line.move(to: CGPoint(x: x, y: 0))
                line.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(line, with: .color(col % 4 == 0 ? strong : weak), lineWidth: col % 4 == 0 ? 2 : 1)
                x += cell
                col += 1
            }
            var y: CGFloat = 0
            var row = 0
            while y <= size.height {
                var line = Path()
                line.move(to: CGPoint(x: 0, y: y))
                line.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(line, with: .color(row % 4 == 0 ? strong : weak), lineWidth: row % 4 == 0 ? 2 : 1)
                y += cell
                row += 1
            }

            let points: [CGPoint] = known.enumerated().map { index, value in
                CGPoint(
                    x: inset + plotW * CGFloat(index) / CGFloat(slots),
                    y: inset + plotH * (1 - CGFloat((value - minV) / span))
                )
            }
            guard let first = points.first, let last = points.last else { return }

            var fill = Path()
            fill.move(to: CGPoint(x: first.x, y: size.height))
            fill.addLine(to: first)
            points.dropFirst().forEach { fill.addLine(to: $0) }
            fill.addLine(to: CGPoint(x: last.x, y: size.height))
            fill.closeSubpath()
            context.fill(fill, with: .color(line.opacity(0.16)))

            var stroke = Path()
            stroke.move(to: first)
            points.dropFirst().forEach { stroke.addLine(to: $0) }
            context.stroke(stroke, with: .color(line), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))

            let dot = Path(ellipseIn: CGRect(x: last.x - 4.5, y: last.y - 4.5, width: 9, height: 9))
            context.fill(dot, with: .color(line))
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
    var video: String? = nil
    let duration: String
    let equipment: [ExtraGear]
    let move: Move

    static let all: [ExtraWorkout] = [
        ExtraWorkout(
            id: "press",
            line1: "Dumbbell",
            line2: "shoulder press",
            image: "ChickenShoulderPress",
            video: "Sequence04",
            duration: "4 min",
            equipment: [
                ExtraGear(id: "db", title: "Dumbbells", icon: "IconDumbbells"),
            ],
            move: Move(id: 2, name: "Dumbbell shoulder press", duration: 40, repInterval: 2, media: .video("Sequence04"))
        ),
        ExtraWorkout(
            id: "abs",
            line1: "Abs",
            line2: "",
            image: "ChickenAbs",
            video: "Sequence01",
            duration: "20 min",
            equipment: [
                ExtraGear(id: "db", title: "Dumbbells", icon: "IconDumbbells"),
                ExtraGear(id: "mat", title: "Mat", icon: "IconYogaMat"),
            ],
            move: WorkoutCatalog.moves[0]
        ),
    ]
}

private enum DayPageKind {
    case train(live: Bool, title: String, image: String)
    case rest(title: String)
}

private struct HomeDay: Identifiable {
    /// Local calendar day, `yyyy-MM-dd`.
    let id: String
    let label: String
    let dayNumber: String
    let isToday: Bool
    let isPast: Bool
}

#Preview {
    HomeView(session: WorkoutSession(), log: FitnessLog())
}
