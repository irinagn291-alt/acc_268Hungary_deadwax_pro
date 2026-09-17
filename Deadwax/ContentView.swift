import SwiftUI

/// Role: Root shell. Onboarding cover, then wall-segment chrome. ReviewScreen is applied after onboarding.
struct ContentView: View {
    @StateObject private var chrome: WallChrome
    @Environment(\.scenePhase) private var scenePhase

    init(chrome: WallChrome = .live()) {
        _chrome = StateObject(wrappedValue: chrome)
    }

    var body: some View {
        ZStack {
            Bloom.Pigment.background.ignoresSafeArea()
            if chrome.booted == false {
                Image("dwx_Splash")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .accessibilityHidden(true)
            } else if chrome.showingOnboarding {
                SleeveOnboarding {
                    Task { await chrome.finishOnboarding() }
                }
            } else {
                WallShell()
            }
        }
        .environmentObject(chrome)
        .animation(Bloom.Motion.travel, value: chrome.showingOnboarding)
        .animation(Bloom.Motion.travel, value: chrome.booted)
        .task { await chrome.boot() }
        .onChange(of: scenePhase) { _, phase in
            chrome.handle(phase: phase)
        }
        .onOpenURL { chrome.open($0) }
    }
}

#if DEBUG
#Preview {
    ContentView(chrome: .seededPreview())
}
#endif
