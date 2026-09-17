import SwiftUI

/// Role: Wall-segment chrome. The sleeve wall never leaves. Discover, Crate, Heard, and Taste are segments of the same wall.
struct WallShell: View {
    @EnvironmentObject private var chrome: WallChrome

    var body: some View {
        VStack(spacing: 0) {
            segmentBody
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            WallSegmentRail(segment: $chrome.segment)
        }
        .background(Bloom.Pigment.background.ignoresSafeArea())
        .fullScreenCover(isPresented: $chrome.showingSearch) {
            CatalogSeek()
                .environmentObject(chrome)
        }
        .fullScreenCover(isPresented: $chrome.showingScan) {
            SleeveScan()
                .environmentObject(chrome)
        }
        .fullScreenCover(isPresented: $chrome.showingTwist) {
            GrooveFlip()
        }
        .sheet(isPresented: $chrome.showingSettings) {
            WallSettings()
                .environmentObject(chrome)
                .presentationDetents([.large])
        }
        .confirmationDialog(
            "Retract the last play?",
            isPresented: $chrome.confirmRetract,
            titleVisibility: .visible
        ) {
            Button("Retract last play", role: .destructive) {
                Task { await chrome.peelFocused() }
            }
            Button("Keep the play", role: .cancel) {}
        } message: {
            Text(retractCopy)
        }
    }

    @ViewBuilder
    private var segmentBody: some View {
        switch chrome.segment {
        case .discover:
            DiscoverWall()
        case .crate:
            CrateFold()
        case .heard:
            SeenWalk()
        case .taste:
            TasteProfile()
        }
    }

    private var retractCopy: String {
        if let title = chrome.focused?.title {
            return "Retract the last GrooveMark on \(title)? At zero plays this sleeve returns to Mint."
        }
        return "Retract the last GrooveMark? At zero plays this sleeve returns to Mint."
    }
}

struct WallSegmentRail: View {
    @Binding var segment: WallSegment
    @ScaledMetric(relativeTo: .caption) private var railHit = Bloom.Rhythm.steps(7)

    private let items: [(WallSegment, String, String)] = [
        (.discover, "Discover", "square.grid.2x2"),
        (.crate, "Crate", "square.stack"),
        (.heard, "Heard", "waveform"),
        (.taste, "Taste", "chart.bar"),
    ]

    var body: some View {
        HStack(spacing: Bloom.Rhythm.steps(1)) {
            ForEach(items, id: \.0) { item in
                Button {
                    withAnimation(Bloom.Motion.travel) {
                        segment = item.0
                    }
                } label: {
                    VStack(spacing: Bloom.Rhythm.unit) {
                        Image(systemName: item.2)
                            .font(Bloom.Typeface.caption)
                        Text(item.1)
                            .font(Bloom.Typeface.micro)
                    }
                    .foregroundStyle(segment == item.0 ? Bloom.Pigment.surface : Bloom.Pigment.ink)
                    .frame(maxWidth: .infinity, minHeight: railHit)
                    .background(segment == item.0 ? Bloom.Pigment.accent : Bloom.Pigment.surface)
                    .clipShape(RoundedRectangle(cornerRadius: Bloom.Bend.chip, style: .continuous))
                    .contentShape(Rectangle())
                }
                .buttonStyle(TilePress())
                .accessibilityLabel(item.1)
                .accessibilityAddTraits(segment == item.0 ? .isSelected : [])
            }
        }
        .padding(.horizontal, Bloom.Rhythm.steps(2))
        .padding(.top, Bloom.Rhythm.steps(1))
        .padding(.bottom, Bloom.Rhythm.steps(1))
        .background(Bloom.Pigment.surface.ignoresSafeArea(edges: .bottom))
        .bloomLift()
    }
}
