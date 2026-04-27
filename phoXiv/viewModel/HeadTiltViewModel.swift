//
//  HeadTiltViewModel.swift
//  phoXiv
//

import Foundation
import SwiftUI
import ARKit          // ARSession, ARFaceTrackingConfiguration, ARFaceAnchor
import AVFoundation   // AVCaptureDevice for camera permission checks
import Combine

/// Tracks the user's head tilt via ARKit's face anchor roll angle and
/// outputs a smoothed signed progress value (-1 … +1) that the card
/// stack uses as a drag input. Handles calibration, deadzone filtering,
/// face locking, and post-swipe suppression.
@MainActor
@Observable
final class HeadTiltViewModel: NSObject {

    // The published state that views read to drive UI and card movement.
    private(set) var state: HeadTiltState = .initial

    // MARK: - Tunables

    // Maximum roll angle (radians) that maps to ±1.0 progress.
    // ~14° of tilt reaches full progress.
    var headTiltMax: Float = 0.25

    // Roll deviations smaller than this (radians, ~6°) are treated as zero.
    // Prevents casual head movement from moving the card.
    var deadzone: Float = 0.10

    // How close to neutral (radians) the head must return before the next
    // swipe is accepted after a commit.
    var recenterThreshold: Float = 0.40

    // Minimum wait time (seconds) after a commit before accepting input again,
    // even if the head is already back at neutral.
    var minSuppressionTime: TimeInterval = 0.8

    // Exponential smoothing blend factor. Lower = smoother/slower response.
    // At 0.02, only 2% of each new reading blends in per frame.
    var smoothingMix: Float = 0.02

    // Minimum interval between publishing new signedProgress values to the view.
    // Prevents excessive SwiftUI re-renders.
    var publishInterval: TimeInterval = 0.10

    // How long (seconds) the calibration phase collects samples to establish
    // the user's neutral head position.
    var calibrationDuration: TimeInterval = 1.0

    // MARK: - Private

    // The ARKit session that delivers face anchor updates.
    private let session = ARSession()

    // Running smoothed value that gets published at publishInterval.
    private var smoothedSignedProgress: Float = 0

    // Timestamp of the last publish to enforce publishInterval throttling.
    private var lastPublishedAt: Date = .distantPast

    // When calibration started — used to measure the calibrationDuration window.
    private var calibrationStartedAt: Date?

    // Raw roll samples collected during calibration to compute the average neutral.
    private var calibrationSamples: [Float] = []

    // The user's neutral roll angle, computed as the mean of calibration samples.
    // All subsequent deviations are measured relative to this baseline.
    private var neutralRoll: Float = 0

    // Earliest time after a commit that new input will be accepted.
    private var minSuppressionUntil: Date = .distantPast

    // The UUID of the face anchor we locked onto during calibration.
    // Any other face anchor (bystanders, etc.) is ignored.
    private var trackedAnchorID: UUID?

    // MARK: - Capability Checks

    // True if the device has a TrueDepth camera (iPhone X+, iPad Pro).
    // Returns false in the simulator.
    var isSupported: Bool {
        ARFaceTrackingConfiguration.isSupported
    }

    // Current camera permission without triggering a prompt.
    var cameraPermissionStatus: AVAuthorizationStatus {
        AVCaptureDevice.authorizationStatus(for: .video)
    }

    // MARK: - Lifecycle

    // Requests camera access, configures ARKit for face tracking, and starts
    // the session. Calibration begins automatically when the first face anchor
    // arrives (see handleFaceAnchor).
    func start() async {
        // Bail early if hardware doesn't support face tracking.
        guard isSupported else {
            state.calibration = .failed(reason: "Face tracking not supported on this device")
            return
        }

        // Request camera permission. This awaits the user's response if
        // status is .notDetermined; returns immediately otherwise.
        let granted = await AVCaptureDevice.requestAccess(for: .video)
        guard granted else {
            state.calibration = .failed(reason: "Camera permission denied")
            return
        }

        // Create a face-tracking config. Light estimation is off because
        // we only need the face anchor transform, not lighting data.
        let config = ARFaceTrackingConfiguration()
        config.isLightEstimationEnabled = false

        // Wire up the delegate so we receive anchor updates, then start.
        // resetTracking + removeExistingAnchors ensures a clean slate.
        session.delegate = self
        session.run(config, options: [.resetTracking, .removeExistingAnchors])
    }

    // Pauses the AR session and resets all internal state back to initial.
    // After calling stop(), start() can be called again for a fresh session.
    func stop() {
        session.pause()                        // stop receiving face updates
        trackedAnchorID = nil                  // forget which face we were tracking
        smoothedSignedProgress = 0             // clear the running smooth value
        lastPublishedAt = .distantPast         // allow immediate publish on restart
        calibrationStartedAt = nil             // no calibration in progress
        calibrationSamples.removeAll()         // discard any partial samples
        neutralRoll = 0                        // clear the baseline
        minSuppressionUntil = .distantPast     // no active suppression
        state = .initial                       // reset published state to defaults
    }

    // Starts (or restarts) the calibration phase. Collects roll samples for
    // calibrationDuration seconds to establish the neutral head position.
    // Also called by the recenter button in the UI.
    func beginCalibration() {
        calibrationSamples.removeAll(keepingCapacity: true)  // clear old samples
        calibrationStartedAt = Date()                        // mark start time
        trackedAnchorID = nil                                // allow locking a new face
        state.calibration = .calibrating                     // tell the UI we're calibrating
        state.needsRecenter = false                          // clear any stale recenter flag
    }

    // Called after a swipe commits. Zeroes out progress immediately and
    // sets needsRecenter so the bridge won't feed input to the card stack
    // until the user returns their head to neutral AND minSuppressionTime passes.
    func suppressBriefly() {
        smoothedSignedProgress = 0                                     // zero the smooth value
        state.signedProgress = 0                                       // zero the published value
        state.needsRecenter = true                                     // block further input
        minSuppressionUntil = Date().addingTimeInterval(minSuppressionTime) // enforce cooldown
    }

    // MARK: - Frame Processing

    // Called for every face anchor update from ARKit (~60fps).
    // Routes through calibration or tracking depending on current state.
    private func handleFaceAnchor(_ anchor: ARFaceAnchor) {

        // --- Face locking ---
        // During calibration, lock onto the first face we see.
        if state.calibration == .calibrating && trackedAnchorID == nil {
            trackedAnchorID = anchor.identifier
        }
        // If we've locked a face, reject updates from any other face.
        if let tracked = trackedAnchorID, anchor.identifier != tracked {
            return
        }

        // Extract the roll angle (left/right head tilt) from the 4x4 transform.
        let rawRoll = extractRoll(from: anchor.transform)

        switch state.calibration {

        // Session just started — first face anchor triggers calibration automatically.
        case .uncalibrated:
            beginCalibration()
            return

        // Something went wrong — ignore all input.
        case .failed:
            return

        // Collecting samples to find the user's neutral head position.
        case .calibrating:
            // Accumulate this frame's roll value.
            calibrationSamples.append(rawRoll)
            // Check if the calibration window has elapsed.
            if let startedAt = calibrationStartedAt,
               Date().timeIntervalSince(startedAt) >= calibrationDuration {
                finishCalibration()
            }

        // Actively tracking — convert roll into signed progress.
        case .ready:
            // How far the head is tilted from the calibrated neutral.
            let deviation = rawRoll - neutralRoll
            let absDeviation = abs(deviation)

            // --- Post-swipe recenter gate ---
            // After a commit, block input until the head returns near neutral
            // AND the minimum suppression time has passed.
            if state.needsRecenter {
                let pastMinTime = Date() >= minSuppressionUntil
                let isNeutral = absDeviation < recenterThreshold
                if pastMinTime && isNeutral {
                    state.needsRecenter = false  // gate opens, resume tracking
                } else {
                    return  // still waiting — ignore this frame
                }
            }

            // --- Deadzone + normalization ---
            let targetProgress: Float
            if absDeviation <= deadzone {
                // Within deadzone — output zero so the card stays still.
                targetProgress = 0
            } else {
                // Outside deadzone — normalize to -1…+1 range.
                let sign: Float = deviation > 0 ? 1 : -1
                let adjustedDeviation = absDeviation - deadzone     // subtract deadzone so movement starts from 0
                let adjustedMax = headTiltMax - deadzone             // remaining range after deadzone
                let normalized = adjustedDeviation / adjustedMax     // 0…1 within that range
                targetProgress = sign * min(1, normalized)           // clamp to ±1
            }

            // --- Exponential smoothing ---
            // Blend the new target into the running average. Low smoothingMix
            // means slow, stable response; high means fast but jittery.
            smoothedSignedProgress = smoothedSignedProgress * (1 - smoothingMix)
                                   + targetProgress * smoothingMix

            // --- Throttled publishing ---
            // Only push to the view at publishInterval to avoid excessive re-renders.
            if Date().timeIntervalSince(lastPublishedAt) >= publishInterval {
                state.signedProgress = smoothedSignedProgress
                lastPublishedAt = Date()
            }
        }
    }

    // Averages the collected calibration samples to set the neutral baseline.
    // If no samples were collected (no face detected), calibration fails.
    private func finishCalibration() {
        guard !calibrationSamples.isEmpty else {
            state.calibration = .failed(reason: "No face detected during calibration")
            return
        }
        // Mean of all samples = the user's natural resting head roll.
        neutralRoll = calibrationSamples.reduce(0, +) / Float(calibrationSamples.count)
        calibrationStartedAt = nil                            // calibration is done
        calibrationSamples.removeAll(keepingCapacity: true)   // free the sample buffer
        state.calibration = .ready                            // start tracking
    }

    // Extracts the roll angle from a 4x4 transform matrix.
    // Roll = rotation around the Z axis (head tilting left/right).
    // Uses atan2 on the first two elements of the top row.
    private func extractRoll(from transform: simd_float4x4) -> Float {
        let m00 = transform.columns.0.x  // cos(roll)
        let m01 = transform.columns.1.x  // sin(roll)
        return atan2(m01, m00)           // roll angle in radians
    }
}

// MARK: - ARSessionDelegate

extension HeadTiltViewModel: ARSessionDelegate {
    // Called by ARKit whenever face anchors update (typically ~60fps).
    // nonisolated because ARKit calls this from its own thread.
    // We hop to MainActor to safely mutate @Observable state.
    nonisolated func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        // Find the first face anchor in the update batch.
        guard let faceAnchor = anchors.compactMap({ $0 as? ARFaceAnchor }).first else { return }
        // Dispatch to main actor for safe state mutation.
        Task { @MainActor in
            self.handleFaceAnchor(faceAnchor)
        }
    }
}

// MARK: - State Types

/// The observable state that views read from HeadTiltViewModel.
struct HeadTiltState: Equatable {
    // Smoothed head tilt progress: -1.0 (full left) to +1.0 (full right), 0 = neutral.
    var signedProgress: Float = 0
    // Current phase of the calibration lifecycle.
    var calibration: HeadCalibrationState = .uncalibrated
    // True after a commit — the user must return to neutral before the next swipe.
    var needsRecenter: Bool = false

    static let initial = HeadTiltState()
}

/// Calibration lifecycle states.
enum HeadCalibrationState: Equatable {
    case uncalibrated  // session started, waiting for first face anchor
    case calibrating   // collecting samples for calibrationDuration seconds
    case ready         // baseline set, actively tracking
    case failed(reason: String)  // hardware or permission issue
}
