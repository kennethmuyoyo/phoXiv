//
//  ArchiveView.swift
//  phoXiv
//
//  Created by Kenneth Muyoyo on 21/04/26.
//
//  Orchestrator for the archive experience. Owns the view models and the
//  state that coordinates them; delegates all presentation to subviews in
//  the ArchiveView/ folder.
//

import SwiftUI
import AVFoundation

struct ArchiveView: View {
    @State private var stack = CardStackViewModel(items: imageMock)
    @State private var head = HeadTiltViewModel()

    @State private var isCommitting = false

    /// Head tracking starts DISABLED. User must opt in via the toggle,
    /// which routes through the priming alert.
    @State private var isTrackingEnabled = false

    @AppStorage("hasInteractedWithArchive") private var hasInteracted = false
    @State private var hintVisible = true

    @State private var showingPrimingAlert = false
    @State private var showingDeniedAlert = false
    @State private var showingUnsupportedAlert = false

    private let maxHeadTranslation: CGFloat = 280
    private let commitFraction: CGFloat = 0.70

    private var isAllDone: Bool {
        stack.items.isEmpty && stack.poppedCard == nil
    }

    // MARK: - Body

    var body: some View {
        navigationContent
            .modifier(AlertsModifier(
                showingPrimingAlert: $showingPrimingAlert,
                showingDeniedAlert: $showingDeniedAlert,
                showingUnsupportedAlert: $showingUnsupportedAlert,
                onEnable: { Task { await enableHeadTracking() } }
            ))
            .onDisappear { head.stop() }
            .onChange(of: stack.isUserDragging) { _, dragging in
                if dragging { dismissHint() }
            }
            .onChange(of: stack.poppedCard) { oldValue, newValue in
                if oldValue == nil && newValue != nil { dismissHint() }
            }
            .onChange(of: head.state.signedProgress) { _, signedProgress in
                handleHeadProgressChanged(signedProgress)
            }
    }

    // MARK: - Navigation + Toolbar

    private var navigationContent: some View {
        NavigationStack {
            mainContent
                .navigationTitle("PhoXiv")
                .toolbarTitleDisplayMode(.inlineLarge)
                .toolbar { toolbarContent }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            HeadTrackingToggle(
                isEnabled: isTrackingEnabled,
                onTap: handleToggleTapped
            )
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        ZStack {
            AmbientBackground(topItem: stack.topCard)
            stackOrEmptyState

            if hintVisible && !hasInteracted && !isAllDone {
                SwipeHint()
            }
        }
    }

    @ViewBuilder
    private var stackOrEmptyState: some View {
        VStack {
            if isAllDone {
                AllDoneView {
                    withAnimation { stack.reset(with: imageMock) }
                }
            } else {
                cardStack
                recenterButtonIfNeeded
            }
        }
    }

    private var cardStack: some View {
        ArchiveStackView(viewModel: stack) { item, progress, direction in
            PhotoCard(item: item, progress: progress, direction: direction)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var recenterButtonIfNeeded: some View {
        if isTrackingEnabled && head.state.calibration == .ready {
            RecenterButton(
                calibration: head.state.calibration,
                needsRecenter: head.state.needsRecenter,
                onTap: { head.beginCalibration() }
            )
        }
    }

    // MARK: - Priming Flow

    private func handleToggleTapped() {
        if isTrackingEnabled {
            isTrackingEnabled = false
            head.stop()
            return
        }

        guard head.isSupported else {
            showingUnsupportedAlert = true
            return
        }

        switch head.cameraPermissionStatus {
        case .authorized:
            Task { await enableHeadTracking() }
        case .denied, .restricted:
            showingDeniedAlert = true
        case .notDetermined:
            showingPrimingAlert = true
        @unknown default:
            showingPrimingAlert = true
        }
    }

    private func enableHeadTracking() async {
        isTrackingEnabled = true
        await head.start()
        head.beginCalibration()
    }

    // MARK: - Head Tilt → Card Bridge

    private func handleHeadProgressChanged(_ signedProgress: Float) {
        guard isTrackingEnabled else { return }
        guard head.state.calibration == .ready else { return }
        guard stack.poppedCard == nil else { return }
        guard !isCommitting else { return }
        guard !stack.isUserDragging else { return }
        guard !isAllDone else { return }

        let translationX = CGFloat(signedProgress) * maxHeadTranslation
        let commitDistance = maxHeadTranslation * commitFraction

        if abs(translationX) >= commitDistance {
            commitToEdge(direction: translationX > 0 ? .right : .left)
        } else {
            trackHeadProgress(translationX: translationX)
        }
    }

    private func commitToEdge(direction: CardSwipeDirection) {
        isCommitting = true

        withAnimation(.spring(response: 0.6, dampingFraction: 0.92)) {
            stack.updateDrag(translation: CGSize(
                width: direction == .right ? maxHeadTranslation : -maxHeadTranslation,
                height: 0
            ))
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            head.suppressBriefly()
            stack.commitSwipe(direction: direction)
            isCommitting = false
        }
    }

    private func trackHeadProgress(translationX: CGFloat) {
        withAnimation(.spring(response: 1.0, dampingFraction: 0.85)) {
            stack.updateDrag(translation: CGSize(width: translationX, height: 0))
        }
    }

    // MARK: - Hint Dismissal

    private func dismissHint() {
        guard !hasInteracted else { return }
        hasInteracted = true
        withAnimation(.easeOut(duration: 0.4)) {
            hintVisible = false
        }
    }
}

// MARK: - Alerts Modifier

/// Bundles the three alerts into a single modifier so the main view's
/// type doesn't balloon with three chained .alert modifiers.
private struct AlertsModifier: ViewModifier {
    @Binding var showingPrimingAlert: Bool
    @Binding var showingDeniedAlert: Bool
    @Binding var showingUnsupportedAlert: Bool
    let onEnable: () -> Void

    func body(content: Content) -> some View {
        content
            .alert("Enable head tilt?", isPresented: $showingPrimingAlert) {
                Button("Not now", role: .cancel) { }
                Button("Enable", action: onEnable)
            } message: {
                Text("Tilt your head left to archive, right to keep. PhoXiv uses the front camera on-device to track head movement.")
            }
            .alert("Camera access needed", isPresented: $showingDeniedAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Open Settings", action: openSettings)
            } message: {
                Text("PhoXiv needs camera access to detect head tilts. You can enable it in Settings.")
            }
            .alert("Not available on this device", isPresented: $showingUnsupportedAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Head tilt requires a device with a TrueDepth camera, like iPhone X or later. You can still swipe cards with your finger.")
            }
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    ArchiveView()
}
