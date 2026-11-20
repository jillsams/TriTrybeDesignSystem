import SwiftUI
import Observation

// Tri Trybe — playful beginner-first visual prototype.
// Add this file to an iOS 17+ SwiftUI project, then use TriTrybeRootView() in WindowGroup.
// Sample training data is deliberately separate from the website's planning engine.

enum TriStyle {
    static let navy = Color(red: 0.035, green: 0.075, blue: 0.19)
    static let blue = Color(red: 0.02, green: 0.55, blue: 0.96)
    static let green = Color(red: 0.22, green: 0.73, blue: 0.15)
    static let red = Color(red: 0.98, green: 0.23, blue: 0.23)
    static let canvas = Color(red: 0.97, green: 0.98, blue: 1)
    static let muted = Color(red: 0.40, green: 0.46, blue: 0.55)
    static func title(_ size: CGFloat = 28) -> Font { .system(size: size, weight: .heavy, design: .rounded) }
    static func body(_ size: CGFloat = 15) -> Font { .system(size: size, weight: .medium, design: .rounded) }
}

enum Sport: String, CaseIterable, Identifiable, Codable {
    case swim = "Swim", bike = "Bike", run = "Run"
    var id: String { rawValue }
    var tint: Color { switch self { case .swim: TriStyle.blue; case .bike: TriStyle.green; case .run: TriStyle.red } }
    var symbol: String { switch self { case .swim: "figure.pool.swim"; case .bike: "bicycle"; case .run: "figure.run" } }
}

struct Workout: Identifiable {
    let id = UUID()
    let day: String
    let sport: Sport
    let name: String
    let minutes: Int
    let detail: String
    var complete: Bool = false
}

struct TriCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
            .padding(17)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(TriStyle.navy.opacity(0.055)))
            .shadow(color: TriStyle.navy.opacity(0.065), radius: 10, y: 4)
    }
}

struct TriBrand: View {
    var body: some View {
        HStack(spacing: 11) {
            HStack(spacing: 4) {
                ForEach([TriStyle.blue, TriStyle.green, TriStyle.red].indices, id: \.self) { i in
                    Capsule().fill([TriStyle.blue, TriStyle.green, TriStyle.red][i])
                        .frame(width: 10, height: 29).rotationEffect(.degrees(32))
                }
            }.frame(width: 40)
            Text("Tri Trybe")
                // SF Rounded fallback until the licensed Allo font is bundled.
                .font(TriStyle.title(29))
                .foregroundStyle(TriStyle.navy)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Tri Trybe")
    }
}

/// A reusable, asset-free hero while the final athlete artwork is prepared.
struct TriWelcomeBanner: View {
    @Environment(\.horizontalSizeClass) private var sizeClass

    private var bannerName: String {
        sizeClass == .compact ? "TriTrybeBannerPhone" : "TriTrybeBanner"
    }

    var body: some View {
        Group {
            if UIImage(named: bannerName) != nil {
                Image(bannerName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                    .accessibilityLabel("Cartoon swimmer, cyclist and runner. Your journey, your pace. Celebrate every workout.")
            } else {
                VStack(alignment: .leading, spacing: 9) {
                    Text("SWIM  ·  BIKE  ·  RUN")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                    Text("Your journey.\\nYour pace.")
                        .font(TriStyle.title(29))
                    Text("Celebrate every workout.")
                        .font(TriStyle.body(13))
                }
                .foregroundStyle(.white)
                .padding(23)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(TriStyle.blue.gradient, in: RoundedRectangle(cornerRadius: 26))
            }
        }
    }
}

struct SportIcon: View {
    let sport: Sport
    var body: some View {
        Image(systemName: sport.symbol)
            .font(.system(size: 22, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 49, height: 49)
            .background(sport.tint.gradient, in: RoundedRectangle(cornerRadius: 15))
            .accessibilityHidden(true)
    }
}

struct WorkoutRow: View {
    let workout: Workout
    var body: some View {
        HStack(spacing: 12) {
            SportIcon(sport: workout.sport)
            VStack(alignment: .leading, spacing: 3) {
                Text("\(workout.sport.rawValue) – \(workout.name)")
                    .font(TriStyle.body(16).weight(.bold)).foregroundStyle(TriStyle.navy)
                Text("\(workout.minutes) min · \(workout.detail)")
                    .font(.subheadline).foregroundStyle(TriStyle.muted)
            }
            Spacer(minLength: 3)
            Image(systemName: workout.complete ? "checkmark.circle.fill" : "chevron.right")
                .foregroundStyle(workout.complete ? TriStyle.green : TriStyle.muted)
                .font(.title3)
        }
        .padding(10)
        .background(workout.sport.tint.opacity(0.09), in: RoundedRectangle(cornerRadius: 17))
        .accessibilityElement(children: .combine)
    }
}

struct SavedRace: Codable {
    var discipline: String
    var distance: String
    var date: Date
    var trainingDays: [Int]
    var athlete: String

    var title: String { "\(distance) \(discipline)" }
}

@MainActor @Observable final class TriDemoStore {
    var workouts: [Workout] = [
        .init(day: "Mon", sport: .swim, name: "Easy Swim", minutes: 30, detail: "Comfortable pace", complete: true),
        .init(day: "Tue", sport: .bike, name: "Steady Ride", minutes: 45, detail: "Easy effort", complete: true),
        .init(day: "Thu", sport: .run, name: "Run & Walk", minutes: 25, detail: "Take your time"),
        .init(day: "Sat", sport: .bike, name: "Weekend Ride", minutes: 60, detail: "Enjoy the ride"),
        .init(day: "Sun", sport: .swim, name: "Swim Skills", minutes: 25, detail: "Build confidence")
    ]
    var race: SavedRace? = nil {
        didSet { persistRace() }
    }

    init() {
        if let data = UserDefaults.standard.data(forKey: "triTrybeRace"),
           let saved = try? JSONDecoder().decode(SavedRace.self, from: data) {
            race = saved
        }
    }

    private func persistRace() {
        if let race, let data = try? JSONEncoder().encode(race) {
            UserDefaults.standard.set(data, forKey: "triTrybeRace")
        } else {
            UserDefaults.standard.removeObject(forKey: "triTrybeRace")
        }
    }
    var showCelebration = false
    var lastCelebrated: Sport = .swim
    func toggle(_ id: UUID) {
        guard let i = workouts.firstIndex(where: { $0.id == id }) else { return }
        let firstOfSport = !workouts.contains { $0.sport == workouts[i].sport && $0.complete }
        workouts[i].complete.toggle()
        if workouts[i].complete && firstOfSport {
            lastCelebrated = workouts[i].sport
            showCelebration = true
        }
    }
    var completed: Int { workouts.filter(\.complete).count }
}

struct TriTrybeRootView: View {
    @State private var store = TriDemoStore()
    @State private var selectedTab = 0

    var body: some View {
        Group {
            if store.race == nil {
                NavigationStack {
                    TriWelcomeView(startPlanning: {
                        selectedTab = 3
                    })
                }
                // The setup tab is presented in the same root to avoid losing its state.
                .fullScreenCover(isPresented: Binding(
                    get: { selectedTab == 3 },
                    set: { if !$0 { selectedTab = 0 } }
                )) {
                    NavigationStack {
                        TriRaceSetupView(store: store) {
                            selectedTab = 0
                        }
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                Button("Close") { selectedTab = 0 }
                            }
                        }
                    }
                }
            } else {
                TabView(selection: $selectedTab) {
                    NavigationStack { TriHomeView(store: store) }
                        .tabItem { Label("Home", systemImage: "house.fill") }.tag(0)
                    NavigationStack { TriPlanView(store: store) }
                        .tabItem { Label("Plan", systemImage: "calendar") }.tag(1)
                    NavigationStack { TriProgressView(store: store) }
                        .tabItem { Label("Progress", systemImage: "chart.bar.fill") }.tag(2)
                    NavigationStack { TriRaceSetupView(store: store) { selectedTab = 0 } }
                        .tabItem { Label("Race", systemImage: "flag.checkered") }.tag(3)
                }
                .tint(TriStyle.blue)
            }
        }
        .alert("Your first \(store.lastCelebrated.rawValue.lowercased())! 🎉", isPresented: $store.showCelebration) {
            Button("Keep going!") { }
        } message: {
            Text("You showed up and gave it a go. That's worth celebrating!")
        }
    }
}

struct TriWelcomeView: View {
    let startPlanning: () -> Void
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                Group {
                    if sizeClass == .regular && geometry.size.width >= 700 {
                        iPadWelcome(availableWidth: min(geometry.size.width - 48, 1050))
                    } else {
                        iPhoneWelcome
                    }
                }
                .frame(maxWidth: 1050)
                .frame(maxWidth: .infinity)
                .frame(minHeight: geometry.size.height, alignment: .center)
                .padding(.horizontal, 24)
            }
            .background(TriStyle.canvas)
        }
    }

    private var iPhoneWelcome: some View {
        VStack(spacing: 22) {
            TriBrand()
                .frame(maxWidth: .infinity, alignment: .leading)
            TriWelcomeBanner()
            Text("Welcome to Tri Trybe!")
                .font(TriStyle.title(29))
                .foregroundStyle(TriStyle.navy)
                .multilineTextAlignment(.center)
            Text("Plan, train and celebrate every step of your triathlon journey.")
                .font(TriStyle.body(17))
                .foregroundStyle(TriStyle.muted)
                .multilineTextAlignment(.center)
            planButton
        }
        .frame(maxWidth: 650)
        .padding(.vertical, 24)
    }

    private func iPadWelcome(availableWidth: CGFloat) -> some View {
        let gap: CGFloat = 32
        let leftWidth = (availableWidth - gap) * 0.52
        let rightWidth = (availableWidth - gap) * 0.48

        return VStack(alignment: .leading, spacing: 28) {
            TriBrand()
            HStack(alignment: .center, spacing: gap) {
                Image("TriTrybeBanner")
                    .resizable()
                    .scaledToFit()
                    .frame(width: leftWidth)
                    .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                    .accessibilityLabel("Cartoon swimmer, cyclist and runner")

                VStack(alignment: .leading, spacing: 19) {
                    Text("WELCOME TO TRI TRYBE")
                        .font(.caption.weight(.heavy))
                        .tracking(2)
                        .foregroundStyle(TriStyle.blue)
                    Text("Your journey. Your pace.")
                        .font(TriStyle.title(32))
                        .foregroundStyle(TriStyle.navy)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Create a training plan that fits your race, your experience and your life.")
                        .font(TriStyle.body(17))
                        .foregroundStyle(TriStyle.muted)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(alignment: .leading, spacing: 15) {
                        benefit("Plan for your race", icon: "calendar", tint: TriStyle.blue)
                        benefit("Train at your pace", icon: "figure.run", tint: TriStyle.green)
                        benefit("Celebrate your progress", icon: "trophy", tint: TriStyle.red)
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.white, in: RoundedRectangle(cornerRadius: 20))

                    planButton
                }
                .frame(width: rightWidth, alignment: .leading)
            }
        }
        .padding(.vertical, 30)
    }

    private func benefit(_ title: String, icon: String, tint: Color) -> some View {
        HStack(spacing: 13) {
            Image(systemName: icon)
                .font(.title3.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 30)
            Text(title)
                .font(TriStyle.body(17))
                .foregroundStyle(TriStyle.navy)
        }
    }

    private var planButton: some View {
        Button(action: startPlanning) {
            Label("Create My Training Plan", systemImage: "calendar.badge.plus")
                .font(TriStyle.title(19))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
        }
        .buttonStyle(.borderedProminent)
        .tint(Color.orange)
        .accessibilityHint("Start setting up your race and training days")
    }
}

struct TriCompletionBanner: View {
    let completed: Int
    let total: Int
    let athlete: String

    private var fraction: Double {
        total > 0 ? Double(completed) / Double(total) : 0
    }

    var body: some View {
        TriCard {
            Text("Training completed")
                .font(TriStyle.title(21))
                .foregroundStyle(TriStyle.navy)
            HStack(spacing: 16) {
                ZStack {
                    Circle().stroke(Color.gray.opacity(0.18), lineWidth: 13)
                    Circle()
                        .trim(from: 0, to: fraction)
                        .stroke(TriStyle.green.gradient, style: StrokeStyle(lineWidth: 13, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text("\(Int(fraction * 100))%")
                        .font(TriStyle.title(26))
                        .foregroundStyle(TriStyle.navy)
                }
                .frame(width: 105, height: 105)
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(completed) of \(total)")
                        .font(TriStyle.title(20))
                    Text("sessions")
                        .font(TriStyle.body(15))
                }
                .foregroundStyle(TriStyle.navy)
                Spacer(minLength: 0)
                Image(systemName: athlete == "Male" ? "figure.run" : "figure.run")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(TriStyle.green)
                    .frame(width: 62)
                    .accessibilityLabel("\(athlete) athlete celebrating")
            }
        }
    }
}

struct TriHomeView: View {
    let store: TriDemoStore
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 17) {
                TriBrand().padding(.top, 12)
                TriCompletionBanner(completed: store.completed, total: store.workouts.count, athlete: store.race?.athlete ?? "Female")
                Text("You're doing great! 👋")
                    .font(TriStyle.title(27))
                    .foregroundStyle(TriStyle.navy)
                Text("Every session gets you closer to race day.")
                    .foregroundStyle(TriStyle.muted)

                TriCard {
                    Label("YOUR RACE", systemImage: "flag.checkered")
                        .font(.caption.bold())
                        .foregroundStyle(TriStyle.blue)
                    Text(store.race?.title ?? "Your race")
                        .font(TriStyle.title(22))
                        .foregroundStyle(TriStyle.navy)
                    Text("Your race countdown will appear here once you've chosen a date.")
                        .font(.subheadline)
                        .foregroundStyle(TriStyle.muted)
                }
                TriCard {
                    Text("Your training journey")
                        .font(TriStyle.title(20))
                        .foregroundStyle(TriStyle.navy)
                    Text("Base phase · Building confidence")
                        .font(.subheadline)
                        .foregroundStyle(TriStyle.muted)
                    ProgressView(value: 0.35)
                        .tint(TriStyle.green)
                        .padding(.vertical, 7)
                    HStack {
                        ForEach(["Base", "Build", "Peak", "Taper"], id: \.self) { phase in
                            Text(phase)
                                .font(.caption.bold())
                                .frame(maxWidth: .infinity)
                                .foregroundStyle(phase == "Base" ? TriStyle.green : TriStyle.muted)
                        }
                    }
                }
                TriCard {
                    HStack {
                        Text("This week").font(TriStyle.title(21))
                        Spacer()
                        Text("\(store.completed) of \(store.workouts.count) done")
                            .font(.subheadline.bold())
                            .foregroundStyle(TriStyle.green)
                    }
                    .foregroundStyle(TriStyle.navy)
                    ForEach(store.workouts.prefix(3)) { workout in
                        WorkoutRow(workout: workout)
                    }
                }
            }
            .frame(maxWidth: sizeClass == .regular ? 850 : 620)
            .frame(maxWidth: .infinity)
            .padding(18)
        }
        .background(TriStyle.canvas)
        .toolbar(.hidden)
    }
}

struct TriPlanView: View {
    let store: TriDemoStore
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Training Plan").font(TriStyle.title()).foregroundStyle(TriStyle.navy)
                TriCard {
                    Text("Week 1 · Base phase").font(TriStyle.title(22)).foregroundStyle(TriStyle.navy)
                    Text("Small steps, big progress.").foregroundStyle(TriStyle.muted)
                    ProgressView(value: Double(store.completed), total: Double(store.workouts.count))
                        .tint(TriStyle.green).padding(.top, 5)
                }
                ForEach(store.workouts) { workout in
                    VStack(alignment: .leading, spacing: 7) {
                        Text(workout.day).font(.caption.bold()).foregroundStyle(TriStyle.muted)
                        Button { store.toggle(workout.id) } label: { WorkoutRow(workout: workout) }
                            .buttonStyle(.plain)
                            .accessibilityHint("Double tap to mark this workout complete or incomplete")
                    }
                }
                Text("Tap a session to mark it complete. Your plan should fit your life, not the other way around.")
                    .font(.footnote).foregroundStyle(TriStyle.muted)
            }.padding(18)
        }
        .background(TriStyle.canvas)
    }
}

struct TriProgressView: View {
    let store: TriDemoStore
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 17) {
                Text("Your Progress").font(TriStyle.title()).foregroundStyle(TriStyle.navy)
                TriCard {
                    Text("Look what you've done! 🌟").font(TriStyle.title(22)).foregroundStyle(TriStyle.navy)
                    Text("You've completed \(store.completed) workouts this week!")
                        .font(TriStyle.body(17)).foregroundStyle(TriStyle.navy)
                    ProgressView(value: Double(store.completed), total: Double(store.workouts.count))
                        .tint(TriStyle.green).padding(.vertical, 9)
                    Text("Every workout counts, even the short ones.")
                        .font(.subheadline).foregroundStyle(TriStyle.muted)
                }
                TriCard {
                    Text("Your swim · bike · run mix").font(TriStyle.title(20)).foregroundStyle(TriStyle.navy)
                    ForEach(Sport.allCases) { sport in
                        HStack {
                            SportIcon(sport: sport)
                            Text(sport.rawValue).font(TriStyle.body())
                            Spacer()
                            Text("\(store.workouts.filter { $0.sport == sport && $0.complete }.count) done")
                                .font(.subheadline.bold()).foregroundStyle(sport.tint)
                        }
                    }
                }
                TriCard {
                    Text("Your next milestone 🏅").font(TriStyle.title(20)).foregroundStyle(TriStyle.navy)
                    Text("Finish your first workout in each sport to earn your Tri Trybe starter badge.")
                        .foregroundStyle(TriStyle.muted)
                }
            }.padding(18)
        }.background(TriStyle.canvas)
    }
}

enum RaceDiscipline: String, CaseIterable, Identifiable {
    case triathlon = "Triathlon", aquabike = "Aquabike", aquathlon = "Aquathlon", duathlon = "Duathlon"
    var id: String { rawValue }
    var sports: [Sport] {
        switch self {
        case .triathlon: [.swim, .bike, .run]
        case .aquabike: [.swim, .bike]
        case .aquathlon: [.swim, .run]
        case .duathlon: [.run, .bike]
        }
    }
}

struct TriRaceSetupView: View {
    let store: TriDemoStore
    let onSave: () -> Void
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var step = 0
    @State private var discipline: RaceDiscipline = .triathlon
    @State private var distance = "Sprint"
    @State private var raceDate = Calendar.current.date(byAdding: .month, value: 4, to: .now) ?? .now
    @State private var days: Set<Int> = [1, 2, 4, 6]
    @State private var athlete = "Female"
    private let distances = ["Super Sprint", "Sprint", "Olympic", "T100", "Middle (70.3)", "Long (Ironman)"]
    private let weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 7) {
                        Text("YOUR NEXT ADVENTURE")
                            .font(.caption.bold()).tracking(2).foregroundStyle(TriStyle.blue)
                        Text("Let's get race-ready!")
                            .font(TriStyle.title(28)).foregroundStyle(TriStyle.navy)
                        Text("Your race. Your schedule. Your pace.")
                            .font(TriStyle.body(15)).foregroundStyle(TriStyle.muted)
                    }
                    Spacer(minLength: 0)
                    Image(sizeClass == .regular ? "TriTrybeBanner" : "TriTrybeBannerPhone")
                        .resizable().scaledToFit()
                        .frame(width: sizeClass == .regular ? 230 : 92)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .accessibilityLabel("Tri Trybe cartoon athletes")
                }
                if sizeClass == .regular {
                    HStack(alignment: .top, spacing: 16) {
                        VStack(spacing: 16) {
                            TriCard { sectionTitle("1", "Your event"); eventChoices }
                            TriCard { sectionTitle("2", "Race distance"); distanceChoices }
                        }.frame(maxWidth: .infinity)
                        VStack(spacing: 16) {
                            TriCard {
                                sectionTitle("3", "Race day")
                                DatePicker("Race date", selection: $raceDate, in: Date.now..., displayedComponents: .date)
                                    .datePickerStyle(.compact).tint(TriStyle.blue)
                            }
                            TriCard { sectionTitle("4", "Make it yours"); personalChoices }
                        }.frame(maxWidth: .infinity)
                    }
                    saveButton
                } else {
                    HStack(spacing: 6) {
                        ForEach(0..<4, id: \.self) { i in
                            Capsule().fill(i <= step ? TriStyle.blue : Color.gray.opacity(0.2))
                                .frame(height: 7)
                        }
                    }
                    Text("Step \(step + 1) of 4")
                        .font(TriStyle.body(15)).foregroundStyle(TriStyle.muted)
                    TriCard {
                        if step == 0 {
                            sectionTitle("1", "Choose your event")
                            eventChoices
                        } else if step == 1 {
                            sectionTitle("2", "Choose your distance")
                            distanceChoices
                        } else if step == 2 {
                            sectionTitle("3", "When is race day?")
                            DatePicker("Race date", selection: $raceDate, in: Date.now..., displayedComponents: .date)
                                .datePickerStyle(.graphical).tint(TriStyle.blue)
                        } else {
                            sectionTitle("4", "Make it yours")
                            personalChoices
                        }
                    }
                    HStack(spacing: 12) {
                        if step > 0 {
                            Button("Back") { step -= 1 }.buttonStyle(.bordered)
                        }
                        if step == 3 {
                            saveButton
                        } else {
                            Button("Next") { step += 1 }
                                .font(TriStyle.body(17).weight(.bold))
                                .frame(maxWidth: .infinity)
                                .buttonStyle(.borderedProminent)
                        }
                    }
                }
            }
            .frame(maxWidth: sizeClass == .regular ? 1050 : 620)
            .frame(maxWidth: .infinity)
            .padding(18)
        }
        .background(TriStyle.canvas)
        .onAppear {
            if let race = store.race {
                discipline = RaceDiscipline(rawValue: race.discipline) ?? .triathlon
                distance = race.distance
                raceDate = race.date
                days = Set(race.trainingDays)
                athlete = race.athlete
            }
        }
    }

    private func sectionTitle(_ number: String, _ title: String) -> some View {
        HStack(spacing: 9) {
            Text(number).font(.caption.bold()).foregroundStyle(.white)
                .frame(width: 26, height: 26).background(TriStyle.blue, in: Circle())
            Text(title).font(TriStyle.title(20)).foregroundStyle(TriStyle.navy)
        }
    }

    private var eventChoices: some View {
        LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 10) {
            ForEach(RaceDiscipline.allCases) { item in
                Button { discipline = item } label: {
                    VStack(spacing: 8) {
                        HStack(spacing: 6) {
                            ForEach(item.sports) { sport in
                                Image(systemName: sport.symbol).foregroundStyle(sport.tint)
                            }
                        }.font(.title3)
                        Text(item.rawValue).font(TriStyle.body(15).weight(.bold))
                            .foregroundStyle(TriStyle.navy)
                    }
                    .frame(maxWidth: .infinity, minHeight: 75)
                    .background(discipline == item ? TriStyle.blue.opacity(0.12) : TriStyle.canvas,
                                in: RoundedRectangle(cornerRadius: 15))
                    .overlay(RoundedRectangle(cornerRadius: 15)
                        .stroke(discipline == item ? TriStyle.blue : Color.gray.opacity(0.12),
                                lineWidth: discipline == item ? 2 : 1))
                }.buttonStyle(.plain)
            }
        }
    }

    private var distanceChoices: some View {
        LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 9) {
            ForEach(distances, id: \.self) { item in
                Button { distance = item } label: {
                    HStack {
                        Text(item).font(TriStyle.body(14).weight(.bold))
                        Spacer(minLength: 0)
                        Image(systemName: distance == item ? "checkmark.circle.fill" : "circle")
                    }
                    .foregroundStyle(distance == item ? TriStyle.blue : TriStyle.navy)
                    .padding(10).frame(maxWidth: .infinity, minHeight: 54)
                    .background(distance == item ? TriStyle.blue.opacity(0.10) : TriStyle.canvas,
                                in: RoundedRectangle(cornerRadius: 13))
                }.buttonStyle(.plain)
            }
        }
    }

    private var personalChoices: some View {
        VStack(alignment: .leading, spacing: 11) {
            Text("Choose your athlete").font(TriStyle.body(16).weight(.bold))
            Picker("Athlete", selection: $athlete) {
                Text("Woman").tag("Female")
                Text("Man").tag("Male")
            }.pickerStyle(.segmented)
            Text("Which days can you train?").font(TriStyle.body(16).weight(.bold))
            Text("Choose the days that usually suit you.")
                .font(.footnote).foregroundStyle(TriStyle.muted)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 5), count: 7)) {
                ForEach(weekdays.indices, id: \.self) { i in
                    Button {
                        if days.contains(i) { days.remove(i) } else { days.insert(i) }
                    } label: {
                        Text(String(weekdays[i].prefix(1)))
                            .font(.caption.bold())
                            .foregroundStyle(days.contains(i) ? .white : TriStyle.navy)
                            .frame(maxWidth: .infinity).frame(height: 38)
                            .background(days.contains(i) ? TriStyle.green : TriStyle.canvas,
                                        in: RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(weekdays[i])
                }
            }
            Text("\(days.count) training days selected")
                .font(.footnote).foregroundStyle(days.isEmpty ? TriStyle.red : TriStyle.muted)
        }
    }

    private var saveButton: some View {
        Button {
            store.race = SavedRace(discipline: discipline.rawValue, distance: distance,
                                  date: raceDate, trainingDays: days.sorted(), athlete: athlete)
            onSave()
        } label: {
            Label(store.race == nil ? "Create My Training Plan" : "Save Race Changes",
                  systemImage: "checkmark.circle.fill")
                .font(TriStyle.body(18).weight(.bold))
                .frame(maxWidth: .infinity).padding(.vertical, 12)
        }
        .buttonStyle(.borderedProminent).tint(Color.orange).disabled(days.isEmpty)
    }
}

#Preview { TriTrybeRootView() }
