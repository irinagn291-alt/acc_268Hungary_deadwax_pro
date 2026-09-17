import AppIntents
import Foundation

/// Role: App Intents that open Discover, a Pressing, Heard, and Taste without a Game tab.
struct OpenDiscoverIntent: AppIntent {
    static var title: LocalizedStringResource { "Open Discover" }
    static var openAppWhenRun: Bool { true }

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            WallDeepLink.post(.segment(.discover, nil))
        }
        return .result()
    }
}

struct OpenHeardIntent: AppIntent {
    static var title: LocalizedStringResource { "Open Heard" }
    static var openAppWhenRun: Bool { true }

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            WallDeepLink.post(.segment(.heard, nil))
        }
        return .result()
    }
}

struct OpenTasteIntent: AppIntent {
    static var title: LocalizedStringResource { "Open Taste" }
    static var openAppWhenRun: Bool { true }

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            WallDeepLink.post(.segment(.taste, nil))
        }
        return .result()
    }
}

struct OpenPressingIntent: AppIntent {
    static var title: LocalizedStringResource { "Open a Pressing" }
    static var openAppWhenRun: Bool { true }

    @Parameter(title: "Pressing")
    var pressingID: String

    func perform() async throws -> some IntentResult {
        let id = UUID(uuidString: pressingID)
        await MainActor.run {
            WallDeepLink.post(.segment(.discover, id))
        }
        return .result()
    }
}

struct DeadwaxShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenDiscoverIntent(),
            phrases: [
                "Open Discover in \(.applicationName)",
                "Show the sleeve wall in \(.applicationName)",
            ],
            shortTitle: "Discover",
            systemImageName: "square.grid.2x2"
        )
        AppShortcut(
            intent: OpenHeardIntent(),
            phrases: [
                "Open Heard in \(.applicationName)",
            ],
            shortTitle: "Heard",
            systemImageName: "waveform"
        )
        AppShortcut(
            intent: OpenTasteIntent(),
            phrases: [
                "Open Taste in \(.applicationName)",
            ],
            shortTitle: "Taste",
            systemImageName: "chart.bar"
        )
        AppShortcut(
            intent: OpenPressingIntent(),
            phrases: [
                "Open a pressing in \(.applicationName)",
            ],
            shortTitle: "Pressing",
            systemImageName: "opticaldisc"
        )
    }
}
