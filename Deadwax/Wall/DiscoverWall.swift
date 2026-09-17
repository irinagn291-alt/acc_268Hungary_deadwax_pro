import SwiftUI

/// Role: Home mechanic. Mixed-size sleeve tiles, one cutout, a fat Drop CTA. Search and Scan cover this wall.
struct DiscoverWall: View {
    @EnvironmentObject private var chrome: WallChrome
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var noteFocused: Bool
    @ScaledMetric(relativeTo: .title2) private var cutoutWidth = Bloom.Rhythm.steps(12)
    @ScaledMetric(relativeTo: .title2) private var cutoutHeight = Bloom.Rhythm.steps(8)

    var body: some View {
        Group {
            if chrome.document.pressings.isEmpty {
                EmptySleevePage(
                    art: "dwx_EmptyHome",
                    headline: "The wall is empty.",
                    line: "Sleeve the first pressing.",
                    cta: "Search or Scan"
                ) {
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
        VStack(alignment: .leading, spacing: Bloom.Rhythm.steps(2)) {
            header
            banners
            board
            fuseStrip
            dropControl
        }
        .padding(.horizontal, Bloom.Rhythm.steps(2))
        .padding(.top, Bloom.Rhythm.steps(1))
        .overlay(alignment: .center) {
            if chrome.showSuccess {
                Image("dwx_SuccessMark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: Bloom.Rhythm.steps(12), height: Bloom.Rhythm.steps(12))
                    .accessibilityHidden(true)
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: Bloom.Rhythm.steps(2)) {
            VStack(alignment: .leading, spacing: Bloom.Rhythm.steps(1)) {
                Text("Tap a sleeve.")
                    .font(Bloom.Typeface.display)
                    .foregroundStyle(Bloom.Pigment.ink)
                    .lineLimit(2)
                Text("Then Drop.")
                    .font(Bloom.Typeface.body)
                    .foregroundStyle(Bloom.Pigment.muted)
                    .lineLimit(2)
                HStack(spacing: Bloom.Rhythm.steps(1)) {
                    BloomIcon(symbol: "magnifyingglass", label: "Search") {
                        chrome.showingSearch = true
                    }
                    BloomIcon(symbol: "barcode.viewfinder", label: "Scan") {
                        chrome.showingScan = true
                    }
                    BloomIcon(symbol: "gearshape", label: "Settings") {
                        chrome.showingSettings = true
                    }
                }
            }
            Spacer(minLength: 0)
            Button {
                chrome.showingTwist = true
            } label: {
                Image("dwx_HeaderDecor")
                    .resizable()
                    .scaledToFit()
                    .frame(width: cutoutWidth, height: cutoutHeight)
                    .padding(Bloom.Rhythm.steps(1))
                    .background(Bloom.Pigment.surface)
                    .clipShape(RoundedRectangle(cornerRadius: Bloom.Bend.card, style: .continuous))
                    .contentShape(RoundedRectangle(cornerRadius: Bloom.Bend.card, style: .continuous))
            }
            .buttonStyle(TilePress())
            .bloomLift()
            .accessibilityLabel("How Drop works")
        }
    }

    @ViewBuilder
    private var banners: some View {
        if chrome.recoveredFromBackup {
            WallFaultBanner(copy: "The wall was restored from a backup.") {
                chrome.faultCopy = nil
            }
        }
        if let fault = chrome.faultCopy {
            WallFaultBanner(copy: fault) {
                Task { await chrome.dropFocused(reduceMotion: reduceMotion) }
            }
        }
    }

    private var board: some View {
        ZStack {
            GrooveRings()
                .stroke(Bloom.Pigment.accent.opacity(0.14), lineWidth: 2)
                .allowsHitTesting(false)
            PlayTileBoard(
                pressings: chrome.document.pressings,
                focused: chrome.focusedID,
                pulse: chrome.dropPulse,
                plays: { chrome.store.plays(for: $0) },
                grade: { chrome.document.grades[$0] },
                onPick: { chrome.focus($0) }
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var fuseStrip: some View {
        if let pressing = chrome.focused {
            VStack(alignment: .leading, spacing: Bloom.Rhythm.steps(1)) {
                HStack(alignment: .firstTextBaseline, spacing: Bloom.Rhythm.steps(1)) {
                    Text(pressing.title)
                        .font(Bloom.Typeface.headline)
                        .foregroundStyle(Bloom.Pigment.ink)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    if pressing.groove == .grooved {
                        GroovePip(plays: chrome.store.plays(for: pressing.id), prominent: true)
                            .layoutPriority(1)
                    }
                }
                if pressing.groove == .grooved {
                    gradeRow
                    TextField("Local note on this copy", text: Binding(
                        get: { chrome.fuseNote },
                        set: { chrome.editNote($0) }
                    ))
                    .font(Bloom.Typeface.body)
                    .foregroundStyle(Bloom.Pigment.ink)
                    .focused($noteFocused)
                    .submitLabel(.done)
                    .onSubmit { noteFocused = false }
                    .padding(Bloom.Rhythm.steps(2))
                    .frame(minHeight: Bloom.Rhythm.steps(6), alignment: .leading)
                    .background(Bloom.Pigment.surface)
                    .clipShape(RoundedRectangle(cornerRadius: Bloom.Bend.card, style: .continuous))
                    HStack(spacing: Bloom.Rhythm.steps(1)) {
                        Text("Grade and retract stay on Grooved copies.")
                            .font(Bloom.Typeface.micro)
                            .foregroundStyle(Bloom.Pigment.muted)
                            .lineLimit(2)
                        Spacer(minLength: 0)
                        Button("Retract") { chrome.confirmRetract = true }
                            .buttonStyle(NeedlePress(kind: .destructive, isLoading: chrome.busyRetract))
                            .frame(width: Bloom.Rhythm.steps(16))
                            .disabled(chrome.busyRetract || chrome.store.plays(for: pressing.id) == 0)
                    }
                } else {
                    Text("Mint until you Drop. Grade waits.")
                        .font(Bloom.Typeface.caption)
                        .foregroundStyle(Bloom.Pigment.muted)
                }
            }
            .padding(Bloom.Rhythm.steps(2))
            .frame(maxWidth: .infinity, alignment: .leading)
            .bloomCard()
        }
    }

    private var gradeRow: some View {
        HStack(spacing: Bloom.Rhythm.steps(1)) {
            ForEach(1 ... 5, id: \.self) { pip in
                Button(PhonographFigures.whole(pip)) {
                    noteFocused = false
                    Task { await chrome.gradeFocused(pip) }
                }
                .buttonStyle(GrooveChipPress(selected: chrome.focused.flatMap { chrome.document.grades[$0.id] } == pip))
                .frame(maxWidth: .infinity)
                .disabled(chrome.busyGrade)
                .accessibilityLabel("Grade \(PhonographFigures.whole(pip))")
            }
        }
    }

    private var dropControl: some View {
        Button {
            noteFocused = false
            Task { await chrome.dropFocused(reduceMotion: reduceMotion) }
        } label: {
            HStack(spacing: Bloom.Rhythm.steps(2)) {
                Image("dwx_ControlFace")
                    .resizable()
                    .scaledToFit()
                    .frame(width: Bloom.Rhythm.steps(5), height: Bloom.Rhythm.steps(5))
                    .accessibilityHidden(true)
                Text("Drop")
            }
        }
        .buttonStyle(NeedlePress(kind: .primary, isLoading: chrome.busyDrop))
        .disabled(!chrome.dropEnabled)
        .accessibilityLabel("Drop the needle")
        .accessibilityHint("Records a play on the focused sleeve")
    }
}
