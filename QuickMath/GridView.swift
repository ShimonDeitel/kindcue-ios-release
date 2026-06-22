import SwiftUI
import SwiftData

/// The primary action screen: shows today's kindness cue and lets the user mark it done.
struct GridView: View {
    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var store: Store

    @State private var showReflectionSheet = false
    @State private var reflectionDraft = ""
    @State private var didAnimate = false

    private var entry: KindnessDay? { appModel.todayEntry }
    private var cue: KindnessCue? { appModel.todayCue }
    private var isDone: Bool { entry?.done ?? false }

    var body: some View {
        VStack(spacing: 20) {
            // Category badge
            if let cat = cue?.category {
                Text(cat.uppercased())
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.qmAccent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.qmAccent.opacity(0.12), in: Capsule())
            }

            // Cue text
            Text(cue?.text ?? "Loading your kindness cue…")
                .font(.title3.weight(.medium))
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)
                .padding(.horizontal, 8)
                .animation(.easeInOut(duration: 0.3), value: cue?.text)

            // Done indicator or action button
            if isDone {
                doneBadge
            } else {
                actionButtons
            }

            // Reflection snippet (pro, if filled)
            if store.isPro, let r = entry?.reflection, !r.isEmpty {
                Text("\u{201C}\(r)\u{201D}")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .italic()
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.qmCard)
        )
        .sheet(isPresented: $showReflectionSheet) {
            reflectionSheet
        }
    }

    // MARK: Sub-views

    private var doneBadge: some View {
        VStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 52))
                .foregroundStyle(Color.qmCorrect)
                .scaleEffect(didAnimate ? 1 : 0.6)
                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: didAnimate)
                .onAppear { didAnimate = true }

            Text("Done for today")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.qmCorrect)

            if store.isPro && (entry?.reflection == nil || entry?.reflection?.isEmpty == true) {
                Button("Add a reflection") {
                    reflectionDraft = entry?.reflection ?? ""
                    showReflectionSheet = true
                }
                .font(.caption)
                .foregroundStyle(Color.qmAccent)
            }
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                Haptics.tap()
                if store.isPro {
                    reflectionDraft = ""
                    showReflectionSheet = true
                } else {
                    appModel.markDone()
                }
            } label: {
                Text(store.isPro ? "Done — Add Reflection" : "Mark as Done")
                    .frame(maxWidth: .infinity)
            }
            .prominentButton()

            if !store.isPro {
                Button {
                    appModel.markDone()
                } label: {
                    Text("Quick Done")
                        .frame(maxWidth: .infinity)
                }
                .softButton()
            }
        }
    }

    private var reflectionSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("How did it go?")
                    .font(.title3.weight(.semibold))
                    .padding(.top, 8)

                TextEditor(text: $reflectionDraft)
                    .font(.body)
                    .frame(minHeight: 120)
                    .padding(12)
                    .background(Color.qmField, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                Spacer()
            }
            .padding()
            .navigationTitle("Reflection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showReflectionSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        appModel.markDone(reflection: reflectionDraft.isEmpty ? nil : reflectionDraft)
                        showReflectionSheet = false
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
