import Foundation

struct WallLoad: Sendable, Equatable {
    var document: WallDocument
    var recoveredFromBackup: Bool
    var startedEmpty: Bool
}

protocol WallProjecting: Sendable {
    func load() async -> WallLoad
    func save(_ document: WallDocument) async
    func wipe() async
    func demoPlanted() async -> Bool
    func markDemoPlanted() async
}

/// Application Support folder for the wall projection. Views never touch this type.
enum WallPaths {
    static func supportFolder() throws -> URL {
        let manager = FileManager.default
        let base = try manager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let folder = base.appendingPathComponent("Deadwax", isDirectory: true)
        try manager.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }
}

enum WallDefaultsSource: Sendable {
    case standard
    case suite(String)
}

/// Role: Projects WallDocument to UserDefaults (`dwx.wall.v1`) and an atomic Application Support file. Views never touch this type.
actor WallVault: WallProjecting {
    static let documentKey = "dwx.wall.v1"
    static let backupKey = "dwx.wall.v1.backup"
    static let demoKey = "dwx.demo.v1"

    private let source: WallDefaultsSource
    private let folder: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(source: WallDefaultsSource = .standard, folder: URL) {
        self.source = source
        self.folder = folder
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        self.encoder = encoder
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        self.decoder = decoder
    }

    func load() async -> WallLoad {
        let fm = FileManager.default
        if !fm.fileExists(atPath: folder.path) {
            try? fm.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        let primary = defaults().data(forKey: Self.documentKey)
        if let document = decode(primary) {
            return WallLoad(document: repaired(document), recoveredFromBackup: false, startedEmpty: false)
        }
        let backupDefaults = defaults().data(forKey: Self.backupKey)
        if let document = decode(backupDefaults) {
            return WallLoad(document: repaired(document), recoveredFromBackup: true, startedEmpty: false)
        }
        if let document = decode(try? Data(contentsOf: fileURL)) {
            return WallLoad(document: repaired(document), recoveredFromBackup: false, startedEmpty: false)
        }
        if let document = decode(try? Data(contentsOf: backupFileURL)) {
            return WallLoad(document: repaired(document), recoveredFromBackup: true, startedEmpty: false)
        }
        return WallLoad(document: .empty, recoveredFromBackup: false, startedEmpty: true)
    }

    func save(_ document: WallDocument) async {
        let fm = FileManager.default
        do {
            try fm.createDirectory(at: folder, withIntermediateDirectories: true)
        } catch {
            return
        }
        var snapshot = document
        snapshot.schemaVersion = WallDocument.currentSchema
        snapshot.repairGrooves()
        guard let data = try? encoder.encode(snapshot) else { return }
        let box = defaults()
        if let current = box.data(forKey: Self.documentKey) {
            box.set(current, forKey: Self.backupKey)
        }
        if fm.fileExists(atPath: fileURL.path) {
            try? fm.removeItem(at: backupFileURL)
            try? fm.copyItem(at: fileURL, to: backupFileURL)
        }
        box.set(data, forKey: Self.documentKey)
        do {
            try data.write(to: fileURL, options: .atomic)
        } catch {
            return
        }
    }

    func wipe() async {
        let box = defaults()
        box.removeObject(forKey: Self.documentKey)
        box.removeObject(forKey: Self.backupKey)
        let fm = FileManager.default
        try? fm.removeItem(at: fileURL)
        try? fm.removeItem(at: backupFileURL)
    }

    func demoPlanted() async -> Bool {
        defaults().bool(forKey: Self.demoKey)
    }

    func markDemoPlanted() async {
        defaults().set(true, forKey: Self.demoKey)
    }

    private func repaired(_ document: WallDocument) -> WallDocument {
        var copy = document
        copy.repairGrooves()
        return copy
    }

    private func decode(_ data: Data?) -> WallDocument? {
        guard let data else { return nil }
        return try? decoder.decode(WallDocument.self, from: data)
    }

    private var fileURL: URL {
        folder.appendingPathComponent("wall.json", isDirectory: false)
    }

    private var backupFileURL: URL {
        folder.appendingPathComponent("wall.json.backup", isDirectory: false)
    }

    private func defaults() -> UserDefaults {
        switch source {
        case .standard:
            return .standard
        case .suite(let name):
            return UserDefaults(suiteName: name) ?? .standard
        }
    }
}

actor MemoryVault: WallProjecting {
    private var document: WallDocument
    private var planted: Bool

    init(document: WallDocument = .empty, planted: Bool = false) {
        self.document = document
        self.planted = planted
    }

    func load() async -> WallLoad {
        WallLoad(
            document: document,
            recoveredFromBackup: false,
            startedEmpty: document.pressings.isEmpty
        )
    }

    func save(_ document: WallDocument) async {
        self.document = document
    }

    func wipe() async {
        document = .empty
    }

    func demoPlanted() async -> Bool { planted }

    func markDemoPlanted() async { planted = true }
}
