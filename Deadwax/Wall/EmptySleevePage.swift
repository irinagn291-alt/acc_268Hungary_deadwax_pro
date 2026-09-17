import SwiftUI

/// Role: Full-page empty and denied states. CTA sits at the bottom, full width.
struct EmptySleevePage: View {
    let art: String
    let headline: String
    let line: String
    let cta: String
    var destructive: Bool = false
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Bloom.Rhythm.steps(2)) {
            Spacer(minLength: Bloom.Rhythm.steps(2))
            Image(art)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 280, maxHeight: 220, alignment: .leading)
                .accessibilityHidden(true)
            Text(headline)
                .font(Bloom.Typeface.display)
                .foregroundStyle(Bloom.Pigment.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(line)
                .font(Bloom.Typeface.body)
                .foregroundStyle(Bloom.Pigment.muted)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: Bloom.Rhythm.steps(2))
            Button(cta, action: action)
                .buttonStyle(NeedlePress(kind: destructive ? .destructive : .primary))
        }
        .padding(.horizontal, Bloom.Rhythm.steps(3))
        .padding(.bottom, Bloom.Rhythm.steps(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Bloom.Pigment.background.ignoresSafeArea())
    }
}

struct WallFaultBanner: View {
    let copy: String
    let retry: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: Bloom.Rhythm.steps(2)) {
            Text(copy)
                .font(Bloom.Typeface.caption)
                .foregroundStyle(Bloom.Pigment.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button("Retry", action: retry)
                .buttonStyle(GrooveChipPress(selected: false))
                .fixedSize()
        }
        .padding(Bloom.Rhythm.steps(2))
        .frame(maxWidth: .infinity, minHeight: Bloom.Rhythm.steps(6))
        .bloomCard()
        .accessibilityElement(children: .combine)
    }
}
