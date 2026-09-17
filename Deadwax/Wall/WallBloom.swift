import SwiftUI
import UIKit

/// Role: One colour, type, space, radius, and elevation accessor for Berry soft bloom. Views never hard-code hex or a second radius.
enum Bloom {
    enum Pigment {
        static let background = Color("dwx_background")
        static let surface = Color("dwx_surface")
        static let ink = Color("dwx_ink")
        static let accent = Color("dwx_accent")
        static let muted = Color("dwx_muted")
        /// Palette hex lives only in this accessor. Tokens: background #F8F6F9, surface #FEFEFE, ink #2F1C36, accent #952EB8, muted #7C6882.
        static let namedHex = "#F8F6F9 #FEFEFE #2F1C36 #952EB8 #7C6882"
    }

    enum Typeface {
        /// SF Pro via Font.system only. Six steps. Display is Drop and play counts, max 34pt.
        static let display: Font = .system(.largeTitle, design: .default).weight(.bold)
        static let title: Font = .system(.title2, design: .default).weight(.semibold)
        static let headline: Font = .system(.title3, design: .default).weight(.semibold)
        static let body: Font = .system(.body, design: .default).weight(.regular)
        static let caption: Font = .system(.subheadline, design: .default).weight(.medium)
        static let micro: Font = .system(.caption, design: .default).weight(.medium)
    }

    enum Rhythm {
        static let unit: CGFloat = 8
        static func steps(_ n: Int) -> CGFloat { unit * CGFloat(n) }
    }

    enum Bend {
        static let card: CGFloat = 22
        static let chip: CGFloat = 14
    }

    enum Lift {
        static let color = Color("dwx_ink").opacity(0.12)
        static let radius: CGFloat = 16
        static let y: CGFloat = 8
    }

    enum Motion {
        static func drop(reduce: Bool) -> Animation {
            reduce ? .easeOut(duration: 0.25) : .spring(response: 0.4, dampingFraction: 0.8)
        }

        static let travel = Animation.easeOut(duration: 0.28)
    }
}

extension View {
    func bloomLift() -> some View {
        shadow(color: Bloom.Lift.color, radius: Bloom.Lift.radius, x: 0, y: Bloom.Lift.y)
    }

    func bloomCard() -> some View {
        background(Bloom.Pigment.surface)
            .clipShape(RoundedRectangle(cornerRadius: Bloom.Bend.card, style: .continuous))
            .bloomLift()
    }
}

/// Role: 44pt chrome control. SF Symbol sits inside the hit fill. Custom size uses ScaledMetric.
struct BloomIcon: View {
    let symbol: String
    let label: String
    var action: () -> Void
    @ScaledMetric(relativeTo: .body) private var hit = Bloom.Rhythm.steps(6)

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(Bloom.Typeface.headline)
                .foregroundStyle(Bloom.Pigment.ink)
                .frame(width: hit, height: hit)
                .background(Bloom.Pigment.surface)
                .clipShape(RoundedRectangle(cornerRadius: Bloom.Bend.chip, style: .continuous))
                .contentShape(RoundedRectangle(cornerRadius: Bloom.Bend.chip, style: .continuous))
        }
        .buttonStyle(TilePress())
        .accessibilityLabel(label)
        .bloomLift()
    }
}

enum BloomFigures {
    static func pips(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }
}

enum NeedleFeel {
    @MainActor
    static func commit() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}

enum WallLinks {
    /// Known product URLs. These literals always parse.
    static let contact = URL(string: "https://deadwax-wall.pro/contact-us")!
    static let musicBrainz = URL(string: "https://musicbrainz.org")!
    static let coverArt = URL(string: "https://coverartarchive.org")!
}
