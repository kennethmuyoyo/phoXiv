//
//  SortView.swift
//  phoXiv
//
//  Created by Kenneth Muyoyo on 21/04/26.
//
//  Orchestrator for the sorting experience. Owns the CardStackViewModel and
//  HeadTiltViewModel, coordinates them, and delegates all card rendering to
//  ArchiveStackView. Two input sources (finger drag and head tilt) both feed
//  into the same CardStackViewModel.updateDrag/endDrag pipeline.
//

import SwiftUI
import AVFoundation
import Photos

struct SortView: View {

    // The shared library of images. Unsorted images feed the card stack;
    // swipe commits update sorted/archived flags here.
    @EnvironmentObject var vm: LibraryViewModel

    // The card stack view model — owns the item list, drag state, and commit logic.
    // Initialized empty; populated when vm.images loads.
    @State private var stack = CardStackViewModel<ImageItem>(items: [])

    // The head tilt view model — tracks head roll via ARKit and outputs signedProgress.
    @State private var head = HeadTiltViewModel()

    // Whether head tracking is currently active. Starts disabled;
    // user must opt in via the toolbar toggle.
    @State private var isTrackingEnabled = false

    // Persisted flag so the swipe hint only shows on the very first session.
    @AppStorage("hasInteractedWithArchive") private var hasInteracted = false

    // Controls visibility of the "swipe to sort" hint overlay.
    @State private var hintVisible = true

    // Alert presentation flags for the head tracking priming flow.
    @State private var showingPrimingAlert = false     // "Enable head tilt?" prompt
    @State private var showingDeniedAlert = false      // camera permission denied
    @State private var showingUnsupportedAlert = false  // no TrueDepth camera

    // Multiplier that converts head tilt progress (-1…+1) into a card translation
    // in points. Higher = card moves further per degree of tilt, but requires
    // a bigger tilt to reach the commit threshold (150pt from CardConfig).
    private let headTranslationScale: CGFloat = 400

    // True when all cards have been sorted and the pop animation has finished.
    private var isAllDone: Bool {
        stack.items.isEmpty && stack.poppedCard == nil
    }

    // MARK: - Body

    var body: some View {
        navigationContent
            // Attach the three head-tracking alerts via a modifier to keep the body clean.
            .modifier(AlertsModifier(
                showingPrimingAlert: $showingPrimingAlert,
                showingDeniedAlert: $showingDeniedAlert,
                showingUnsupportedAlert: $showingUnsupportedAlert,
                onEnable: { Task { await enableHeadTracking() } }
            ))
            // Wire up the swipe commit callback. When a card is swiped,
            // mark it as sorted and set archived based on direction.
            .onAppear {
                let service = ImageService()
                stack.onSwipeCommitted = { item, direction in
                    service.sortImage(asset: item.asset, direction: direction, vm: vm)
                }
            }
            // When the library finishes loading images, populate the stack
            // with unsorted images (only if the stack is currently empty).
            .onChange(of: vm.images) { _, _ in
                if stack.items.isEmpty {
                    stack.reset(with: vm.unsortedImages)
                }
            }
            // Stop the AR session when leaving this screen.
            .onDisappear { head.stop() }
            // Dismiss the hint when the user starts dragging with their finger.
            .onChange(of: stack.isUserDragging) { _, dragging in
                if dragging { dismissHint() }
            }
            // Dismiss the hint when a card is popped (swiped away).
            .onChange(of: stack.poppedCard) { oldValue, newValue in
                if oldValue == nil && newValue != nil { dismissHint() }
            }
            // React to head tilt progress changes and feed them into the card stack.
            .onChange(of: head.state.signedProgress) { _, signedProgress in
                handleHeadProgressChanged(signedProgress)
            }
    }

    // MARK: - Navigation + Toolbar

    // Wraps the main content in a NavigationStack with title and toolbar.
    private var navigationContent: some View {
        NavigationStack {
            mainContent
                .navigationTitle("PhoXiv")
                .toolbarTitleDisplayMode(.inlineLarge)
                .toolbar { toolbarContent }
        }
    }

    // The toolbar button that toggles head tracking on/off.
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

    // Layers: blurred ambient background → card stack or empty state → swipe hint.
    private var mainContent: some View {
        ZStack {
            // Blurred version of the top card's image as the background.
            AmbientBackground(topItem: stack.topCard)

            // Either the card stack, a loading spinner, or the "all done" screen.
            stackOrEmptyState

            // First-time hint overlay — disappears after the first interaction.
            if hintVisible && !hasInteracted && !isAllDone {
                SwipeHint()
            }
        }
    }

    // True while the library is still fetching images from Photos.
    // Prevents flashing the "all done" screen before images load.
    private var isLoading: Bool {
        vm.images.isEmpty && (vm.authorizationStatus == .notDetermined || vm.authorizationStatus == .authorized || vm.authorizationStatus == .limited)
    }

    // Shows a spinner while loading, the card stack when ready,
    // or the "all done" screen when every image has been sorted.
    @ViewBuilder
    private var stackOrEmptyState: some View {
        VStack {
            if isLoading {
                ProgressView()   // still fetching from Photos library
            } else if isAllDone {
                // All cards sorted — offer to reload unsorted images.
                AllDoneView {
                    withAnimation { stack.reset(with: vm.unsortedImages) }
                }
            } else {
                cardStack                // the swipeable card stack
                recenterButtonIfNeeded   // "recenter" button for head tracking
            }
        }
    }

    // The ArchiveStackView configured with PhotoCard as the card content.
    private var cardStack: some View {
        SortStackView(viewModel: stack) { item, progress, direction in
            PhotoCard(item: item, progress: progress, direction: direction)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // Shows the recenter button only when head tracking is active and calibrated.
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

    // Handles the head tracking toggle button tap.
    // If tracking is on, turns it off. Otherwise, checks device support
    // and camera permission before enabling.
    private func handleToggleTapped() {
        // If currently enabled, disable and stop the AR session.
        if isTrackingEnabled {
            isTrackingEnabled = false
            head.stop()
            return
        }

        // Check hardware support first.
        guard head.isSupported else {
            showingUnsupportedAlert = true
            return
        }

        // Route based on current camera permission status.
        switch head.cameraPermissionStatus {
        case .authorized:
            // Permission already granted — start immediately.
            Task { await enableHeadTracking() }
        case .denied, .restricted:
            // Permission denied — show alert with Settings link.
            showingDeniedAlert = true
        case .notDetermined:
            // Never asked — show the priming alert first.
            showingPrimingAlert = true
        @unknown default:
            showingPrimingAlert = true
        }
    }

    // Starts the AR session. Calibration begins automatically when the
    // first face anchor arrives (handled inside HeadTiltViewModel).
    private func enableHeadTracking() async {
        isTrackingEnabled = true
        await head.start()
    }

    // MARK: - Head Tilt → Card Bridge

    // Translates head tilt progress into card drag input.
    // Uses the exact same updateDrag/endDrag pipeline as finger swipes.
    private func handleHeadProgressChanged(_ signedProgress: Float) {
        // Only process if tracking is on and calibration is complete.
        guard isTrackingEnabled, head.state.calibration == .ready else { return }

        // Block input until the user has returned their head to neutral after a commit.
        guard !head.state.needsRecenter else { return }

        // Don't interfere with finger drags, active pop animations, or empty stack.
        guard stack.poppedCard == nil, !stack.isUserDragging, !isAllDone else { return }

        // Convert signed progress (-1…+1) to a translation in points.
        let translation = CGSize(width: CGFloat(signedProgress) * headTranslationScale, height: 0)

        // Feed the translation into the card stack — same path as finger drags.
        // Spring animation makes the card follow smoothly rather than snapping.
        withAnimation(.spring(response: 0.8, dampingFraction: 0.9)) {
            stack.updateDrag(translation: translation)
        }

        // If the card has crossed the commit threshold, commit the swipe.
        // suppressBriefly() blocks further input until the head returns to neutral.
        if stack.hasCrossedThreshold {
            head.suppressBriefly()
            stack.endDrag(translation: translation)
        }
    }

    // MARK: - Hint Dismissal

    // Hides the first-time swipe hint and persists the flag so it never shows again.
    private func dismissHint() {
        guard !hasInteracted else { return }
        hasInteracted = true
        withAnimation(.easeOut(duration: 0.4)) {
            hintVisible = false
        }
    }
}

// MARK: - Alerts Modifier

// Bundles the three head-tracking alerts into one modifier so the main
// body doesn't balloon with three chained .alert modifiers.
private struct AlertsModifier: ViewModifier {
    @Binding var showingPrimingAlert: Bool      // "Enable head tilt?" prompt
    @Binding var showingDeniedAlert: Bool       // camera permission denied
    @Binding var showingUnsupportedAlert: Bool  // no TrueDepth camera
    let onEnable: () -> Void                   // callback when user taps "Enable"

    func body(content: Content) -> some View {
        content
            // Priming alert — explains what head tilt does and asks permission.
            .alert("Enable head tilt?", isPresented: $showingPrimingAlert) {
                Button("Not now", role: .cancel) { }
                Button("Enable", action: onEnable)
            } message: {
                Text("Tilt your head left to archive, right to keep. PhoXiv uses the front camera on-device to track head movement.")
            }
            // Denied alert — directs user to Settings to grant camera access.
            .alert("Camera access needed", isPresented: $showingDeniedAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Open Settings", action: openSettings)
            } message: {
                Text("PhoXiv needs camera access to detect head tilts. You can enable it in Settings.")
            }
            // Unsupported alert — device lacks TrueDepth camera.
            .alert("Not available on this device", isPresented: $showingUnsupportedAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Head tilt requires a device with a TrueDepth camera, like iPhone X or later. You can still swipe cards with your finger.")
            }
    }

    // Opens the system Settings app to the app's permission page.
    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    SortView()
}
