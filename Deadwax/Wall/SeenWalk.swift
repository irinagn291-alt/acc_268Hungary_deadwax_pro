import SwiftUI

/// Role: Seen segment. Heard walk of Grooved pressings in GrooveMark play order.
struct SeenWalk: View {
    @EnvironmentObject private var chrome: WallChrome
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        Group {
            if steps.isEmpty {
                EmptySleevePage(
                    art: "dwx_EmptyList",
                    headline: "Nothing heard yet.",
                    line: "Drop the needle on a sleeve first.",
                    cta: "Open the wall"
                ) {
                    chrome.segment = .discover
                }
            } else {
                populated
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Bloom.Pigment.background.ignoresSafeArea())
    }

    private var steps: [HeardStep] {
        chrome.document.marks.compactMap { mark in
            guard let pressing = chrome.document.pressings.first(where: { $0.id == mark.pressingId && $0.groove == .grooved }) else {
                return nil
            }
            return HeardStep(mark: mark, pressing: pressing)
        }
    }

    private var populated: some View {
        VStack(alignment: .leading, spacing: Bloom.Rhythm.steps(2)) {
            Text("Heard in play order.")
                .font(Bloom.Typeface.title)
                .foregroundStyle(Bloom.Pigment.ink)
            Text("Each row is one Drop, newest last.")
                .font(Bloom.Typeface.body)
                .foregroundStyle(Bloom.Pigment.muted)
            if let fault = chrome.faultCopy {
                WallFaultBanner(copy: fault) {
                    chrome.faultCopy = nil
                }
            }
            walk
        }
        .padding(.horizontal, Bloom.Rhythm.steps(2))
        .padding(.top, Bloom.Rhythm.steps(2))
        .padding(.bottom, Bloom.Rhythm.steps(1))
    }

    @ViewBuilder
    private var walk: some View {
        if sizeClass == .regular {
            GeometryReader { geo in
                padWalk(in: geo.size)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: Bloom.Rhythm.steps(2)) {
                    ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                        stepButton(step: step, sleeve: index.isMultiple(of: 3) ? 112 : 88, fill: false)
                    }
                }
                .padding(.bottom, Bloom.Rhythm.steps(2))
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }

    private func padWalk(in size: CGSize) -> some View {
        let gap = Bloom.Rhythm.steps(2)
        let columns = 2
        let rowCount = max((steps.count + columns - 1) / columns, 1)
        let gapsY = gap * CGFloat(max(rowCount - 1, 0))
        let minRow = Bloom.Rhythm.steps(18)
        let filled = (size.height - gapsY) / CGFloat(rowCount)
        let overflowing = filled < minRow
        let rowH = overflowing ? minRow : max(filled, minRow)
        let sleeve = min(max(rowH - Bloom.Rhythm.steps(4), Bloom.Rhythm.steps(14)), Bloom.Rhythm.steps(28))

        let rows = VStack(spacing: gap) {
            ForEach(0 ..< rowCount, id: \.self) { row in
                HStack(alignment: .top, spacing: gap) {
                    ForEach(0 ..< columns, id: \.self) { column in
                        let index = row * columns + column
                        if steps.indices.contains(index) {
                            stepButton(step: steps[index], sleeve: sleeve, fill: overflowing == false)
                                .frame(maxWidth: .infinity, maxHeight: overflowing ? rowH : .infinity)
                        }
                    }
                }
                .frame(maxHeight: overflowing ? rowH : .infinity)
            }
        }

        return Group {
            if overflowing {
                ScrollView {
                    rows
                }
            } else {
                rows
                    .frame(width: size.width, height: size.height, alignment: .top)
            }
        }
    }

    private func stepButton(step: HeardStep, sleeve: CGFloat, fill: Bool) -> some View {
        Button {
            chrome.focus(step.pressing)
            chrome.segment = .discover
        } label: {
            heardRow(step: step, sleeve: sleeve, fill: fill)
        }
        .buttonStyle(TilePress())
    }

    private func heardRow(step: HeardStep, sleeve: CGFloat, fill: Bool) -> some View {
        HStack(alignment: .center, spacing: Bloom.Rhythm.steps(2)) {
            SleeveFront(urlString: step.pressing.sleeveFrontURL, corner: Bloom.Bend.card)
                .frame(width: sleeve, height: sleeve)
            VStack(alignment: .leading, spacing: Bloom.Rhythm.unit) {
                Text(step.pressing.artist)
                    .font(Bloom.Typeface.caption)
                    .foregroundStyle(Bloom.Pigment.muted)
                    .lineLimit(1)
                Text(step.pressing.title)
                    .font(Bloom.Typeface.headline)
                    .foregroundStyle(Bloom.Pigment.ink)
                    .lineLimit(2)
                GroovePip(plays: chrome.store.plays(for: step.pressing.id), prominent: sleeve >= Bloom.Rhythm.steps(16))
                Text(WallDayFace.phrase(step.mark.dayKey))
                    .font(Bloom.Typeface.micro)
                    .foregroundStyle(Bloom.Pigment.muted)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(Bloom.Rhythm.steps(2))
        .frame(
            maxWidth: .infinity,
            minHeight: fill ? nil : max(sleeve + Bloom.Rhythm.steps(4), Bloom.Rhythm.steps(12)),
            maxHeight: fill ? .infinity : nil,
            alignment: .leading
        )
        .bloomCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(step.pressing.artist), \(step.pressing.title), \(WallDayFace.phrase(step.mark.dayKey))")
    }
}

struct HeardStep: Identifiable {
    let mark: GrooveMark
    let pressing: Pressing
    var id: UUID { mark.id }
}

enum WallDayFace {
    static func phrase(_ key: Int) -> String {
        let year = key / 10_000
        let month = (key / 100) % 100
        let day = key % 100
        var parts = DateComponents()
        parts.year = year
        parts.month = month
        parts.day = day
        guard let date = Calendar.current.date(from: parts) else {
            return PhonographFigures.whole(key)
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
