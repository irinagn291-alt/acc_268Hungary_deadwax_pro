import SwiftUI

/// Role: Profile segment. Taste folds Grooved grades by genre and label. Mint never enters.
struct TasteProfile: View {
    @EnvironmentObject private var chrome: WallChrome
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        Group {
            if chrome.store.tasteByGenre.isEmpty && chrome.store.tasteByLabel.isEmpty {
                EmptySleevePage(
                    art: "dwx_EmptyList",
                    headline: "Taste waits for Grooved grades.",
                    line: "Play a sleeve, then grade it.",
                    cta: "Drop on the wall"
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

    @ViewBuilder
    private var populated: some View {
        if sizeClass == .regular {
            padFold
        } else {
            phoneFold
        }
    }

    private var phoneFold: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Bloom.Rhythm.steps(2)) {
                hero
                faultBanner
                Text("By genre")
                    .font(Bloom.Typeface.headline)
                    .foregroundStyle(Bloom.Pigment.ink)
                phoneGenreStack
                Text("By label")
                    .font(Bloom.Typeface.headline)
                    .foregroundStyle(Bloom.Pigment.ink)
                labelStack
            }
            .padding(.horizontal, Bloom.Rhythm.steps(2))
            .padding(.top, Bloom.Rhythm.steps(2))
            .padding(.bottom, Bloom.Rhythm.steps(3))
        }
        .contentMargins(.bottom, Bloom.Rhythm.steps(10), for: .scrollContent)
        .scrollDismissesKeyboard(.interactively)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var padFold: some View {
        GeometryReader { geo in
            let labels = chrome.store.tasteByLabel.count
            let floor = Bloom.Rhythm.steps(18)
                + Bloom.Rhythm.steps(22)
                + CGFloat(labels) * Bloom.Rhythm.steps(10)
                + Bloom.Rhythm.steps(10)
            let overflowing = floor > geo.size.height
            let stack = VStack(alignment: .leading, spacing: Bloom.Rhythm.steps(2)) {
                hero
                faultBanner
                Text("By genre")
                    .font(Bloom.Typeface.headline)
                    .foregroundStyle(Bloom.Pigment.ink)
                padGenreBoard
                    .frame(minHeight: Bloom.Rhythm.steps(22))
                    .frame(maxWidth: .infinity, maxHeight: overflowing ? nil : .infinity)
                Text("By label")
                    .font(Bloom.Typeface.headline)
                    .foregroundStyle(Bloom.Pigment.ink)
                labelStack
            }
            .padding(.horizontal, Bloom.Rhythm.steps(2))
            .padding(.top, Bloom.Rhythm.steps(2))
            .padding(.bottom, Bloom.Rhythm.steps(2))
            Group {
                if overflowing {
                    ScrollView {
                        stack
                    }
                    .contentMargins(.bottom, Bloom.Rhythm.steps(8), for: .scrollContent)
                } else {
                    stack
                        .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var phoneGenreStack: some View {
        let folds = chrome.store.tasteByGenre
        return VStack(alignment: .leading, spacing: Bloom.Rhythm.steps(1)) {
            ForEach(Array(folds.enumerated()), id: \.element.id) { index, fold in
                phoneGenreRow(fold, lead: index == 0)
            }
        }
    }

    private var padGenreBoard: some View {
        GeometryReader { geo in
            let folds = chrome.store.tasteByGenre
            let frames = PlayTileMath.frames(count: folds.count, in: geo.size)
            ZStack(alignment: .topLeading) {
                ForEach(Array(folds.enumerated()), id: \.element.id) { index, fold in
                    if frames.indices.contains(index) {
                        let frame = frames[index]
                        Button {
                            openGenre(fold)
                        } label: {
                            TasteTile(
                                fold: fold,
                                copy: genreSleeves(fold).first,
                                prominent: index == 0
                            )
                        }
                        .buttonStyle(TilePress())
                        .frame(width: frame.width, height: frame.height)
                        .position(x: frame.midX, y: frame.midY)
                    }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    private func phoneGenreRow(_ fold: TasteFold, lead: Bool) -> some View {
        let copies = genreSleeves(fold)
        let sleeve = lead ? Bloom.Rhythm.steps(9) : Bloom.Rhythm.steps(7)
        return Button {
            openGenre(fold)
        } label: {
            HStack(spacing: Bloom.Rhythm.steps(2)) {
                if let copy = copies.first {
                    SleeveFront(urlString: copy.sleeveFrontURL, corner: Bloom.Bend.chip)
                        .frame(width: sleeve, height: sleeve)
                }
                VStack(alignment: .leading, spacing: Bloom.Rhythm.unit) {
                    Text(fold.bucket)
                        .font(lead ? Bloom.Typeface.title : Bloom.Typeface.headline)
                        .foregroundStyle(Bloom.Pigment.ink)
                        .lineLimit(1)
                    Text("\(BloomFigures.pips(fold.meanPips)) mean grade")
                        .font(Bloom.Typeface.body)
                        .foregroundStyle(Bloom.Pigment.ink)
                        .lineLimit(1)
                    Text("\(PhonographFigures.whole(fold.groovedCount)) Grooved, \(PhonographFigures.whole(fold.markCount)) plays")
                        .font(Bloom.Typeface.caption)
                        .foregroundStyle(Bloom.Pigment.muted)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                gradeShape(fold.meanPips, span: lead ? Bloom.Rhythm.steps(7) : Bloom.Rhythm.steps(6))
            }
            .padding(Bloom.Rhythm.steps(2))
            .frame(maxWidth: .infinity, minHeight: Bloom.Rhythm.steps(lead ? 11 : 9), alignment: .leading)
            .bloomCard()
            .contentShape(RoundedRectangle(cornerRadius: Bloom.Bend.card, style: .continuous))
        }
        .buttonStyle(TilePress())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(genreVoice(fold))
        .accessibilityHint("Opens this genre on the wall")
        .accessibilityAddTraits(.isButton)
    }

    private var labelStack: some View {
        VStack(alignment: .leading, spacing: Bloom.Rhythm.steps(1)) {
            ForEach(chrome.store.tasteByLabel) { fold in
                Button {
                    openLabel(fold)
                } label: {
                    HStack(spacing: Bloom.Rhythm.steps(2)) {
                        VStack(alignment: .leading, spacing: Bloom.Rhythm.unit) {
                            Text(fold.bucket)
                                .font(Bloom.Typeface.headline)
                                .foregroundStyle(Bloom.Pigment.ink)
                                .lineLimit(1)
                            Text("\(PhonographFigures.whole(fold.markCount)) plays")
                                .font(Bloom.Typeface.micro)
                                .foregroundStyle(Bloom.Pigment.muted)
                                .lineLimit(1)
                        }
                        Spacer(minLength: 0)
                        gradeShape(fold.meanPips, span: Bloom.Rhythm.steps(6))
                    }
                    .padding(Bloom.Rhythm.steps(2))
                    .frame(maxWidth: .infinity, minHeight: Bloom.Rhythm.steps(8), alignment: .leading)
                    .bloomCard()
                    .contentShape(RoundedRectangle(cornerRadius: Bloom.Bend.card, style: .continuous))
                }
                .buttonStyle(TilePress())
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(fold.bucket), mean grade \(BloomFigures.pips(fold.meanPips)), \(PhonographFigures.whole(fold.markCount)) plays")
                .accessibilityHint("Opens this label on the wall")
                .accessibilityAddTraits(.isButton)
            }
        }
    }

    @ViewBuilder
    private var faultBanner: some View {
        if let fault = chrome.faultCopy {
            WallFaultBanner(copy: fault) {
                chrome.faultCopy = nil
            }
        }
    }

    private var hero: some View {
        let art = sizeClass == .regular ? Bloom.Rhythm.steps(15) : Bloom.Rhythm.steps(10)
        return HStack(alignment: .center, spacing: Bloom.Rhythm.steps(2)) {
            VStack(alignment: .leading, spacing: Bloom.Rhythm.steps(1)) {
                Text("Taste from Grooved copies.")
                    .font(Bloom.Typeface.display)
                    .foregroundStyle(Bloom.Pigment.ink)
                    .lineLimit(3)
                HStack(spacing: Bloom.Rhythm.steps(1)) {
                    Circle()
                        .fill(Bloom.Pigment.accent)
                        .frame(width: Bloom.Rhythm.steps(2), height: Bloom.Rhythm.steps(2))
                    Text(PhonographFigures.whole(chrome.document.marks.count))
                        .font(Bloom.Typeface.title)
                        .foregroundStyle(Bloom.Pigment.ink)
                        .monospacedDigit()
                    Text("GrooveMarks")
                        .font(Bloom.Typeface.body)
                        .foregroundStyle(Bloom.Pigment.muted)
                        .lineLimit(1)
                }
                Text("\(PhonographFigures.whole(chrome.document.grades.count)) graded sleeves")
                    .font(Bloom.Typeface.caption)
                    .foregroundStyle(Bloom.Pigment.muted)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            Image("dwx_TwistHero")
                .resizable()
                .scaledToFit()
                .frame(width: art, height: art)
                .accessibilityHidden(true)
        }
        .padding(Bloom.Rhythm.steps(2))
        .frame(maxWidth: .infinity, alignment: .leading)
        .bloomCard()
    }

    private func gradeShape(_ mean: Double, span: CGFloat) -> some View {
        ZStack {
            Circle()
                .stroke(Bloom.Pigment.muted.opacity(0.35), lineWidth: 4)
            Circle()
                .trim(from: 0, to: CGFloat(min(max(mean / 5, 0), 1)))
                .stroke(Bloom.Pigment.accent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text(BloomFigures.pips(mean))
                .font(Bloom.Typeface.caption)
                .foregroundStyle(Bloom.Pigment.ink)
                .monospacedDigit()
                .lineLimit(1)
        }
        .frame(width: span, height: span)
        .accessibilityLabel("Mean grade \(BloomFigures.pips(mean))")
    }

    private func genreSleeves(_ fold: TasteFold) -> [Pressing] {
        grooved(matching: fold, key: \.genre)
    }

    private func labelSleeves(_ fold: TasteFold) -> [Pressing] {
        grooved(matching: fold, key: \.label)
    }

    private func grooved(matching fold: TasteFold, key: KeyPath<Pressing, String>) -> [Pressing] {
        chrome.document.pressings
            .filter { pressing in
                pressing.groove == .grooved
                    && chrome.document.grades[pressing.id] != nil
                    && pressing[keyPath: key] == fold.bucket
            }
            .sorted { chrome.store.plays(for: $0.id) > chrome.store.plays(for: $1.id) }
    }

    private func openGenre(_ fold: TasteFold) {
        if let pressing = genreSleeves(fold).first {
            chrome.focus(pressing)
            chrome.segment = .discover
        }
    }

    private func openLabel(_ fold: TasteFold) {
        if let pressing = labelSleeves(fold).first {
            chrome.focus(pressing)
            chrome.segment = .discover
        }
    }

    private func genreVoice(_ fold: TasteFold) -> String {
        "\(fold.bucket), mean grade \(BloomFigures.pips(fold.meanPips)), \(PhonographFigures.whole(fold.groovedCount)) Grooved"
    }
}

/// Role: One mixed-size Taste tile. Sleeve and grade fill the frame. Leftover white is forbidden.
private struct TasteTile: View {
    let fold: TasteFold
    let copy: Pressing?
    var prominent: Bool = false

    var body: some View {
        GeometryReader { geo in
            laidOut(in: geo.size)
        }
        .bloomCard()
        .contentShape(RoundedRectangle(cornerRadius: Bloom.Bend.card, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(fold.bucket), mean grade \(BloomFigures.pips(fold.meanPips))")
        .accessibilityHint("Opens this genre on the wall")
        .accessibilityAddTraits(.isButton)
    }

    @ViewBuilder
    private func laidOut(in size: CGSize) -> some View {
        let pad = Bloom.Rhythm.steps(2)
        let gap = Bloom.Rhythm.steps(1)
        let innerW = max(size.width - pad * 2, 1)
        let innerH = max(size.height - pad * 2, 1)
        let minArt = Bloom.Rhythm.steps(8)
        let rowArt = min(innerH, innerW * 0.48)
        let canRow = innerW >= innerH * 1.1 && innerW - rowArt - gap >= Bloom.Rhythm.steps(14)
        let caption = Bloom.Rhythm.steps(prominent ? 12 : 10)
        let canStack = innerH >= minArt + caption + gap

        Group {
            if canRow {
                HStack(alignment: .center, spacing: gap) {
                    sleeve(art: max(rowArt, minArt))
                    meta
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                }
            } else if canStack {
                let art = min(innerW, max(minArt, innerH - caption - gap))
                VStack(alignment: .leading, spacing: gap) {
                    sleeve(art: art)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                    meta
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                }
            } else {
                HStack(alignment: .center, spacing: gap) {
                    sleeve(art: min(innerH, Bloom.Rhythm.steps(8)))
                    meta
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(pad)
        .frame(width: size.width, height: size.height, alignment: .topLeading)
    }

    @ViewBuilder
    private func sleeve(art: CGFloat) -> some View {
        if let copy {
            SleeveFront(urlString: copy.sleeveFrontURL, corner: Bloom.Bend.chip)
                .frame(width: art, height: art)
        } else {
            gradeRing(span: art)
        }
    }

    private var meta: some View {
        VStack(alignment: .leading, spacing: Bloom.Rhythm.unit) {
            Text(fold.bucket)
                .font(prominent ? Bloom.Typeface.title : Bloom.Typeface.headline)
                .foregroundStyle(Bloom.Pigment.ink)
                .lineLimit(2)
            HStack(spacing: Bloom.Rhythm.steps(1)) {
                gradeRing(span: prominent ? Bloom.Rhythm.steps(7) : Bloom.Rhythm.steps(6))
                VStack(alignment: .leading, spacing: Bloom.Rhythm.unit) {
                    Text("\(BloomFigures.pips(fold.meanPips)) mean grade")
                        .font(Bloom.Typeface.body)
                        .foregroundStyle(Bloom.Pigment.ink)
                        .lineLimit(1)
                    Text("\(PhonographFigures.whole(fold.groovedCount)) Grooved, \(PhonographFigures.whole(fold.markCount)) plays")
                        .font(Bloom.Typeface.caption)
                        .foregroundStyle(Bloom.Pigment.muted)
                        .lineLimit(2)
                }
            }
            if let copy {
                Text(copy.artist)
                    .font(Bloom.Typeface.caption)
                    .foregroundStyle(Bloom.Pigment.muted)
                    .lineLimit(1)
                Text(copy.title)
                    .font(Bloom.Typeface.body)
                    .foregroundStyle(Bloom.Pigment.ink)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func gradeRing(span: CGFloat) -> some View {
        ZStack {
            Circle()
                .stroke(Bloom.Pigment.muted.opacity(0.35), lineWidth: 4)
            Circle()
                .trim(from: 0, to: CGFloat(min(max(fold.meanPips / 5, 0), 1)))
                .stroke(Bloom.Pigment.accent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text(BloomFigures.pips(fold.meanPips))
                .font(Bloom.Typeface.caption)
                .foregroundStyle(Bloom.Pigment.ink)
                .monospacedDigit()
                .lineLimit(1)
        }
        .frame(width: span, height: span)
    }
}
