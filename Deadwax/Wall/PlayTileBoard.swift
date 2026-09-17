import SwiftUI

/// Role: Mixed-size play tiles that fill remaining height and iPad width. Dead placeholder cells are forbidden.
enum PlayTileMath {
    static func frames(count: Int, in size: CGSize) -> [CGRect] {
        guard count > 0, size.width > 1, size.height > 1 else { return [] }
        let gap = Bloom.Rhythm.steps(1)
        let wide = size.width >= 700
        switch count {
        case 1:
            return [CGRect(origin: .zero, size: size)]
        case 2:
            let lead = (size.width - gap) * (wide ? 0.62 : 0.58)
            return [
                CGRect(x: 0, y: 0, width: lead, height: size.height),
                CGRect(x: lead + gap, y: 0, width: size.width - lead - gap, height: size.height),
            ]
        case 3:
            return three(size: size, gap: gap, wide: wide)
        case 4:
            return four(size: size, gap: gap, wide: wide)
        case 5:
            return five(size: size, gap: gap, wide: wide)
        default:
            return sixPlus(count: count, size: size, gap: gap, wide: wide)
        }
    }

    private static func three(size: CGSize, gap: CGFloat, wide: Bool) -> [CGRect] {
        let lead = (size.width - gap) * (wide ? 0.6 : 0.56)
        let right = size.width - lead - gap
        let top = (size.height - gap) * (wide ? 0.62 : 0.58)
        return [
            CGRect(x: 0, y: 0, width: lead, height: size.height),
            CGRect(x: lead + gap, y: 0, width: right, height: top),
            CGRect(x: lead + gap, y: top + gap, width: right, height: size.height - top - gap),
        ]
    }

    private static func four(size: CGSize, gap: CGFloat, wide: Bool) -> [CGRect] {
        let lead = (size.width - gap) * (wide ? 0.52 : 0.54)
        let right = size.width - lead - gap
        let heroH = (size.height - gap) * (wide ? 0.58 : 0.54)
        let r1 = (heroH - gap) * (wide ? 0.62 : 0.58)
        let bottomH = size.height - heroH - gap
        return [
            CGRect(x: 0, y: 0, width: lead, height: heroH),
            CGRect(x: lead + gap, y: 0, width: right, height: r1),
            CGRect(x: lead + gap, y: r1 + gap, width: right, height: heroH - r1 - gap),
            CGRect(x: 0, y: heroH + gap, width: size.width, height: bottomH),
        ]
    }

    private static func five(size: CGSize, gap: CGFloat, wide: Bool) -> [CGRect] {
        var frames = four(size: size, gap: gap, wide: wide)
        let last = frames.removeLast()
        let split = (last.width - gap) * (wide ? 0.62 : 0.58)
        frames.append(CGRect(x: last.minX, y: last.minY, width: split, height: last.height))
        frames.append(CGRect(x: last.minX + split + gap, y: last.minY, width: last.width - split - gap, height: last.height))
        return frames
    }

    private static func sixPlus(count: Int, size: CGSize, gap: CGFloat, wide: Bool) -> [CGRect] {
        let heroW = (size.width - gap) * (wide ? 0.5 : 0.58)
        let heroH = (size.height - gap) * (wide ? 0.56 : 0.5)
        let rightW = size.width - heroW - gap
        let r1 = (heroH - gap) * (wide ? 0.62 : 0.58)
        var frames: [CGRect] = [
            CGRect(x: 0, y: 0, width: heroW, height: heroH),
            CGRect(x: heroW + gap, y: 0, width: rightW, height: r1),
            CGRect(x: heroW + gap, y: r1 + gap, width: rightW, height: heroH - r1 - gap),
        ]
        let leftover = max(count - 3, 0)
        guard leftover > 0 else { return Array(frames.prefix(count)) }
        let bottomY = heroH + gap
        let bottomH = size.height - heroH - gap
        frames.append(contentsOf: mixedBottom(count: leftover, width: size.width, y: bottomY, height: bottomH, gap: gap, wide: wide))
        if frames.count > count {
            return Array(frames.prefix(count))
        }
        return frames
    }

    /// Bottom band of a six-plus wall. Never three equal-weight tiles.
    private static func mixedBottom(
        count: Int,
        width: CGFloat,
        y: CGFloat,
        height: CGFloat,
        gap: CGFloat,
        wide: Bool
    ) -> [CGRect] {
        switch count {
        case 1:
            return [CGRect(x: 0, y: y, width: width, height: height)]
        case 2:
            let lead = (width - gap) * (wide ? 0.62 : 0.58)
            return [
                CGRect(x: 0, y: y, width: lead, height: height),
                CGRect(x: lead + gap, y: y, width: width - lead - gap, height: height),
            ]
        case 3:
            let lead = (width - gap) * (wide ? 0.54 : 0.56)
            let right = width - lead - gap
            let top = (height - gap) * (wide ? 0.62 : 0.58)
            return [
                CGRect(x: 0, y: y, width: lead, height: height),
                CGRect(x: lead + gap, y: y, width: right, height: top),
                CGRect(x: lead + gap, y: y + top + gap, width: right, height: height - top - gap),
            ]
        default:
            let row1 = (height - gap) * 0.58
            let topCount = (count + 1) / 2
            let botCount = count - topCount
            var result = unevenStrip(
                count: topCount,
                width: width,
                y: y,
                height: row1,
                gap: gap,
                leadShare: wide ? 0.58 : 0.56
            )
            result.append(contentsOf: unevenStrip(
                count: botCount,
                width: width,
                y: y + row1 + gap,
                height: height - row1 - gap,
                gap: gap,
                leadShare: wide ? 0.42 : 0.44
            ))
            return result
        }
    }

    private static func unevenStrip(
        count: Int,
        width: CGFloat,
        y: CGFloat,
        height: CGFloat,
        gap: CGFloat,
        leadShare: CGFloat
    ) -> [CGRect] {
        guard count > 0 else { return [] }
        if count == 1 {
            return [CGRect(x: 0, y: y, width: width, height: height)]
        }
        var shares: [CGFloat] = []
        var remain: CGFloat = 1
        for index in 0 ..< count {
            if index == count - 1 {
                shares.append(remain)
            } else {
                let take = remain * (index == 0 ? leadShare : 0.55)
                shares.append(take)
                remain -= take
            }
        }
        let usable = width - gap * CGFloat(count - 1)
        var x: CGFloat = 0
        var frames: [CGRect] = []
        for (index, share) in shares.enumerated() {
            let tileW = index == count - 1 ? (width - x) : usable * share
            frames.append(CGRect(x: x, y: y, width: max(tileW, 44), height: height))
            x += tileW + gap
        }
        return frames
    }
}

struct PlayTileBoard: View {
    let pressings: [Pressing]
    let focused: UUID?
    let pulse: Bool
    let plays: (UUID) -> Int
    let grade: (UUID) -> Int?
    let onPick: (Pressing) -> Void

    var body: some View {
        GeometryReader { geo in
            let frames = PlayTileMath.frames(count: pressings.count, in: geo.size)
            ZStack(alignment: .topLeading) {
                ForEach(Array(pressings.enumerated()), id: \.element.id) { index, pressing in
                    if frames.indices.contains(index) {
                        let frame = frames[index]
                        Button {
                            onPick(pressing)
                        } label: {
                            SleeveTile(
                                pressing: pressing,
                                plays: plays(pressing.id),
                                grade: grade(pressing.id),
                                focused: pressing.id == focused,
                                pulse: pulse,
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
}
