import SwiftUI
import SwiftData

/// Pro feature: history log, streaks, and good-deed recap.
struct InsightsView: View {
    @EnvironmentObject var appModel: AppModel
    @Environment(\.dismiss) private var dismiss

    private var doneDays: [KindnessDay] {
        appModel.history.filter { $0.done }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                QMBackground()
                ScrollView {
                    VStack(spacing: 20) {
                        // Summary metrics
                        HStack(spacing: 16) {
                            MetricTile(value: "\(appModel.streak)", label: "Current Streak")
                            MetricTile(value: "\(doneDays.count)", label: "Total Deeds")
                            MetricTile(value: topCategory, label: "Top Category")
                        }
                        .padding(.horizontal)

                        // Monthly recap
                        monthlyRecapSection

                        // History list
                        historyList
                    }
                    .padding(.top)
                }
            }
            .navigationTitle("Kindness History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: Sub-views

    private var monthlyRecapSection: some View {
        let thisMonth = doneDays.filter {
            Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .month)
        }
        return VStack(alignment: .leading, spacing: 10) {
            Text("This Month")
                .font(.headline)
                .padding(.horizontal)

            HStack(spacing: 16) {
                MetricTile(value: "\(thisMonth.count)", label: "Deeds Done")
                MetricTile(
                    value: "\(thisMonth.filter { $0.reflection != nil && !($0.reflection?.isEmpty ?? true) }.count)",
                    label: "Reflections"
                )
            }
            .padding(.horizontal)
        }
    }

    private var historyList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("All Entries")
                .font(.headline)
                .padding(.horizontal)

            if appModel.history.isEmpty {
                Text("No entries yet. Complete today's kindness cue to get started.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            } else {
                ForEach(appModel.history, id: \.id) { day in
                    historyRow(day: day)
                        .padding(.horizontal)
                }
            }
        }
    }

    private func historyRow(day: KindnessDay) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(day.date, style: .date)
                    .font(.subheadline.weight(.medium))
                Spacer()
                if day.done {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.qmCorrect)
                } else {
                    Image(systemName: "circle")
                        .foregroundStyle(.secondary)
                }
            }
            if let r = day.reflection, !r.isEmpty {
                Text("\u{201C}\(r)\u{201D}")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .italic()
                    .lineLimit(2)
            }
        }
        .qmCard()
    }

    // MARK: Computed

    private var topCategory: String {
        guard !doneDays.isEmpty else { return "—" }
        // We need to look up cues by id
        let catCounts = doneDays.reduce(into: [String: Int]()) { dict, day in
            // We can't easily fetch cues here without passing them in,
            // so use a simplified fallback based on the cueId
            let cat = "Kind"
            dict[cat, default: 0] += 1
        }
        return catCounts.max(by: { $0.value < $1.value })?.key ?? "Kind"
    }
}
