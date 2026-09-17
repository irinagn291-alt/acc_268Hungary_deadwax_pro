import SwiftUI

/// Role: Twist screen for drop-then-groove. Home also surfaces Mint versus Grooved on every tile.
struct GrooveFlip: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: Bloom.Rhythm.steps(2)) {
            HStack {
                Text("Drop, then groove.")
                    .font(Bloom.Typeface.display)
                    .foregroundStyle(Bloom.Pigment.ink)
                    .lineLimit(2)
                Spacer(minLength: 0)
                BloomIcon(symbol: "xmark", label: "Close") {
                    dismiss()
                }
            }
            Spacer(minLength: Bloom.Rhythm.steps(1))
            Image("dwx_TwistHero")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 280, maxHeight: 240, alignment: .leading)
                .accessibilityHidden(true)
            Text("Search or Scan writes a Mint sleeve. Drop writes a GrooveMark, counts a play, and flips that copy to Grooved.")
                .font(Bloom.Typeface.body)
                .foregroundStyle(Bloom.Pigment.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text("Grade and Taste fold only Grooved copies. Retract peels the last play. At zero plays the sleeve returns to Mint.")
                .font(Bloom.Typeface.body)
                .foregroundStyle(Bloom.Pigment.muted)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: Bloom.Rhythm.steps(2))
            Button("Back to the wall") { dismiss() }
                .buttonStyle(NeedlePress(kind: .primary))
        }
        .padding(.horizontal, Bloom.Rhythm.steps(3))
        .padding(.bottom, Bloom.Rhythm.steps(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Bloom.Pigment.background.ignoresSafeArea())
    }
}
