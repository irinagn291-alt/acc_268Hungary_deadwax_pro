import SwiftUI

/// Role: Shared press language for Drop, Scan, Grade, and Retract. Destructive Retract does not wear accent.
struct NeedlePress: ButtonStyle {
    enum Kind {
        case primary
        case quiet
        case destructive
    }

    var kind: Kind = .primary
    var isLoading: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        NeedlePressBody(configuration: configuration, kind: kind, isLoading: isLoading)
    }
}

private struct NeedlePressBody: View {
    let configuration: ButtonStyle.Configuration
    let kind: NeedlePress.Kind
    let isLoading: Bool
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        ZStack {
            configuration.label
                .opacity(isLoading ? 0 : 1)
            if isLoading {
                ProgressView()
                    .tint(onAccent ? Bloom.Pigment.surface : Bloom.Pigment.accent)
            }
        }
        .font(kind == .primary ? Bloom.Typeface.display : Bloom.Typeface.body)
        .foregroundStyle(foreground)
        .frame(maxWidth: .infinity, minHeight: kind == .primary ? Bloom.Rhythm.steps(8) : Bloom.Rhythm.steps(6))
        .padding(.horizontal, Bloom.Rhythm.steps(2))
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: Bloom.Bend.card, style: .continuous))
        .bloomLift()
        .scaleEffect(configuration.isPressed && isEnabled ? 0.97 : 1)
        .opacity(isEnabled ? 1 : 0.45)
        .animation(Bloom.Motion.travel, value: configuration.isPressed)
        .contentShape(RoundedRectangle(cornerRadius: Bloom.Bend.card, style: .continuous))
    }

    private var onAccent: Bool {
        kind == .primary && isEnabled
    }

    private var foreground: Color {
        switch kind {
        case .primary:
            return Bloom.Pigment.surface
        case .quiet:
            return Bloom.Pigment.ink
        case .destructive:
            return Bloom.Pigment.surface
        }
    }

    private var background: Color {
        guard isEnabled else { return Bloom.Pigment.muted.opacity(0.35) }
        switch kind {
        case .primary:
            return Bloom.Pigment.accent
        case .quiet:
            return Bloom.Pigment.surface
        case .destructive:
            return Bloom.Pigment.ink
        }
    }
}

struct TilePress: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(Bloom.Motion.travel, value: configuration.isPressed)
    }
}

struct GrooveChipPress: ButtonStyle {
    var selected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Bloom.Typeface.caption)
            .foregroundStyle(selected ? Bloom.Pigment.surface : Bloom.Pigment.ink)
            .padding(.horizontal, Bloom.Rhythm.steps(1))
            .frame(minWidth: Bloom.Rhythm.steps(6), minHeight: Bloom.Rhythm.steps(6))
            .background(selected ? Bloom.Pigment.accent : Bloom.Pigment.surface)
            .clipShape(RoundedRectangle(cornerRadius: Bloom.Bend.chip, style: .continuous))
            .bloomLift()
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .contentShape(RoundedRectangle(cornerRadius: Bloom.Bend.chip, style: .continuous))
    }
}

