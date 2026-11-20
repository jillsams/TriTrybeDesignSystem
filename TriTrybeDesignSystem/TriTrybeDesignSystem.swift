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
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                if UIImage(named: "TriTrybeBanner") != nil {
                    Image("TriTrybeBanner")
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        .accessibilityLabel("Cartoon swimmer, cyclist and runner. Your journey, your pace. Celebrate every workout.")
                } else {
                    RoundedRectangle(cornerRadius: 26)
                        .fill(TriStyle.blue.gradient)
                    VStack(alignment: .leading, spacing: 9) {
                        Text("SWIM  ·  BIKE  ·  RUN")
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                        Text("Your journey.\nYour pace.")
                            .font(TriStyle.title(29))
                        Text("Celebrate every workout.")
                            .font(TriStyle.body(13))
                    }
                    .foregroundStyle(.white)
                    .padding(23)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        }
        .frame(height: 180)
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

@MainActor @Observable final class TriDemoStore {
    var workouts: [Workout] = [
        .init(day: "Mon", sport: .swim, name: "Easy Swim", minutes: 30, detail: "Comfortable pace", complete: true),
        .init(day: "Tue", sport: .bike, name: "Steady Ride", minutes: 45, detail: "Easy effort", complete: true),
        .init(day: "Thu", sport: .run, name: "Run & Walk", minutes: 25, detail: "Take your time"),
        .init(day: "Sat", sport: .bike, name: "Weekend Ride", minutes: 60, detail: "Enjoy the ride"),
        .init(day: "Sun", sport: .swim, name: "Swim Skills", minutes: 25, detail: "Build confidence")
    ]
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
    var body: some View {
        TabView {
            NavigationStack { TriHomeView(store: store) }
                .tabItem { Label("Home", systemImage: "house.fill") }
            NavigationStack { TriPlanView(store: store) }
                .tabItem { Label("Plan", systemImage: "calendar") }
            NavigationStack { TriProgressView(store: store) }
                .tabItem { Label("Progress", systemImage: "chart.bar.fill") }
            NavigationStack { TriRaceSetupView() }
                .tabItem { Label("Race", systemImage: "flag.checkered") }
        }
        .tint(TriStyle.blue)
        .alert("Your first \(store.lastCelebrated.rawValue.lowercased())! 🎉", isPresented: $store.showCelebration) {
            Button("Keep going!") { }
        } message: {
            Text("You showed up and gave it a go. That's worth celebrating!")
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
                TriWelcomeBanner()
                Text("You're doing great! 👋")
                    .font(TriStyle.title(27))
                    .foregroundStyle(TriStyle.navy)
                Text("Every session gets you closer to race day.")
                    .foregroundStyle(TriStyle.muted)

                TriCard {
                    Label("YOUR RACE", systemImage: "flag.checkered")
                        .font(.caption.bold())
                        .foregroundStyle(TriStyle.blue)
                    Text("Your first Sprint Triathlon")
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
    @State private var step = 0
    @State private var discipline: RaceDiscipline = .triathlon
    @State private var distance = "Sprint"
    @State private var raceDate = Calendar.current.date(byAdding: .month, value: 4, to: .now) ?? .now
    @State private var days: Set<Int> = [1, 2, 4, 6]
    @State private var showConfirmation = false
    private let distances = ["Super Sprint", "Sprint", "Olympic", "T100", "Middle (70.3)", "Long (Ironman)"]
    private let weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Set Up Your Race").font(TriStyle.title()).foregroundStyle(TriStyle.navy)
                HStack(spacing: 6) {
                    ForEach(0..<4, id: \.self) { i in
                        Capsule().fill(i <= step ? TriStyle.blue : Color.gray.opacity(0.18))
                            .frame(height: 7)
                    }
                }
                Text(["What are you training for?", "Choose your race distance", "When is race day?", "Make it work for you"][step])
                    .font(TriStyle.title(23)).foregroundStyle(TriStyle.navy)
                if step == 0 {
                    LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 12) {
                        ForEach(RaceDiscipline.allCases) { item in
                            Button { discipline = item } label: {
                                VStack(spacing: 11) {
                                    HStack(spacing: 6) {
                                        ForEach(item.sports) { sport in
                                            Image(systemName: sport.symbol)
                                                .font(.title3).foregroundStyle(sport.tint)
                                        }
                                    }
                                    Text(item.rawValue).font(TriStyle.body(17).weight(.bold)).foregroundStyle(TriStyle.navy)
                                }
                                .frame(maxWidth: .infinity, minHeight: 95)
                                .background(discipline == item ? TriStyle.blue.opacity(0.10) : .white,
                                            in: RoundedRectangle(cornerRadius: 20))
                                .overlay(RoundedRectangle(cornerRadius: 20)
                                    .stroke(discipline == item ? TriStyle.blue : Color.gray.opacity(0.15), lineWidth: discipline == item ? 2.5 : 1))
                            }.buttonStyle(.plain)
                        }
                    }
                } else if step == 1 {
                    ForEach(distances, id: \.self) { item in
                        Button { distance = item } label: {
                            HStack {
                                Text(item).font(TriStyle.body(17).weight(.bold))
                                Spacer()
                                Image(systemName: distance == item ? "checkmark.circle.fill" : "circle")
                            }
                            .foregroundStyle(distance == item ? TriStyle.blue : TriStyle.navy)
                            .padding(17)
                            .background(.white, in: RoundedRectangle(cornerRadius: 16))
                        }.buttonStyle(.plain)
                    }
                } else if step == 2 {
                    TriCard {
                        DatePicker("Race day", selection: $raceDate, in: Date.now..., displayedComponents: .date)
                            .datePickerStyle(.graphical).tint(TriStyle.blue)
                    }
                } else {
                    TriCard {
                        Text("Which days can you train?").font(TriStyle.title(20)).foregroundStyle(TriStyle.navy)
                        Text("Pick the days that usually suit you. You can change them later.")
                            .font(.subheadline).foregroundStyle(TriStyle.muted)
                        ForEach(weekdays.indices, id: \.self) { i in
                            Toggle(weekdays[i], isOn: Binding(
                                get: { days.contains(i) },
                                set: { on in if on { days.insert(i) } else { days.remove(i) } }
                            )).tint(TriStyle.green)
                        }
                    }
                }
                HStack {
                    if step > 0 {
                        Button("Back") { step -= 1 }.buttonStyle(.bordered)
                    }
                    Button(step == 3 ? "Save My Race" : "Next") {
                        if step < 3 { step += 1 } else { showConfirmation = true }
                    }
                    .font(TriStyle.body(17).weight(.bold))
                    .frame(maxWidth: .infinity).buttonStyle(.borderedProminent)
                    .disabled(step == 3 && days.isEmpty)
                }
                .padding(.top, 12)
            }.padding(18)
        }
        .background(TriStyle.canvas)
        .alert("Race setup saved in this preview! 🎉", isPresented: $showConfirmation) {
            Button("Great!") { }
        } message: {
            Text("You've chosen \(discipline.rawValue), \(distance). Next we'll connect this setup to your real training-plan generator.")
        }
    }
}

#Preview { TriTrybeRootView() }
