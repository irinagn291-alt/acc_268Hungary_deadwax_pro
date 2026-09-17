import SwiftUI

/// Role: One-shot three-page cover. Skip still writes defaults. Re-runnable from Settings.
struct SleeveOnboarding: View {
    var onFinish: () -> Void
    @State private var page = 0

    private let pages: [(art: String, title: String, line: String)] = [
        ("dwx_Onboarding1", "Your played crate lives on this wall.", "Search or scan a pressing onto a sleeve. Home is the wall, not a title list."),
        ("dwx_Onboarding2", "Tap a sleeve to Drop the needle.", "Search writes Mint. Drop writes a GrooveMark and flips that copy to Grooved."),
        ("dwx_Onboarding3", "Grade what you heard.", "Taste folds Grooved grades by genre and label. Unplayed Mint stays off taste."),
    ]

    var body: some View {
        let item = pages[page]
        VStack(alignment: .leading, spacing: Bloom.Rhythm.steps(2)) {
            HStack {
                Spacer()
                if page < pages.count - 1 {
                    Button("Skip") { onFinish() }
                        .font(Bloom.Typeface.caption)
                        .foregroundStyle(Bloom.Pigment.muted)
                        .frame(minHeight: Bloom.Rhythm.steps(6))
                        .contentShape(Rectangle())
                }
            }
            Spacer(minLength: Bloom.Rhythm.steps(1))
            Image(item.art)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 280, maxHeight: 280, alignment: .leading)
                .accessibilityHidden(true)
            Text(item.title)
                .font(Bloom.Typeface.display)
                .foregroundStyle(Bloom.Pigment.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(item.line)
                .font(Bloom.Typeface.body)
                .foregroundStyle(Bloom.Pigment.muted)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: Bloom.Rhythm.steps(2))
            Button(page == pages.count - 1 ? "Continue" : "Continue") {
                if page == pages.count - 1 {
                    onFinish()
                } else {
                    withAnimation(Bloom.Motion.travel) { page += 1 }
                }
            }
            .buttonStyle(NeedlePress(kind: .primary))
        }
        .padding(.horizontal, Bloom.Rhythm.steps(3))
        .padding(.bottom, Bloom.Rhythm.steps(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Bloom.Pigment.background.ignoresSafeArea())
    }
}
