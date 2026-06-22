import SwiftUI
import SwiftData

struct HomeView: View {
    var forceScreen: String? = nil

    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var store: Store

    @State private var showSettings = false
    @State private var showPaywall = false
    @State private var showInsights = false

    var body: some View {
        NavigationStack {
            ZStack {
                QMBackground()
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 4) {
                            Text("Kindcue")
                                .font(.largeTitle.weight(.bold))
                                .foregroundStyle(.primary)
                            Text("A daily act of kindness")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 8)

                        // Streak row
                        HStack(spacing: 16) {
                            MetricTile(value: "\(appModel.streak)", label: "Day Streak")
                            MetricTile(
                                value: "\(appModel.history.filter(\.done).count)",
                                label: "Good Deeds"
                            )
                        }
                        .padding(.horizontal)

                        // Today's cue card / action area
                        GridView()
                            .padding(.horizontal)

                        // Pro / Insights tile
                        Button {
                            Haptics.tap()
                            if store.isPro {
                                showInsights = true
                            } else {
                                showPaywall = true
                            }
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(store.isPro ? "Kindness History" : "Kindcue Pro")
                                        .font(.headline)
                                    Text(store.isPro
                                         ? "Your reflection log and streaks"
                                         : "Themed decks, reflections & recap")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: store.isPro ? "heart.text.square" : "lock.fill")
                                    .foregroundStyle(Color.qmAccent)
                                    .font(.title3)
                            }
                            .qmCard()
                            .padding(.horizontal)
                        }
                        .buttonStyle(.plain)

                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(Color.qmAccent)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showInsights) {
                InsightsView()
            }
            .onAppear {
                if let forced = forceScreen {
                    switch forced {
                    case "paywall": showPaywall = true
                    case "insights": showInsights = true
                    case "settings": showSettings = true
                    default: break
                    }
                }
            }
        }
    }
}
