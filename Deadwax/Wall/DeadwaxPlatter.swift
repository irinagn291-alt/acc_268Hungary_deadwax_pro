import SwiftUI

/// Role: The quiet ring outside the label. Decorative on tiles; the reader explains it in text.
struct DeadwaxBead: View {
    var span: CGFloat = Bloom.Rhythm.steps(3)

    var body: some View {
        ZStack {
            Circle()
                .stroke(Bloom.Pigment.accent, lineWidth: max(2, span * 0.12))
            Circle()
                .fill(Bloom.Pigment.accent)
                .padding(span * 0.28)
        }
        .frame(width: span, height: span)
        .background(Bloom.Pigment.surface.opacity(0.92))
        .clipShape(Circle())
        .accessibilityHidden(true)
    }
}

/// Role: Entry fused on a Grooved sleeve. Opens the runout reader. Mint does not show it.
struct DeadwaxEntry: View {
    @EnvironmentObject private var chrome: WallChrome

    var body: some View {
        let summary = RunoutMath.summary(of: rows)
        Button {
            chrome.openDeadwax()
        } label: {
            HStack(spacing: Bloom.Rhythm.steps(1)) {
                DeadwaxBead(span: Bloom.Rhythm.steps(3))
                VStack(alignment: .leading, spacing: Bloom.Rhythm.unit) {
                    Text(summary.isEmpty ? "Read the deadwax" : "Deadwax")
                        .font(Bloom.Typeface.caption)
                        .foregroundStyle(Bloom.Pigment.ink)
                        .lineLimit(1)
                    Text(summary.isEmpty ? "The quiet ring outside the label." : summary)
                        .font(Bloom.Typeface.micro)
                        .foregroundStyle(Bloom.Pigment.muted)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, Bloom.Rhythm.unit)
            .frame(maxWidth: .infinity, minHeight: Bloom.Rhythm.steps(6), alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(TilePress())
        .accessibilityLabel(summary.isEmpty ? "Read the deadwax" : "Deadwax, \(summary)")
        .accessibilityHint("Opens the runout for this copy")
    }

    private var rows: [RunoutEtching] {
        guard let id = chrome.focusedID else { return [] }
        return chrome.document.runouts[id] ?? []
    }
}

/// Role: Cover over the wall for one Grooved copy. Each side keeps its own runout. Dismisses back to the sleeve.
struct DeadwaxReader: View {
    @EnvironmentObject private var chrome: WallChrome
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if let pressing = chrome.focused, pressing.groove == .grooved {
                reader(pressing)
            } else {
                Bloom.Pigment.background
                    .ignoresSafeArea()
                    .onAppear { chrome.showingDeadwax = false }
            }
        }
    }

    private func reader(_ pressing: Pressing) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Bloom.Rhythm.steps(2)) {
                header(pressing)
                Text("The quiet ring between the last groove and the label.")
                    .font(Bloom.Typeface.body)
                    .foregroundStyle(Bloom.Pigment.muted)
                    .fixedSize(horizontal: false, vertical: true)
                PlatterDisc(live: !reduceMotion)
                    .frame(width: Bloom.Rhythm.steps(22), height: Bloom.Rhythm.steps(22))
                    .frame(maxWidth: .infinity)
                Text("That ring is the deadwax.")
                    .font(Bloom.Typeface.caption)
                    .foregroundStyle(Bloom.Pigment.ink)
                    .frame(maxWidth: .infinity, alignment: .center)
                VStack(spacing: Bloom.Rhythm.steps(1)) {
                    ForEach(PlatterSide.allCases, id: \.self) { side in
                        sideRow(side)
                    }
                }
                readingLine
                Text("Etch a mark into side \(chrome.platterSide.title).")
                    .font(Bloom.Typeface.micro)
                    .foregroundStyle(Bloom.Pigment.muted)
                    .lineLimit(2)
                plantRail
            }
            .padding(.horizontal, Bloom.Rhythm.steps(3))
            .padding(.bottom, Bloom.Rhythm.steps(4))
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        .contentMargins(.bottom, Bloom.Rhythm.steps(4), for: .scrollContent)
        .background(Bloom.Pigment.background.ignoresSafeArea())
    }

    private func header(_ pressing: Pressing) -> some View {
        HStack(alignment: .top, spacing: Bloom.Rhythm.steps(1)) {
            VStack(alignment: .leading, spacing: Bloom.Rhythm.unit) {
                Text("Deadwax")
                    .font(Bloom.Typeface.display)
                    .foregroundStyle(Bloom.Pigment.ink)
                    .lineLimit(1)
                Text(pressing.artist)
                    .font(Bloom.Typeface.caption)
                    .foregroundStyle(Bloom.Pigment.muted)
                    .lineLimit(1)
                Text(pressing.title)
                    .font(Bloom.Typeface.headline)
                    .foregroundStyle(Bloom.Pigment.ink)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            BloomIcon(symbol: "xmark", label: "Close") {
                chrome.showingDeadwax = false
            }
        }
    }

    private func sideRow(_ side: PlatterSide) -> some View {
        HStack(spacing: Bloom.Rhythm.steps(1)) {
            Button(side.title) {
                chrome.selectSide(side)
            }
            .buttonStyle(GrooveChipPress(selected: chrome.platterSide == side))
            .accessibilityLabel("Side \(side.title)")
            TextField("Side \(side.title) runout", text: runoutBinding(side))
                .font(Bloom.Typeface.body)
                .foregroundStyle(Bloom.Pigment.ink)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .padding(.horizontal, Bloom.Rhythm.steps(2))
                .frame(minHeight: Bloom.Rhythm.steps(6))
                .background(Bloom.Pigment.surface)
                .clipShape(RoundedRectangle(cornerRadius: Bloom.Bend.card, style: .continuous))
                .accessibilityLabel("Side \(side.title) runout")
                .accessibilityHint("What is etched between the last groove and the label")
        }
    }

    @ViewBuilder
    private var readingLine: some View {
        let reading = RunoutMath.reading(of: chrome.fuseRunout)
        if !reading.isEmpty {
            Text(reading)
                .font(Bloom.Typeface.caption)
                .foregroundStyle(Bloom.Pigment.ink)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var plantRail: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Bloom.Rhythm.steps(1)) {
                ForEach(RunoutMath.plants, id: \.self) { plant in
                    Button {
                        chrome.stampPlant(plant)
                    } label: {
                        Text(plant)
                            .lineLimit(1)
                    }
                    .buttonStyle(GrooveChipPress(selected: RunoutScript.contains(chrome.fuseRunout, plant: plant)))
                    .accessibilityHint("Etches this mark into side \(chrome.platterSide.title)")
                }
            }
            .padding(.vertical, Bloom.Rhythm.unit)
        }
    }

    private func runoutBinding(_ side: PlatterSide) -> Binding<String> {
        Binding(
            get: {
                guard let id = chrome.focusedID else { return "" }
                if chrome.platterSide == side {
                    return chrome.fuseRunout
                }
                return chrome.document.inscription(for: id, side: side)
            },
            set: { text in
                if chrome.platterSide != side {
                    chrome.selectSide(side)
                }
                chrome.editRunout(text)
            }
        )
    }
}

/// Role: Spinning platter for the runout reader. Reduce Motion holds the ring still.
private struct PlatterDisc: View {
    var live: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !live)) { timeline in
            PlatterFace()
                .rotationEffect(.degrees(angle(at: timeline.date)))
        }
        .accessibilityHidden(true)
    }

    private func angle(at date: Date) -> Double {
        guard live else { return 18 }
        let period = 2.8
        let seconds = date.timeIntervalSinceReferenceDate
        return seconds.truncatingRemainder(dividingBy: period) / period * 360
    }
}

/// Role: Grooves, the deadwax ring, and the label. The accent band is the quiet ring.
private struct PlatterFace: View {
    var body: some View {
        Canvas { context, size in
            let side = min(size.width, size.height)
            let origin = CGPoint(x: (size.width - side) / 2, y: (size.height - side) / 2)
            let center = CGPoint(x: origin.x + side / 2, y: origin.y + side / 2)
            let radius = side / 2
            let disc = CGRect(x: origin.x, y: origin.y, width: side, height: side)
            context.fill(Path(ellipseIn: disc), with: .color(Bloom.Pigment.ink))

            for step in 0 ..< 6 {
                let reach = radius * (0.48 + CGFloat(step) * 0.07)
                let rect = CGRect(x: center.x - reach, y: center.y - reach, width: reach * 2, height: reach * 2)
                context.stroke(
                    Path(ellipseIn: rect),
                    with: .color(Bloom.Pigment.surface.opacity(0.28)),
                    lineWidth: 1
                )
            }

            let outer = radius * 0.42
            let inner = radius * 0.34
            strokeRing(context: &context, center: center, radius: outer, width: max(4, side * 0.045), opacity: 1)
            strokeRing(context: &context, center: center, radius: inner, width: max(2, side * 0.02), opacity: 0.55)

            var tick = Path()
            tick.move(to: CGPoint(x: center.x, y: center.y - outer))
            tick.addLine(to: CGPoint(x: center.x, y: center.y - inner))
            context.stroke(
                tick,
                with: .color(Bloom.Pigment.surface),
                style: StrokeStyle(lineWidth: max(2, side * 0.015), lineCap: .round)
            )

            let label = radius * 0.26
            let labelRect = CGRect(x: center.x - label, y: center.y - label, width: label * 2, height: label * 2)
            context.fill(Path(ellipseIn: labelRect), with: .color(Bloom.Pigment.accent))

            let spindle = max(3, radius * 0.045)
            let spindleRect = CGRect(
                x: center.x - spindle,
                y: center.y - spindle,
                width: spindle * 2,
                height: spindle * 2
            )
            context.fill(Path(ellipseIn: spindleRect), with: .color(Bloom.Pigment.ink))
        }
    }

    private func strokeRing(
        context: inout GraphicsContext,
        center: CGPoint,
        radius: CGFloat,
        width: CGFloat,
        opacity: Double
    ) {
        let rect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
        context.stroke(
            Path(ellipseIn: rect),
            with: .color(Bloom.Pigment.accent.opacity(opacity)),
            style: StrokeStyle(lineWidth: width, lineCap: .round)
        )
    }
}
