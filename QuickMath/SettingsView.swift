import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var appModel: AppModel
    @Environment(\.dismiss) private var dismiss

    @AppStorage("quickmath.theme") private var themeRaw = AppTheme.system.rawValue
    @State private var showPaywall = false
    @State private var showDeleteConfirm = false

    private var theme: Binding<String> {
        Binding(get: { themeRaw }, set: { themeRaw = $0 })
    }

    var body: some View {
        NavigationStack {
            List {
                // Pro Section
                Section("Kindcue Pro") {
                    if store.isPro {
                        HStack {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(Color.qmAccent)
                            Text("Pro Active")
                                .foregroundStyle(.primary)
                        }
                        Button("Manage Subscription") {
                            UIApplication.shared.open(
                                URL(string: "https://apps.apple.com/account/subscriptions")!
                            )
                        }
                        .foregroundStyle(Color.qmAccent)
                    } else {
                        Button("Unlock Kindcue Pro") {
                            showPaywall = true
                        }
                        .foregroundStyle(Color.qmAccent)
                        Button("Restore Purchase") {
                            Task { await store.restore() }
                        }
                        .foregroundStyle(.secondary)
                    }
                }

                // Reminder
                Section("Reminder") {
                    Button("Set Morning Reminder (8:00 AM)") {
                        Task {
                            let granted = await Reminders.requestAuthorization()
                            if granted { Reminders.schedule(hour: 8, minute: 0) }
                        }
                    }
                    .foregroundStyle(Color.qmAccent)
                    Button("Cancel Reminder") {
                        Reminders.cancel()
                    }
                    .foregroundStyle(.secondary)
                }

                // Appearance
                Section("Appearance") {
                    Picker("Theme", selection: theme) {
                        ForEach(AppTheme.allCases) { t in
                            Text(t.label).tag(t.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Legal
                Section("Legal") {
                    Link("Privacy Policy",
                         destination: URL(string: "https://shimondeitel.github.io/kindcue-site/privacy.html")!)
                        .foregroundStyle(Color.qmAccent)
                    Link("Terms of Use",
                         destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                        .foregroundStyle(Color.qmAccent)
                }

                // Data
                Section {
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Text("Delete All Data")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .confirmationDialog(
                "Delete all kindness history and start fresh?",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete All Data", role: .destructive) {
                    appModel.deleteAllData()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
}
