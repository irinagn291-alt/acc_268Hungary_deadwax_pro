import SwiftUI

/// Role: Search cover over Discover. Catalog query with local shelf fallback. Dismisses back to the wall.
struct CatalogSeek: View {
    @EnvironmentObject private var chrome: WallChrome
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var hits: [CatalogHit] = []
    @State private var fault: String?
    @State private var showSpinner = false
    @State private var seekTask: Task<Void, Never>?
    @State private var spinnerTask: Task<Void, Never>?
    @FocusState private var fieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Bloom.Rhythm.steps(2)) {
            HStack(spacing: Bloom.Rhythm.steps(1)) {
                Text("Search the catalog")
                    .font(Bloom.Typeface.title)
                    .foregroundStyle(Bloom.Pigment.ink)
                Spacer(minLength: 0)
                BloomIcon(symbol: "xmark", label: "Close search") {
                    dismiss()
                }
            }
            TextField("Artist, title, label, or catalog code", text: $query)
                .font(Bloom.Typeface.body)
                .foregroundStyle(Bloom.Pigment.ink)
                .padding(Bloom.Rhythm.steps(2))
                .frame(minHeight: Bloom.Rhythm.steps(6))
                .background(Bloom.Pigment.surface)
                .clipShape(RoundedRectangle(cornerRadius: Bloom.Bend.card, style: .continuous))
                .bloomLift()
                .focused($fieldFocused)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .onSubmit {
                    fieldFocused = false
                    scheduleSeek()
                }
                .onChange(of: query) { _, _ in
                    scheduleSeek()
                }
            content
        }
        .padding(Bloom.Rhythm.steps(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Bloom.Pigment.background.ignoresSafeArea())
        .scrollDismissesKeyboard(.interactively)
        .simultaneousGesture(TapGesture().onEnded { fieldFocused = false })
        .onAppear {
            hits = chrome.document.shelf
            fieldFocused = true
        }
        .onDisappear {
            seekTask?.cancel()
            spinnerTask?.cancel()
        }
    }

    @ViewBuilder
    private var content: some View {
        if showSpinner {
            VStack(spacing: Bloom.Rhythm.steps(2)) {
                Spacer()
                ProgressView()
                    .tint(Bloom.Pigment.accent)
                Text("Looking through MusicBrainz.")
                    .font(Bloom.Typeface.body)
                    .foregroundStyle(Bloom.Pigment.muted)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let fault {
            EmptySleevePage(
                art: "dwx_EmptyList",
                headline: "Search did not land.",
                line: fault,
                cta: "Retry"
            ) {
                scheduleSeek()
            }
        } else if hits.isEmpty && query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
            EmptySleevePage(
                art: "dwx_EmptyList",
                headline: "No pressing matches that search.",
                line: "Try another spelling, or Scan a catalog code.",
                cta: "Scan a sleeve"
            ) {
                dismiss()
                chrome.showingScan = true
            }
        } else {
            resultList
        }
    }

    private var resultList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Bloom.Rhythm.steps(1)) {
                if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("Cached pressings on this device.")
                        .font(Bloom.Typeface.caption)
                        .foregroundStyle(Bloom.Pigment.muted)
                }
                ForEach(hits) { hit in
                    Button {
                        Task { await chrome.sleeve(hit) }
                    } label: {
                        HStack(spacing: Bloom.Rhythm.steps(2)) {
                            SleeveFront(urlString: hit.sleeveFrontURL, corner: Bloom.Bend.chip)
                                .frame(width: 64, height: 64)
                            VStack(alignment: .leading, spacing: Bloom.Rhythm.unit) {
                                Text(hit.artist)
                                    .font(Bloom.Typeface.caption)
                                    .foregroundStyle(Bloom.Pigment.muted)
                                    .lineLimit(1)
                                Text(hit.title)
                                    .font(Bloom.Typeface.headline)
                                    .foregroundStyle(Bloom.Pigment.ink)
                                    .lineLimit(1)
                                Text(hit.label.isEmpty ? hit.catalogCode : hit.label)
                                    .font(Bloom.Typeface.micro)
                                    .foregroundStyle(Bloom.Pigment.muted)
                                    .lineLimit(1)
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(Bloom.Rhythm.steps(2))
                        .frame(maxWidth: .infinity, minHeight: Bloom.Rhythm.steps(10), alignment: .leading)
                        .bloomCard()
                    }
                    .buttonStyle(TilePress())
                    .disabled(chrome.busySleeve)
                    .accessibilityLabel("\(hit.artist), \(hit.title)")
                }
            }
            .padding(.bottom, Bloom.Rhythm.steps(2))
        }
        .contentMargins(.bottom, Bloom.Rhythm.steps(2), for: .scrollContent)
    }

    private func scheduleSeek() {
        seekTask?.cancel()
        spinnerTask?.cancel()
        showSpinner = false
        fault = nil
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            hits = chrome.document.shelf
            return
        }
        seekTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            spinnerTask = Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(150))
                guard !Task.isCancelled else { return }
                showSpinner = true
            }
            do {
                let found = try await chrome.seek(trimmed)
                guard !Task.isCancelled else { return }
                hits = found
                fault = nil
            } catch CatalogFault.cancelled {
                return
            } catch CatalogFault.transport {
                hits = CatalogShelf.matching(trimmed, in: chrome.document.shelf)
                if hits.isEmpty {
                    fault = "MusicBrainz did not answer. Cached sleeves are empty for that query."
                }
            } catch {
                hits = CatalogShelf.matching(trimmed, in: chrome.document.shelf)
                if hits.isEmpty {
                    fault = "That search failed. Try again, or Scan a code."
                }
            }
            spinnerTask?.cancel()
            showSpinner = false
        }
    }
}
