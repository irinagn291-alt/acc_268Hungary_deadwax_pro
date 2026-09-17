import Foundation

/// Role: Maps deadwax:// URLs and App Intent payloads onto wall segments without views touching UserDefaults for product data.
enum WallDeepLink {
    static let pendingKey = "dwx.route.pending"
    static let pulse = Notification.Name("dwx.wall.route")

    enum Route: Equatable, Sendable {
        case segment(WallSegment, UUID?)
    }

    static func parse(_ url: URL) -> Route? {
        guard url.scheme?.lowercased() == "deadwax" else { return nil }
        var parts: [String] = []
        if let host = url.host, !host.isEmpty {
            parts.append(host)
        }
        parts.append(contentsOf: url.pathComponents.filter { $0 != "/" })
        guard let head = parts.first?.lowercased() else { return nil }
        switch head {
        case "discover":
            return .segment(.discover, nil)
        case "heard":
            return .segment(.heard, nil)
        case "taste":
            return .segment(.taste, nil)
        case "crate":
            return .segment(.crate, nil)
        case "pressing":
            if parts.count >= 2, let id = UUID(uuidString: parts[1]) {
                return .segment(.discover, id)
            }
            return .segment(.discover, nil)
        default:
            return nil
        }
    }

    static func encode(_ route: Route) -> String {
        switch route {
        case .segment(let segment, let id):
            if let id {
                return "\(segment.rawValue)|\(id.uuidString)"
            }
            return segment.rawValue
        }
    }

    static func decode(_ raw: String) -> Route? {
        let bits = raw.split(separator: "|", maxSplits: 1).map(String.init)
        guard let head = bits.first, let segment = WallSegment(rawValue: head) else { return nil }
        let id = bits.count > 1 ? UUID(uuidString: bits[1]) : nil
        return .segment(segment, id)
    }

    static func post(_ route: Route) {
        let payload = encode(route)
        UserDefaults.standard.set(payload, forKey: pendingKey)
        NotificationCenter.default.post(name: pulse, object: payload)
    }

    static func takePending() -> Route? {
        let box = UserDefaults.standard
        guard let raw = box.string(forKey: pendingKey) else { return nil }
        box.removeObject(forKey: pendingKey)
        return decode(raw)
    }
}
