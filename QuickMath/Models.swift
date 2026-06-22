import Foundation
import SwiftData

// MARK: - SwiftData Models

@Model
final class KindnessDay {
    var id: UUID
    var date: Date
    var cueId: String
    var done: Bool
    var reflection: String?

    init(id: UUID = UUID(), date: Date, cueId: String, done: Bool = false, reflection: String? = nil) {
        self.id = id
        self.date = date
        self.cueId = cueId
        self.done = done
        self.reflection = reflection
    }
}

@Model
final class KindnessCue {
    var id: UUID
    var text: String
    var category: String
    var isPro: Bool

    init(id: UUID = UUID(), text: String, category: String, isPro: Bool = false) {
        self.id = id
        self.text = text
        self.category = category
        self.isPro = isPro
    }
}

// MARK: - Built-in cue seed data

extension KindnessCue {
    static let seed: [(text: String, category: String, isPro: Bool)] = [
        // Free deck
        ("Hold the door open for the next person behind you.", "Everyday", false),
        ("Compliment a colleague on their work today.", "Work", false),
        ("Text a friend you haven't spoken to in a while.", "Connection", false),
        ("Leave an encouraging note where a stranger might find it.", "Community", false),
        ("Let someone merge ahead of you in traffic.", "Everyday", false),
        ("Donate a canned good to a local food bank bin.", "Community", false),
        ("Say thank you to a service worker and mean it.", "Everyday", false),
        ("Help someone carry something heavy.", "Everyday", false),
        ("Smile and make eye contact with five people today.", "Connection", false),
        ("Tell someone what you genuinely appreciate about them.", "Connection", false),
        ("Buy a coffee or tea for the person behind you in line.", "Community", false),
        ("Pick up a piece of litter you didn't drop.", "Community", false),
        ("Write a positive online review for a small business.", "Community", false),
        ("Share a kind memory about someone with them.", "Connection", false),
        ("Let someone else speak first in a meeting.", "Work", false),
        ("Check in on an elderly neighbor.", "Community", false),
        ("Offer to help a coworker who looks overwhelmed.", "Work", false),
        ("Cook or bake something to share with others.", "Everyday", false),
        ("Send a voice message instead of a text — it's more personal.", "Connection", false),
        ("Call a family member just to say hello.", "Connection", false),
        ("Give a genuine compliment to someone in a service role.", "Everyday", false),
        ("Offer your seat to someone who needs it more.", "Everyday", false),
        ("Be patient with someone who is going slowly.", "Everyday", false),
        ("Donate something you no longer need.", "Community", false),
        ("Write a letter of appreciation to a teacher or mentor.", "Connection", false),
        ("Water a neighbor's plants or collect their mail when they're away.", "Community", false),
        ("Introduce two people who you think should meet.", "Connection", false),
        ("Leave a generous tip, even at a counter.", "Community", false),
        ("Share a skill or piece of knowledge with someone freely.", "Work", false),
        ("Forgive someone silently — even if they don't know it.", "Wellbeing", false),
        // Pro themed deck
        ("Volunteer one hour at a local charity or event.", "Service", true),
        ("Sponsor a child's school supply through a community program.", "Service", true),
        ("Write a public shoutout recognizing someone's unnoticed effort.", "Community", true),
        ("Organize a small neighborhood clean-up with a friend.", "Community", true),
        ("Pay it forward — cover someone's small expense anonymously.", "Community", true),
        ("Mentor someone newer in your field for 20 minutes.", "Work", true),
        ("Create a care package for someone going through a hard time.", "Connection", true),
        ("Advocate for a cause you believe in by sharing factual info.", "Service", true),
        ("Offer free childcare to a parent who needs a break.", "Service", true),
        ("Write a heartfelt letter of recommendation for someone.", "Work", true),
    ]
}

// MARK: - AppModel

@MainActor
final class AppModel: ObservableObject {
    let container: ModelContainer
    weak var store: Store?

    @Published private(set) var todayEntry: KindnessDay?
    @Published private(set) var todayCue: KindnessCue?
    @Published private(set) var streak: Int = 0
    @Published private(set) var history: [KindnessDay] = []

    init(container: ModelContainer) {
        self.container = container
        reload()
    }

    static func makeContainer() -> ModelContainer {
        let schema = Schema([KindnessDay.self, KindnessCue.self])
        do {
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            let fallback = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return try! ModelContainer(for: schema, configurations: [fallback])
        }
    }

    func reload() {
        seedCuesIfNeeded()
        let ctx = container.mainContext
        let today = Calendar.current.startOfDay(for: Date())

        // Fetch or create today's KindnessDay
        let allDays = (try? ctx.fetch(FetchDescriptor<KindnessDay>())) ?? []
        history = allDays.filter { Calendar.current.startOfDay(for: $0.date) <= today }
            .sorted { $0.date > $1.date }

        if let existing = allDays.first(where: { Calendar.current.isDateInToday($0.date) }) {
            todayEntry = existing
        } else {
            let cue = pickCue()
            let day = KindnessDay(date: today, cueId: cue?.id.uuidString ?? "")
            ctx.insert(day)
            try? ctx.save()
            todayEntry = day
        }

        todayCue = resolveCue(id: todayEntry?.cueId)
        streak = computeStreak(days: allDays)
    }

    func refresh() { reload() }

    func markDone(reflection: String? = nil) {
        guard let entry = todayEntry else { return }
        entry.done = true
        if let r = reflection, !r.isEmpty { entry.reflection = r }
        try? container.mainContext.save()
        streak = computeStreak(days: (try? container.mainContext.fetch(FetchDescriptor<KindnessDay>())) ?? [])
        Haptics.success()
    }

    func deleteAllData() {
        let ctx = container.mainContext
        let days = (try? ctx.fetch(FetchDescriptor<KindnessDay>())) ?? []
        let cues = (try? ctx.fetch(FetchDescriptor<KindnessCue>())) ?? []
        days.forEach { ctx.delete($0) }
        cues.forEach { ctx.delete($0) }
        try? ctx.save()
        reload()
    }

    // MARK: Private helpers

    private func pickCue() -> KindnessCue? {
        let isPro = store?.isPro ?? false
        let cues = fetchCues().filter { isPro || !$0.isPro }
        guard !cues.isEmpty else { return fetchCues().first }
        // Avoid repeating recent cue ids
        let recentIds = Set(history.prefix(7).map { $0.cueId })
        let fresh = cues.filter { !recentIds.contains($0.id.uuidString) }
        let pool = fresh.isEmpty ? cues : fresh
        return pool.randomElement()
    }

    private func resolveCue(id: String?) -> KindnessCue? {
        guard let id else { return nil }
        return fetchCues().first { $0.id.uuidString == id }
    }

    private func fetchCues() -> [KindnessCue] {
        (try? container.mainContext.fetch(FetchDescriptor<KindnessCue>())) ?? []
    }

    private func seedCuesIfNeeded() {
        let ctx = container.mainContext
        let existing = (try? ctx.fetch(FetchDescriptor<KindnessCue>())) ?? []
        guard existing.isEmpty else { return }
        for seed in KindnessCue.seed {
            ctx.insert(KindnessCue(text: seed.text, category: seed.category, isPro: seed.isPro))
        }
        try? ctx.save()
    }

    private func computeStreak(days: [KindnessDay]) -> Int {
        let cal = Calendar.current
        let doneDays = days.filter { $0.done }.map { cal.startOfDay(for: $0.date) }
        let sorted = Array(Set(doneDays)).sorted(by: >)
        guard !sorted.isEmpty else { return 0 }
        var streak = 0
        var expected = cal.startOfDay(for: Date())
        for day in sorted {
            if day == expected {
                streak += 1
                expected = cal.date(byAdding: .day, value: -1, to: expected)!
            } else {
                break
            }
        }
        return streak
    }
}
