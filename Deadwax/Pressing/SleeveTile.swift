import SwiftUI

/// Role: One mixed-size play tile on the sleeve wall. Square sleeve plus a reserved caption so artist, title, and plays stay on the canvas.
struct SleeveTile: View {
    let pressing: Pressing
    let plays: Int
    let grade: Int?
    let focused: Bool
    let pulse: Bool
    var prominent: Bool = false
    @ScaledMetric(relativeTo: .body) private var captionBlock = Bloom.Rhythm.steps(10)

    var body: some View {
        GeometryReader { geo in
            laidOut(in: geo.size)
        }
        .background(Bloom.Pigment.surface)
        .clipShape(RoundedRectangle(cornerRadius: Bloom.Bend.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Bloom.Bend.card, style: .continuous)
                .stroke(focused ? Bloom.Pigment.accent : Bloom.Pigment.muted.opacity(0.25), lineWidth: focused ? 3 : 1)
        )
        .bloomLift()
        .scaleEffect(pulse && focused ? 1.03 : 1)
        .contentShape(RoundedRectangle(cornerRadius: Bloom.Bend.card, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(voice)
        .accessibilityHint("Selects this sleeve for Drop")
        .accessibilityAddTraits(.isButton)
    }

    @ViewBuilder
    private func laidOut(in size: CGSize) -> some View {
        let pad = Bloom.Rhythm.steps(1)
        let gap = Bloom.Rhythm.steps(1)
        let innerW = max(size.width - pad * 2, 1)
        let innerH = max(size.height - pad * 2, 1)
        let compact = innerW < Bloom.Rhythm.steps(20)
        let minArt = Bloom.Rhythm.steps(8)
        let wantedCaption = max(captionBlock, compact ? Bloom.Rhythm.steps(12) : Bloom.Rhythm.steps(10))
        let canStack = innerH >= minArt + wantedCaption + gap
        let rowArt = min(innerH, innerW * 0.52)
        let canRow = innerW >= innerH * 1.25 && innerW - rowArt - gap >= Bloom.Rhythm.steps(12)

        if canRow {
            rowFace(size: size, art: rowArt, pad: pad, gap: gap, compact: compact)
        } else if canStack {
            stackFace(size: size, innerW: innerW, innerH: innerH, pad: pad, gap: gap, minArt: minArt, wantedCaption: wantedCaption, compact: compact)
        } else {
            overlayFace(size: size, innerW: innerW, innerH: innerH, pad: pad, wantedCaption: wantedCaption)
        }
    }

    private func rowFace(size: CGSize, art: CGFloat, pad: CGFloat, gap: CGFloat, compact: Bool) -> some View {
        HStack(alignment: .center, spacing: gap) {
            sleeve(art: art)
            meta(compact: compact)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .padding(pad)
        .frame(width: size.width, height: size.height, alignment: .leading)
    }

    private func stackFace(
        size: CGSize,
        innerW: CGFloat,
        innerH: CGFloat,
        pad: CGFloat,
        gap: CGFloat,
        minArt: CGFloat,
        wantedCaption: CGFloat,
        compact: Bool
    ) -> some View {
        let captionH = min(wantedCaption, max(Bloom.Rhythm.steps(8), innerH - minArt - gap))
        let art = min(innerW, max(minArt, innerH - captionH - gap))
        return VStack(alignment: .leading, spacing: gap) {
            sleeve(art: art)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            meta(compact: compact)
                .frame(maxWidth: .infinity, minHeight: captionH, alignment: .topLeading)
                .layoutPriority(1)
        }
        .padding(pad)
        .frame(width: size.width, height: size.height, alignment: .topLeading)
    }

    private func overlayFace(size: CGSize, innerW: CGFloat, innerH: CGFloat, pad: CGFloat, wantedCaption: CGFloat) -> some View {
        let captionH = min(wantedCaption, innerH * 0.46)
        let art = min(innerW, innerH)
        return ZStack(alignment: .bottom) {
            sleeve(art: art)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(pad)
            meta(compact: true)
                .padding(.horizontal, pad)
                .padding(.vertical, Bloom.Rhythm.unit)
                .frame(maxWidth: .infinity, minHeight: captionH, alignment: .leading)
                .background(Bloom.Pigment.surface)
        }
        .frame(width: size.width, height: size.height)
        .clipped()
    }

    private func sleeve(art: CGFloat) -> some View {
        ZStack(alignment: .topTrailing) {
            SleeveFront(urlString: pressing.sleeveFrontURL, corner: Bloom.Bend.chip)
            grooveBadge
                .padding(Bloom.Rhythm.unit)
        }
        .frame(width: art, height: art)
    }

    private func meta(compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: Bloom.Rhythm.unit) {
            Text(pressing.artist)
                .font(Bloom.Typeface.caption)
                .foregroundStyle(Bloom.Pigment.muted)
                .lineLimit(compact ? 2 : 1)
            Text(pressing.title)
                .font(prominent && compact == false ? Bloom.Typeface.headline : Bloom.Typeface.body)
                .foregroundStyle(Bloom.Pigment.ink)
                .lineLimit(2)
            if pressing.groove == .grooved {
                GroovePip(plays: plays, prominent: prominent && compact == false)
                if let grade {
                    Text("Grade \(PhonographFigures.whole(grade))")
                        .font(Bloom.Typeface.micro)
                        .foregroundStyle(Bloom.Pigment.ink)
                        .lineLimit(1)
                }
            } else {
                Text("Mint")
                    .font(Bloom.Typeface.micro)
                    .foregroundStyle(Bloom.Pigment.muted)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var voice: String {
        var parts = [pressing.artist, pressing.title]
        parts.append(pressing.groove == .mint ? "Mint" : "Grooved")
        if pressing.groove == .grooved {
            parts.append("\(PhonographFigures.whole(plays)) plays")
        }
        return parts.joined(separator: ", ")
    }

    private var grooveBadge: some View {
        Text(pressing.groove == .mint ? "Mint" : "Grooved")
            .font(Bloom.Typeface.micro)
            .foregroundStyle(pressing.groove == .grooved ? Bloom.Pigment.surface : Bloom.Pigment.ink)
            .lineLimit(1)
            .padding(.horizontal, Bloom.Rhythm.unit)
            .padding(.vertical, Bloom.Rhythm.unit)
            .frame(minHeight: Bloom.Rhythm.steps(4))
            .background(pressing.groove == .grooved ? Bloom.Pigment.accent : Bloom.Pigment.surface.opacity(0.92))
            .clipShape(RoundedRectangle(cornerRadius: Bloom.Bend.chip, style: .continuous))
            .layoutPriority(1)
    }
}

struct GroovePip: View {
    let plays: Int
    var prominent: Bool = false

    var body: some View {
        HStack(spacing: Bloom.Rhythm.unit) {
            Circle()
                .fill(Bloom.Pigment.accent)
                .frame(width: Bloom.Rhythm.steps(1), height: Bloom.Rhythm.steps(1))
            Text(PhonographFigures.whole(plays))
                .font(prominent ? Bloom.Typeface.display : Bloom.Typeface.body)
                .foregroundStyle(Bloom.Pigment.ink)
                .monospacedDigit()
                .lineLimit(1)
                .layoutPriority(1)
            Text(plays == 1 ? "play" : "plays")
                .font(Bloom.Typeface.micro)
                .foregroundStyle(Bloom.Pigment.muted)
                .lineLimit(1)
                .layoutPriority(1)
        }
        .accessibilityElement(children: .combine)
    }
}

/// Role: Path flourish for the Discover wall only. Concentric grooves behind the play tiles.
struct GrooveRings: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.width * 0.18, y: rect.height * 0.78)
        let maxR = min(rect.width, rect.height) * 0.62
        for step in 1 ... 7 {
            let radius = maxR * CGFloat(step) / 7
            path.addEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
        }
        return path
    }
}
