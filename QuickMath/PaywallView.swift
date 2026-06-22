import SwiftUI

struct PaywallView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss

    private let benefits: [(icon: String, text: String)] = [
        ("paintbrush.pointed", "Themed kindness decks refreshed every month"),
        ("note.text", "Reflection notes and a kindness history log"),
        ("bell.badge", "Morning reminder and monthly good-deed recap"),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                QMBackground()
                VStack(spacing: 28) {
                    Spacer()

                    // Icon
                    ZStack {
                        Circle()
                            .fill(Color.qmAccent.opacity(0.12))
                            .frame(width: 90, height: 90)
                        Image(systemName: "heart")
                            .font(.system(size: 40, weight: .light))
                            .foregroundStyle(Color.qmAccent)
                    }

                    // Title & price
                    VStack(spacing: 8) {
                        Text("Kindcue Pro")
                            .font(.title.weight(.bold))
                        Text("\(store.displayPrice) / month. Auto-renews until you cancel.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    // Benefits
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(benefits, id: \.text) { benefit in
                            HStack(alignment: .top, spacing: 14) {
                                Image(systemName: benefit.icon)
                                    .font(.system(size: 18, weight: .light))
                                    .foregroundStyle(Color.qmAccent)
                                    .frame(width: 26)
                                Text(benefit.text)
                                    .font(.body)
                                    .foregroundStyle(.primary)
                            }
                        }
                    }
                    .padding(.horizontal, 8)

                    Spacer()

                    // Actions
                    VStack(spacing: 12) {
                        Button {
                            Task { await store.purchase() }
                        } label: {
                            if store.purchaseInFlight {
                                ProgressView()
                                    .tint(.white)
                                    .frame(maxWidth: .infinity)
                            } else {
                                Text("Unlock Kindcue Pro")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .prominentButton()
                        .disabled(store.purchaseInFlight)

                        Button("Restore Purchase") {
                            Task { await store.restore() }
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }

                    // Disclosure
                    VStack(spacing: 6) {
                        Text("Subscription automatically renews at \(store.displayPrice)/month unless cancelled at least 24 hours before the end of the current period. Manage in your Apple Account settings.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)

                        HStack(spacing: 16) {
                            Link("Terms of Use", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                            Link("Privacy Policy", destination: URL(string: "https://shimondeitel.github.io/kindcue-site/privacy.html")!)
                        }
                        .font(.caption2)
                        .foregroundStyle(Color.qmAccent)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
                .padding(.horizontal, 28)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .onChange(of: store.isPro) { _, newValue in
                if newValue { dismiss() }
            }
        }
    }
}
