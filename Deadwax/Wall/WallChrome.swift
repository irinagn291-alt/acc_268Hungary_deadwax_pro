import Combine
import SwiftUI

/// Role: Presentation session for wall-segment chrome. Views call dropNeedle, gradeSleeve, peelLastMark, and etchRunout through this type and never mutate Groove.
@MainActor
final class WallChrome: ObservableObject {
    let store: WallStore

    @Published var document: WallDocument = .empty
    @Published var segment: WallSegment = .discover
    @Published var focusedID: UUID?
    @Published var fuseNote: String = ""
    @Published var showingDeadwax = false
    @Published var platterSide: PlatterSide = .a
    @Published var fuseRunout: String = ""
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
    private var runoutTask: Task<Void, Never>?
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
            if let id = focusedID {
                loadRunout(for: id, side: .a)
            }
        }
        watchPulse()
        booted = true
    }

    func handle(phase: ScenePhase) {
        if phase == .inactive || phase == .background {
            commitRunoutDraft()
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
            if let id = focusedID {
                fuseNote = document.notes[id] ?? ""
                loadRunout(for: id, side: .a)
            }
        }
    }

    func replayOnboarding() {
        showingOnboarding = true
        showingSettings = false
    }

    func focus(_ pressing: Pressing) {
        guard focusedID != pressing.id else {
            faultCopy = nil
            return
        }
        commitRunoutDraft()
        focusedID = pressing.id
        fuseNote = document.notes[pressing.id] ?? ""
        faultCopy = nil
        showingDeadwax = false
        loadRunout(for: pressing.id, side: .a)
    }

    func openDeadwax() {
        guard let id = focusedID, focused?.groove == .grooved else { return }
        loadRunout(for: id, side: platterSide)
        showingDeadwax = true
    }

    func selectSide(_ side: PlatterSide) {
        guard side != platterSide else { return }
        guard let id = focusedID else {
            platterSide = side
            fuseRunout = ""
            return
        }
        let previous = platterSide
        let text = fuseRunout
        runoutTask?.cancel()
        runoutTask = nil
        applyRunout(id: id, side: previous, text: text, report: false)
        platterSide = side
        fuseRunout = document.inscription(for: id, side: side)
    }

    func editRunout(_ text: String) {
        let capped = String(text.prefix(RunoutScript.limit))
        fuseRunout = capped
        guard let id = focusedID else { return }
        let side = platterSide
        runoutTask?.cancel()
        runoutTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            applyRunout(id: id, side: side, text: capped, report: true)
        }
    }

    func stampPlant(_ plant: String) {
        guard let id = focusedID else { return }
        let side = platterSide
        let next = RunoutScript.stamped(fuseRunout, with: plant)
        fuseRunout = next
        runoutTask?.cancel()
        runoutTask = nil
        applyRunout(id: id, side: side, text: next, report: true)
    }

    func commitRunoutDraft() {
        runoutTask?.cancel()
        runoutTask = nil
        guard let id = focusedID else { return }
        applyRunout(id: id, side: platterSide, text: fuseRunout, report: false)
    }

    func presentRunout(_ signature: String) {
        guard let pressing = document.pressing(forRunout: signature) else { return }
        if focusedID != pressing.id {
            commitRunoutDraft()
        } else {
            runoutTask?.cancel()
            runoutTask = nil
        }
        focusedID = pressing.id
        fuseNote = document.notes[pressing.id] ?? ""
        faultCopy = nil
        let rows = document.runouts[pressing.id] ?? []
        if let match = rows.first(where: { RunoutMath.signature(of: $0.inscription) == signature }) {
            platterSide = match.side
            fuseRunout = match.inscription
        } else {
            loadRunout(for: pressing.id, side: .a)
        }
        segment = .discover
        showingDeadwax = true
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
            if document.pressings.first(where: { $0.id == id })?.groove != .grooved {
                showingDeadwax = false
                loadRunout(for: id, side: .a)
            }
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
        commitRunoutDraft()
        let pressing = await store.sleeve(hit)
        sync()
        focusedID = pressing.id
        fuseNote = document.notes[pressing.id] ?? ""
        showingDeadwax = false
        loadRunout(for: pressing.id, side: .a)
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
        runoutTask?.cancel()
        runoutTask = nil
        await store.resetAllData()
        sync()
        focusedID = nil
        fuseNote = ""
        showingDeadwax = false
        platterSide = .a
        fuseRunout = ""
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
            if let id = self.focusedID {
                loadRunout(for: id, side: .a)
            } else {
                platterSide = .a
                fuseRunout = ""
                showingDeadwax = false
            }
        }
    }

    func apply(_ lane: ReviewLane) {
        commitRunoutDraft()
        showingDeadwax = false
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
            showingDeadwax = false
            showingSearch = false
            showingScan = false
            showingSettings = false
            showingTwist = false
            if let id, document.pressings.contains(where: { $0.id == id }) {
                if focusedID != id {
                    commitRunoutDraft()
                    focusedID = id
                    loadRunout(for: id, side: .a)
                }
                fuseNote = document.notes[id] ?? ""
                showingDeadwax = false
            }
        }
    }

    private func loadRunout(for id: UUID, side: PlatterSide) {
        platterSide = side
        fuseRunout = document.inscription(for: id, side: side)
    }

    private func applyRunout(id: UUID, side: PlatterSide, text: String, report: Bool) {
        do {
            try store.etchRunout(id, side: side, inscription: text)
            sync()
            if report { faultCopy = nil }
        } catch WallFault.stillMint {
            if report {
                faultCopy = "The deadwax waits for a Grooved sleeve. Drop first."
            }
        } catch WallFault.unknownPressing {
            if report {
                faultCopy = "That sleeve is not on the wall."
            }
        } catch {
            if report {
                faultCopy = "The runout did not save. Try again."
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
        chrome.platterSide = .a
        chrome.fuseRunout = chrome.document.inscription(for: DemoIDs.kindOfBlue, side: .a)
        return chrome
    }
}
#endif
