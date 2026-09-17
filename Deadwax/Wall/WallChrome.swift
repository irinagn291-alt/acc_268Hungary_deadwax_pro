import Combine
import SwiftUI

/// Role: Presentation session for wall-segment chrome. Views call dropNeedle, gradeSleeve, and peelLastMark through this type and never mutate Groove.
@MainActor
final class WallChrome: ObservableObject {
    let store: WallStore

    @Published var document: WallDocument = .empty
    @Published var segment: WallSegment = .discover
    @Published var focusedID: UUID?
    @Published var fuseNote: String = ""
    @Published var booted = false
    @Published var showingOnboarding = true
    @Published var showingSearch = false
    @Published var showingScan = false
    @Published var showingSettings = false
    @Published var showingTwist = false
    @Published var recoveredFromBackup = false
    @Published var dropPulse = false
    @Published var showSuccess = false
    @Published var busyDrop = false
    @Published var busyGrade = false
    @Published var busyRetract = false
    @Published var busySleeve = false
    @Published var faultCopy: String?
    @Published var confirmRetract = false
    @Published var confirmReset = false

    private var didBoot = false
    private var reviewHookConsumed = false
    private var noteTask: Task<Void, Never>?
    private var successTask: Task<Void, Never>?

    init(store: WallStore) {
        self.store = store
    }

    static func live() -> WallChrome {
        let folder: URL
        if let support = try? WallPaths.supportFolder() {
            folder = support
        } else {
            folder = FileManager.default.temporaryDirectory.appendingPathComponent("Deadwax", isDirectory: true)
            try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        return WallChrome(
            store: WallStore(
                vault: WallVault(source: .standard, folder: folder),
                client: CatalogClient()
            )
        )
    }

    var focused: Pressing? {
        guard let focusedID else { return nil }
        return document.pressings.first { $0.id == focusedID }
    }

    var dropEnabled: Bool {
        store.dropIsEnabled && focusedID != nil && !busyDrop
    }

    func boot() async {
        guard !didBoot else { return }
        didBoot = true
        await store.restore()
        await store.plantSimulatorSeedIfNeeded()
        sync()
        showingOnboarding = !document.onboardingComplete
        if document.onboardingComplete {
            applyReviewHookOnce()
        }
        if focusedID == nil {
            focusedID = document.mintSleeves().first?.id ?? document.pressings.first?.id
            fuseNote = focused.flatMap { document.notes[$0.id] } ?? ""
        }
        watchPulse()
        booted = true
    }

    func handle(phase: ScenePhase) {
        if phase == .inactive || phase == .background {
            Task { await store.flush() }
        }
    }

    func open(_ url: URL) {
        guard let route = WallDeepLink.parse(url) else { return }
        if showingOnboarding {
            WallDeepLink.post(route)
            return
        }
        apply(route)
    }

    func consumePulse(_ raw: String) {
        guard let route = WallDeepLink.decode(raw) else { return }
        if showingOnboarding {
            WallDeepLink.post(route)
            return
        }
        apply(route)
    }

    func finishOnboarding() async {
        await store.markOnboardingComplete()
        sync()
        showingOnboarding = false
        applyReviewHookOnce()
        if focusedID == nil {
            focusedID = document.pressings.first?.id
        }
    }

    func replayOnboarding() {
        showingOnboarding = true
        showingSettings = false
    }

    func focus(_ pressing: Pressing) {
        focusedID = pressing.id
        fuseNote = document.notes[pressing.id] ?? ""
        faultCopy = nil
    }

    func dropFocused(reduceMotion: Bool) async {
        guard let id = focusedID else { return }
        guard !busyDrop else { return }
        busyDrop = true
        defer { busyDrop = false }
        do {
            _ = try await store.dropNeedle(id)
            sync()
            NeedleFeel.commit()
            withAnimation(Bloom.Motion.drop(reduce: reduceMotion)) {
                dropPulse.toggle()
            }
            flashSuccess(reduceMotion: reduceMotion)
            faultCopy = nil
        } catch WallFault.unknownPressing {
            faultCopy = "That sleeve is not on the wall. Search or Scan to place it."
        } catch {
            faultCopy = "The Drop did not land. Try the sleeve again."
        }
    }

    func gradeFocused(_ pips: Int) async {
        guard let id = focusedID else { return }
        guard !busyGrade else { return }
        busyGrade = true
        defer { busyGrade = false }
        do {
            try await store.gradeSleeve(id, pips: pips)
            sync()
            NeedleFeel.commit()
            faultCopy = nil
        } catch WallFault.stillMint {
            faultCopy = "Grade waits for a Grooved sleeve. Drop first."
        } catch WallFault.badGrade {
            faultCopy = "Grade stays between 1 and 5."
        } catch {
            faultCopy = "The grade did not save. Try again."
        }
    }

    func peelFocused() async {
        guard let id = focusedID else { return }
        guard !busyRetract else { return }
        busyRetract = true
        defer { busyRetract = false }
        do {
            try await store.peelLastMark(id)
            sync()
            NeedleFeel.commit()
            fuseNote = document.notes[id] ?? ""
            faultCopy = nil
        } catch WallFault.nothingToPeel {
            faultCopy = "No GrooveMark left to retract on this sleeve."
        } catch {
            faultCopy = "Retract did not peel. Try again."
        }
    }

    func editNote(_ text: String) {
        fuseNote = text
        guard let id = focusedID else { return }
        noteTask?.cancel()
        noteTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            do {
                try await store.inscribeNote(id, note: text)
                sync()
            } catch WallFault.stillMint {
                faultCopy = "Notes stay on Grooved sleeves. Drop first."
            } catch {
                faultCopy = "The note did not save. Try again."
            }
        }
    }

    func sleeve(_ hit: CatalogHit) async {
        busySleeve = true
        defer { busySleeve = false }
        let pressing = await store.sleeve(hit)
        sync()
        focusedID = pressing.id
        fuseNote = document.notes[pressing.id] ?? ""
        segment = .discover
        showingSearch = false
        showingScan = false
        faultCopy = nil
    }

    func lookup(_ raw: String) async throws -> CatalogHit {
        try await store.lookupCode(raw)
    }

    func seek(_ query: String) async throws -> [CatalogHit] {
        try await store.seek(query)
    }

    func resetWall() async {
        await store.resetAllData()
        sync()
        focusedID = nil
        fuseNote = ""
        segment = .discover
        faultCopy = nil
        showingSettings = false
    }

    func sync() {
        document = store.document
        recoveredFromBackup = store.recoveredFromBackup
        if let focusedID, document.pressings.contains(where: { $0.id == focusedID }) == false {
            self.focusedID = document.pressings.first?.id
            fuseNote = focused.flatMap { document.notes[$0.id] } ?? ""
        }
    }

    func apply(_ lane: ReviewLane) {
        showingSearch = false
        showingTwist = false
        switch lane.destination {
        case .segment(let next):
            segment = next
            showingScan = false
            showingSettings = false
        case .scan:
            segment = .discover
            showingScan = true
            showingSettings = false
        case .settings:
            showingScan = false
            showingSettings = true
        }
    }

    private func apply(_ route: WallDeepLink.Route) {
        switch route {
        case .segment(let next, let id):
            withAnimation(Bloom.Motion.travel) {
                segment = next
            }
            showingSearch = false
            showingScan = false
            showingSettings = false
            showingTwist = false
            if let id, document.pressings.contains(where: { $0.id == id }) {
                focusedID = id
                fuseNote = document.notes[id] ?? ""
            }
        }
    }

    private func applyReviewHookOnce() {
        guard document.onboardingComplete else { return }
        if let lane = ReviewLane.consume(
            arguments: ProcessInfo.processInfo.arguments,
            onboarded: true,
            consumed: &reviewHookConsumed
        ) {
            apply(lane)
            return
        }
        guard !ReviewLane.isReviewLaunch() else { return }
        if let pending = WallDeepLink.takePending() {
            apply(pending)
        }
    }

    private func watchPulse() {
        Task { [weak self] in
            for await note in NotificationCenter.default.notifications(named: WallDeepLink.pulse) {
                guard let self else { return }
                if let raw = note.object as? String {
                    self.consumePulse(raw)
                }
            }
        }
    }

    private func flashSuccess(reduceMotion: Bool) {
        successTask?.cancel()
        withAnimation(reduceMotion ? Bloom.Motion.travel : Bloom.Motion.drop(reduce: false)) {
            showSuccess = true
        }
        successTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(900))
            guard !Task.isCancelled else { return }
            withAnimation(Bloom.Motion.travel) {
                showSuccess = false
            }
        }
    }
}

#if DEBUG
struct QuietTransport: CatalogTransporting {
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        throw CatalogFault.transport
    }
}

extension WallChrome {
    static func seededPreview() -> WallChrome {
        let store = WallStore(
            vault: MemoryVault(document: .demoCrate(), planted: true),
            client: CatalogClient(transport: QuietTransport())
        )
        let chrome = WallChrome(store: store)
        chrome.document = .demoCrate()
        chrome.booted = true
        chrome.showingOnboarding = false
        chrome.focusedID = DemoIDs.kindOfBlue
        chrome.fuseNote = chrome.document.notes[DemoIDs.kindOfBlue] ?? ""
        return chrome
    }
}
#endif
