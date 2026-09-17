import SwiftUI

/// Role: Settings cover from wall chrome. Contact, catalog credits, re-run onboarding, confirmed reset.
struct WallSettings: View {
    @EnvironmentObject private var chrome: WallChrome
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Bloom.Rhythm.steps(2)) {
                HStack {
                    Text("Settings")
                        .font(Bloom.Typeface.display)
                        .foregroundStyle(Bloom.Pigment.ink)
                    Spacer(minLength: 0)
                    BloomIcon(symbol: "xmark", label: "Close settings") {
                        dismiss()
                    }
                }
                settingsCard {
                    Button("Contact Deadwax") {
                        openURL(WallLinks.contact)
                    }
                    .buttonStyle(NeedlePress(kind: .quiet))
                    Text(WallLinks.contact.absoluteString)
                        .font(Bloom.Typeface.micro)
                        .foregroundStyle(Bloom.Pigment.muted)
                }
                settingsCard {
                    Text("Catalog sources")
                        .font(Bloom.Typeface.headline)
                        .foregroundStyle(Bloom.Pigment.ink)
                    Button("MusicBrainz") { openURL(WallLinks.musicBrainz) }
                        .buttonStyle(NeedlePress(kind: .quiet))
                    Button("Cover Art Archive") { openURL(WallLinks.coverArt) }
                        .buttonStyle(NeedlePress(kind: .quiet))
                }
                settingsCard {
                    Button("Walk the wall again") {
                        chrome.replayOnboarding()
                    }
                    .buttonStyle(NeedlePress(kind: .quiet))
                    Button("Reset the wall") {
                        chrome.confirmReset = true
                    }
                    .buttonStyle(NeedlePress(kind: .destructive))
                }
            }
            .padding(Bloom.Rhythm.steps(2))
        }
        .scrollDismissesKeyboard(.interactively)
        .contentMargins(.bottom, Bloom.Rhythm.steps(2), for: .scrollContent)
        .background(Bloom.Pigment.background.ignoresSafeArea())
        .confirmationDialog(
            "Reset the wall?",
            isPresented: $chrome.confirmReset,
            titleVisibility: .visible
        ) {
            Button("Reset the wall", role: .destructive) {
                Task { await chrome.resetWall() }
            }
            Button("Keep the wall", role: .cancel) {}
        } message: {
            Text("All sleeves, plays, and grades leave this device.")
        }
    }

    private func settingsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Bloom.Rhythm.steps(2)) {
            content()
        }
        .padding(Bloom.Rhythm.steps(2))
        .frame(maxWidth: .infinity, alignment: .leading)
        .bloomCard()
    }
}
