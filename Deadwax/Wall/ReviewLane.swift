import Foundation

/// Role: Parses `-ReviewScreen today|log|goals` once after onboarding. Extra cover slugs open those screens.
enum WallSegment: String, Sendable, Equatable, CaseIterable {
    case discover
    case crate
    case heard
    case taste
}

enum ReviewLane: String, Sendable, Equatable {
    case today
    case log
    case goals
    case discover
    case crate
    case seen
    case profile
    case scan
    case settings

    enum Destination: Equatable, Sendable {
        case segment(WallSegment)
        case scan
        case settings
    }

    var destination: Destination {
        switch self {
        case .today, .discover:
            return .segment(.discover)
        case .crate:
            return .segment(.crate)
        case .log, .seen:
            return .segment(.heard)
        case .goals, .profile:
            return .segment(.taste)
        case .scan:
            return .scan
        case .settings:
            return .settings
        }
    }

    static func isReviewLaunch(arguments: [String] = ProcessInfo.processInfo.arguments) -> Bool {
        arguments.contains("-ReviewScreen")
    }

    static func parse(_ arguments: [String] = ProcessInfo.processInfo.arguments) -> ReviewLane? {
        guard let index = arguments.firstIndex(of: "-ReviewScreen") else { return nil }
        let next = arguments.index(after: index)
        guard arguments.indices.contains(next) else { return nil }
        return parseKey(arguments[next])
    }

    static func consume(
        arguments: [String] = ProcessInfo.processInfo.arguments,
        onboarded: Bool,
        consumed: inout Bool
    ) -> ReviewLane? {
        guard onboarded, !consumed else { return nil }
        consumed = true
        return parse(arguments)
    }

    private static func parseKey(_ token: String) -> ReviewLane? {
        switch token.lowercased() {
        case Self.today.rawValue, "home":
            return .today
        case Self.log.rawValue, "heard":
            return .log
        case Self.goals.rawValue, "taste":
            return .goals
        case Self.discover.rawValue:
            return .discover
        case Self.crate.rawValue:
            return .crate
        case Self.seen.rawValue:
            return .seen
        case Self.profile.rawValue:
            return .profile
        case Self.scan.rawValue:
            return .scan
        case Self.settings.rawValue:
            return .settings
        default:
            return nil
        }
    }
}
