import SwiftUI

/// Role: Crate segment of the same wall. Mint versus Grooved clusters, never a title list.
struct CrateFold: View {
    @EnvironmentObject private var chrome: WallChrome

    var body: some View {
        Group {
            if chrome.document.pressings.isEmpty {
                EmptySleevePage(
                    art: "dwx_EmptyHome",
                    headline: "The crate is empty.",
                    line: "Find the first title.",
                    cta: "Search the catalog"
                ) {
                    chrome.segment = .discover
                    chrome.showingSearch = true
                }
            } else {
                populated
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Bloom.Pigment.background.ignoresSafeArea())
    }

    private var populated: some View {
        let mint = chrome.store.mintSleeves
        let grooved = chrome.store.groovedSleeves
        return VStack(alignment: .leading, spacing: Bloom.Rhythm.steps(2)) {
            Text("Mint stays unplayed. Grooved already heard.")
                .font(Bloom.Typeface.title)
                .foregroundStyle(Bloom.Pigment.ink)
                .padding(.horizontal, Bloom.Rhythm.steps(2))
            if let fault = chrome.faultCopy {
                WallFaultBanner(copy: fault) {
                    chrome.faultCopy = nil
                }
                .padding(.horizontal, Bloom.Rhythm.steps(2))
            }
            if mint.isEmpty == false {
                Text("Mint")
                    .font(Bloom.Typeface.caption)
                    .foregroundStyle(Bloom.Pigment.muted)
                    .padding(.horizontal, Bloom.Rhythm.steps(2))
                if grooved.isEmpty {
                    PlayTileBoard(
                        pressings: mint,
                        focused: chrome.focusedID,
                        pulse: false,
                        plays: { chrome.store.plays(for: $0) },
                        grade: { chrome.document.grades[$0] },
                        onPick: { chrome.focus($0) }
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, Bloom.Rhythm.steps(2))
                } else {
                    mintStrip(mint)
                }
            }
            if grooved.isEmpty == false {
                Text("Grooved")
                    .font(Bloom.Typeface.caption)
                    .foregroundStyle(Bloom.Pigment.muted)
                    .padding(.horizontal, Bloom.Rhythm.steps(2))
                PlayTileBoard(
                    pressings: grooved,
                    focused: chrome.focusedID,
                    pulse: false,
                    plays: { chrome.store.plays(for: $0) },
                    grade: { chrome.document.grades[$0] },
                    onPick: { chrome.focus($0) }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, Bloom.Rhythm.steps(2))
            }
        }
        .padding(.top, Bloom.Rhythm.steps(2))
        .padding(.bottom, Bloom.Rhythm.steps(1))
    }

    private func mintStrip(_ mint: [Pressing]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: Bloom.Rhythm.steps(1)) {
                ForEach(Array(mint.enumerated()), id: \.element.id) { index, pressing in
                    Button {
                        chrome.focus(pressing)
                    } label: {
                        SleeveTile(
                            pressing: pressing,
                            plays: 0,
                            grade: nil,
                            focused: pressing.id == chrome.focusedID,
                            pulse: false,
                            prominent: index == 0
                        )
                    }
                    .buttonStyle(TilePress())
                    .frame(width: index == 0 ? 200 : 152, height: 220)
                }
            }
            .padding(.horizontal, Bloom.Rhythm.steps(2))
        }
        .frame(height: 228)
    }
}
