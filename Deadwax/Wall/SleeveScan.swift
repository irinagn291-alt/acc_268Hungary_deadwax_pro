@preconcurrency import AVFoundation
import SwiftUI
import UIKit

/// Role: Full-screen Scan cover over Discover. Live AVCaptureMetadataOutput, Simulator chips, and a manual catalog field.
struct SleeveScan: View {
    @EnvironmentObject private var chrome: WallChrome
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var permission = AVCaptureDevice.authorizationStatus(for: .video)
    @State private var live = false
    @State private var fault: String?
    @State private var showSpinner = false
    @State private var manual = ""
    @State private var inFlight: String?
    @State private var spinnerTask: Task<Void, Never>?

    private var hasCaptureDevice: Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        return AVCaptureDevice.default(for: .video) != nil
        #endif
    }

    var body: some View {
        Group {
            if hasCaptureDevice == false {
                simulatorPage
            } else {
                switch permission {
                case .authorized:
                    livePage
                case .notDetermined:
                    continuePage
                default:
                    deniedPage
                }
            }
        }
        .background(Bloom.Pigment.background.ignoresSafeArea())
        .onAppear {
            permission = AVCaptureDevice.authorizationStatus(for: .video)
            live = permission == .authorized && hasCaptureDevice
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background || phase == .inactive {
                live = false
            } else if phase == .active, permission == .authorized, hasCaptureDevice {
                live = true
            }
        }
        .onDisappear {
            live = false
            spinnerTask?.cancel()
        }
    }

    private var continuePage: some View {
        EmptySleevePage(
            art: "dwx_ControlFace",
            headline: "The camera reads a catalog code.",
            line: "Point at a barcode or QR on a sleeve. Continue opens the system dialog.",
            cta: "Continue"
        ) {
            AVCaptureDevice.requestAccess(for: .video) { _ in
                Task { @MainActor in
                    permission = AVCaptureDevice.authorizationStatus(for: .video)
                    live = permission == .authorized
                    if permission != .authorized && permission != .notDetermined {
                        live = false
                    }
                }
            }
        }
    }

    private var deniedPage: some View {
        EmptySleevePage(
            art: "dwx_EmptyHome",
            headline: "Camera is off for this device.",
            line: "Open Settings to use a live scan, or type a catalog code on Simulator.",
            cta: "Open Settings"
        ) {
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        }
    }

    private var simulatorPage: some View {
        VStack(alignment: .leading, spacing: Bloom.Rhythm.steps(2)) {
            scanHeader
            Text("No camera on this device. Use a sample code or type a catalog number.")
                .font(Bloom.Typeface.body)
                .foregroundStyle(Bloom.Pigment.muted)
            sampleChips
            manualField
            if showSpinner {
                ProgressView()
                    .tint(Bloom.Pigment.accent)
                    .frame(maxWidth: .infinity)
            }
            if let fault {
                WallFaultBanner(copy: fault) {
                    Task { await intake(manual) }
                }
            }
            Spacer(minLength: Bloom.Rhythm.steps(2))
        }
        .padding(Bloom.Rhythm.steps(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var livePage: some View {
        ZStack {
            SleeveScanPreview(isLive: live) { payload in
                Task { await intake(payload) }
            }
            .ignoresSafeArea()
            VStack(alignment: .leading, spacing: Bloom.Rhythm.steps(2)) {
                scanHeader
                    .padding(.horizontal, Bloom.Rhythm.steps(2))
                Spacer()
                ScanReticle()
                    .stroke(Bloom.Pigment.accent, lineWidth: 3)
                    .frame(width: Bloom.Rhythm.steps(32), height: Bloom.Rhythm.steps(18))
                    .frame(maxWidth: .infinity)
                Spacer()
                VStack(alignment: .leading, spacing: Bloom.Rhythm.steps(1)) {
                    Text("Hold a barcode or QR in the frame.")
                        .font(Bloom.Typeface.body)
                        .foregroundStyle(Bloom.Pigment.ink)
                    manualField
                    if let fault {
                        WallFaultBanner(copy: fault) {
                            Task { await intake(manual) }
                        }
                    }
                }
                .padding(Bloom.Rhythm.steps(2))
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Bloom.Pigment.surface.opacity(0.94))
            }
            if showSpinner {
                ProgressView()
                    .tint(Bloom.Pigment.accent)
                    .scaleEffect(1.2)
                    .padding(Bloom.Rhythm.steps(3))
                    .background(Bloom.Pigment.surface)
                    .clipShape(RoundedRectangle(cornerRadius: Bloom.Bend.card, style: .continuous))
                    .bloomLift()
            }
        }
    }

    private var scanHeader: some View {
        HStack {
            Text("Scan a sleeve")
                .font(Bloom.Typeface.title)
                .foregroundStyle(Bloom.Pigment.ink)
            Spacer(minLength: 0)
            BloomIcon(symbol: "xmark", label: "Close scan") {
                live = false
                dismiss()
            }
        }
    }

    private var sampleChips: some View {
        VStack(alignment: .leading, spacing: Bloom.Rhythm.steps(1)) {
            Text("Sample codes")
                .font(Bloom.Typeface.caption)
                .foregroundStyle(Bloom.Pigment.muted)
            HStack(spacing: Bloom.Rhythm.steps(1)) {
                ForEach(Self.samples, id: \.payload) { chip in
                    Button(chip.title) {
                        Task { await intake(chip.payload) }
                    }
                    .buttonStyle(GrooveChipPress(selected: false))
                    .disabled(inFlight != nil)
                }
            }
        }
    }

    private var manualField: some View {
        HStack(spacing: Bloom.Rhythm.steps(1)) {
            TextField("Catalog code or barcode", text: $manual)
                .font(Bloom.Typeface.body)
                .foregroundStyle(Bloom.Pigment.ink)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .padding(Bloom.Rhythm.steps(2))
                .frame(minHeight: Bloom.Rhythm.steps(6))
                .background(Bloom.Pigment.surface)
                .clipShape(RoundedRectangle(cornerRadius: Bloom.Bend.card, style: .continuous))
            Button("Sleeve") {
                Task { await intake(manual) }
            }
            .buttonStyle(NeedlePress(kind: .primary, isLoading: showSpinner))
            .frame(width: 120)
            .disabled(manual.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || inFlight != nil)
        }
    }

    private func intake(_ raw: String) async {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return }
        let key = SleeveCode.candidates(from: trimmed).first ?? trimmed
        if inFlight == key { return }
        inFlight = key
        fault = nil
        spinnerTask?.cancel()
        spinnerTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(150))
            guard !Task.isCancelled else { return }
            showSpinner = true
        }
        defer {
            spinnerTask?.cancel()
            showSpinner = false
            inFlight = nil
        }
        var lastError: Error = CatalogFault.missing
        var tried: [String] = SleeveCode.candidates(from: trimmed)
        if tried.contains(trimmed) == false {
            tried.append(trimmed)
        }
        for code in tried {
            do {
                let hit = try await chrome.lookup(code)
                await chrome.sleeve(hit)
                dismiss()
                return
            } catch CatalogFault.cancelled {
                return
            } catch {
                lastError = error
            }
        }
        switch lastError as? CatalogFault {
        case .missing:
            fault = "No pressing for that code. Try another, or type the catalog number."
        case .transport:
            fault = "The catalog did not answer. Cached sleeves may still match. Try again."
        default:
            fault = "That code did not resolve. Try a catalog number."
        }
    }

    private static let samples = [
        (title: "Kind of Blue", payload: "0074646352621"),
        (title: "FACT 10", payload: "FACT 10"),
        (title: "Blue Train", payload: "0724353206424"),
    ]
}

/// Role: Scanner reticle drawn in SwiftUI. Confined to the Scan cover.
struct ScanReticle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let arm = Bloom.Rhythm.steps(3)
        let corners: [(CGPoint, CGPoint, CGPoint)] = [
            (CGPoint(x: 0, y: arm), CGPoint(x: 0, y: 0), CGPoint(x: arm, y: 0)),
            (CGPoint(x: rect.width - arm, y: 0), CGPoint(x: rect.width, y: 0), CGPoint(x: rect.width, y: arm)),
            (CGPoint(x: rect.width, y: rect.height - arm), CGPoint(x: rect.width, y: rect.height), CGPoint(x: rect.width - arm, y: rect.height)),
            (CGPoint(x: arm, y: rect.height), CGPoint(x: 0, y: rect.height), CGPoint(x: 0, y: rect.height - arm)),
        ]
        for corner in corners {
            path.move(to: corner.0)
            path.addLine(to: corner.1)
            path.addLine(to: corner.2)
        }
        return path
    }
}

struct SleeveScanPreview: UIViewRepresentable {
    var isLive: Bool
    var onPayload: @MainActor (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onPayload: onPayload)
    }

    func makeUIView(context: Context) -> SleevePreviewBox {
        let box = SleevePreviewBox()
        box.sink.onPayload = { payload in
            context.coordinator.forward(payload)
        }
        box.configure()
        return box
    }

    func updateUIView(_ uiView: SleevePreviewBox, context: Context) {
        context.coordinator.onPayload = onPayload
        uiView.sink.onPayload = { payload in
            context.coordinator.forward(payload)
        }
        if isLive {
            uiView.start()
        } else {
            uiView.stop()
        }
    }

    static func dismantleUIView(_ uiView: SleevePreviewBox, coordinator: Coordinator) {
        uiView.stop()
    }

    final class Coordinator {
        var onPayload: @MainActor (String) -> Void

        init(onPayload: @escaping @MainActor (String) -> Void) {
            self.onPayload = onPayload
        }

        func forward(_ payload: String) {
            let action = onPayload
            let text = payload
            Task { @MainActor in
                action(text)
            }
        }
    }
}

final class SleeveMetaSink: NSObject, AVCaptureMetadataOutputObjectsDelegate {
    var onPayload: ((String) -> Void)?
    private var frameCount = 0
    private var lastScan: CFTimeInterval = 0
    private let cooldown: CFTimeInterval = 1.75

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        frameCount += 1
        guard frameCount % 3 == 0 else { return }
        let now = CACurrentMediaTime()
        guard now - lastScan > cooldown else { return }
        guard let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let payload = object.stringValue,
              payload.isEmpty == false
        else { return }
        lastScan = now
        onPayload?(payload)
    }
}

final class SleeveSessionRunner: @unchecked Sendable {
    /// AVCaptureSession is confined to `queue`. startRunning and stopRunning only run on that queue.
    let session: AVCaptureSession
    private let queue = DispatchQueue(label: "dwx.sleeve.capture")

    init(session: AVCaptureSession) {
        self.session = session
    }

    func start() {
        queue.async { [session] in
            if session.isRunning == false {
                session.startRunning()
            }
        }
    }

    func stop() {
        queue.async { [session] in
            if session.isRunning {
                session.stopRunning()
            }
        }
    }
}

final class SleevePreviewBox: UIView {
    let session = AVCaptureSession()
    let sink = SleeveMetaSink()
    private lazy var runner = SleeveSessionRunner(session: session)
    private var preview: AVCaptureVideoPreviewLayer?
    private var configured = false

    func configure() {
        guard configured == false else { return }
        configured = true
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device)
        else { return }

        session.beginConfiguration()
        if session.canAddInput(input) {
            session.addInput(input)
        }
        if device.isFocusModeSupported(.continuousAutoFocus) {
            do {
                try device.lockForConfiguration()
                device.focusMode = .continuousAutoFocus
                if device.isExposureModeSupported(.continuousAutoExposure) {
                    device.exposureMode = .continuousAutoExposure
                }
                device.unlockForConfiguration()
            } catch {
                // Keep the session without continuous focus.
            }
        }

        let video = AVCaptureVideoDataOutput()
        video.alwaysDiscardsLateVideoFrames = true
        if session.canAddOutput(video) {
            session.addOutput(video)
        }

        let meta = AVCaptureMetadataOutput()
        if session.canAddOutput(meta) {
            session.addOutput(meta)
            meta.setMetadataObjectsDelegate(sink, queue: .main)
            let wanted: [AVMetadataObject.ObjectType] = [.qr, .ean13, .ean8, .upce, .code128, .code39, .code93]
            meta.metadataObjectTypes = wanted.filter { meta.availableMetadataObjectTypes.contains($0) }
        }
        session.commitConfiguration()

        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        self.layer.addSublayer(layer)
        preview = layer
        if let connection = layer.connection, connection.isVideoRotationAngleSupported(90) {
            connection.videoRotationAngle = 90
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        preview?.frame = bounds
    }

    func start() {
        runner.start()
    }

    func stop() {
        runner.stop()
    }
}
