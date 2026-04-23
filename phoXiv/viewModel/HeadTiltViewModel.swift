//
//  HeadTiltViewModel.swift
//  phoXiv
//

import Foundation
import SwiftUI
import ARKit
import AVFoundation
import Combine

/// Continuous head-tilt tracking using ARKit face anchor's roll component.
///
/// The view model publishes a smoothed, calibrated signed progress value.
/// A deadzone near neutral absorbs sensor noise and small natural head
/// movements, so the card sits completely still when the user isn't
/// deliberately tilting. After a commit, the user must return their head
/// near neutral before the next swipe is accepted.
@MainActor
@Observable
final class HeadTiltViewModel: NSObject {

    private(set) var state: HeadTiltState = .initial

    // MARK: - Tunables

    var headTiltMax: Float = 0.25
    var deadzone: Float = 0.10
    var recenterThreshold: Float = 0.40
    var minSuppressionTime: TimeInterval = 0.4
    var smoothingMix: Float = 0.03
    var publishInterval: TimeInterval = 0.10
    var calibrationDuration: TimeInterval = 1.0

    // MARK: - Private

    private let session = ARSession()
    private var smoothedSignedProgress: Float = 0
    private var lastPublishedAt: Date = .distantPast
    private var calibrationStartedAt: Date?
    private var calibrationSamples: [Float] = []
    private var neutralRoll: Float = 0
    private var minSuppressionUntil: Date = .distantPast
    private var trackedAnchorID: UUID?

    // MARK: - Capability Checks (synchronous, no side effects)

    /// True if the device supports face tracking at all. iPhone X and later,
    /// recent iPads Pro. Returns false in the simulator.
    var isSupported: Bool {
        ARFaceTrackingConfiguration.isSupported
    }

    /// Current camera permission status. Reading this does not trigger any
    /// prompt — use `start()` only after confirming the user wants to proceed.
    var cameraPermissionStatus: AVAuthorizationStatus {
        AVCaptureDevice.authorizationStatus(for: .video)
    }

    // MARK: - Lifecycle

    /// Starts the AR session. Assumes camera permission check has been
    /// handled by the caller — this will trigger the system prompt if the
    /// status is `.notDetermined`.
    func start() async {
        guard isSupported else {
            state.calibration = .failed(reason: "Face tracking not supported on this device")
            return
        }

        let granted = await AVCaptureDevice.requestAccess(for: .video)
        guard granted else {
            state.calibration = .failed(reason: "Camera permission denied")
            return
        }

        let config = ARFaceTrackingConfiguration()
        config.isLightEstimationEnabled = false
        session.delegate = self
        session.run(config, options: [.resetTracking, .removeExistingAnchors])
    }

    func stop() {
        session.pause()
        trackedAnchorID = nil
        state.signedProgress = 0
        state.needsRecenter = false
        state.calibration = .uncalibrated
    }

    func beginCalibration() {
        calibrationSamples.removeAll(keepingCapacity: true)
        calibrationStartedAt = Date()
        trackedAnchorID = nil
        state.calibration = .calibrating
        state.needsRecenter = false
    }

    func suppressBriefly() {
        smoothedSignedProgress = 0
        state.signedProgress = 0
        state.needsRecenter = true
        minSuppressionUntil = Date().addingTimeInterval(minSuppressionTime)
    }

    // MARK: - Frame Processing

    private func handleFaceAnchor(_ anchor: ARFaceAnchor) {
        // Lock to one face: during calibration, adopt the first face we see.
        // After that, ignore any other faces in frame.
        if state.calibration == .calibrating && trackedAnchorID == nil {
            trackedAnchorID = anchor.identifier
        }
        if let tracked = trackedAnchorID, anchor.identifier != tracked {
            return
        }

        let rawRoll = extractRoll(from: anchor.transform)

        switch state.calibration {
        case .uncalibrated, .failed:
            return

        case .calibrating:
            calibrationSamples.append(rawRoll)
            if let startedAt = calibrationStartedAt,
               Date().timeIntervalSince(startedAt) >= calibrationDuration {
                finishCalibration()
            }

        case .ready:
            let deviation = rawRoll - neutralRoll
            let absDeviation = abs(deviation)

            if state.needsRecenter {
                let pastMinTime = Date() >= minSuppressionUntil
                let isNeutral = absDeviation < recenterThreshold
                if pastMinTime && isNeutral {
                    state.needsRecenter = false
                } else {
                    return
                }
            }

            let targetProgress: Float
            if absDeviation <= deadzone {
                targetProgress = 0
            } else {
                let sign: Float = deviation > 0 ? 1 : -1
                let adjustedDeviation = absDeviation - deadzone
                let adjustedMax = headTiltMax - deadzone
                let normalized = adjustedDeviation / adjustedMax
                targetProgress = sign * min(1, normalized)
            }

            smoothedSignedProgress = smoothedSignedProgress * (1 - smoothingMix)
                                   + targetProgress * smoothingMix

            if Date().timeIntervalSince(lastPublishedAt) >= publishInterval {
                state.signedProgress = smoothedSignedProgress
                lastPublishedAt = Date()
            }
        }
    }

    private func finishCalibration() {
        guard !calibrationSamples.isEmpty else {
            state.calibration = .failed(reason: "No face detected during calibration")
            return
        }
        neutralRoll = calibrationSamples.reduce(0, +) / Float(calibrationSamples.count)
        calibrationStartedAt = nil
        calibrationSamples.removeAll(keepingCapacity: true)
        state.calibration = .ready
    }

    private func extractRoll(from transform: simd_float4x4) -> Float {
        let m00 = transform.columns.0.x
        let m01 = transform.columns.1.x
        return atan2(m01, m00)
    }
}

// MARK: - ARSessionDelegate

extension HeadTiltViewModel: ARSessionDelegate {
    nonisolated func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        guard let faceAnchor = anchors.compactMap({ $0 as? ARFaceAnchor }).first else { return }
        Task { @MainActor in
            self.handleFaceAnchor(faceAnchor)
        }
    }
}

/// States for headtilting
struct HeadTiltState: Equatable {
    var signedProgress: Float = 0
    var calibration: HeadCalibrationState = .uncalibrated
    /// True when the user must return their head to neutral before the next
    /// swipe will be accepted. Useful for showing UI feedback like "Recenter".
    var needsRecenter: Bool = false

    static let initial = HeadTiltState()
}

enum HeadCalibrationState: Equatable {
    case uncalibrated
    case calibrating
    case ready
    case failed(reason: String)
}
