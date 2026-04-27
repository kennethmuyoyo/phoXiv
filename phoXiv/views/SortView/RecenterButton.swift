//
//  RecenterButton.swift
//  phoXiv
//
//  Pill button for recentering the head tilt calibration. Shows contextual
//  labels based on the calibration state — "Recenter", "Return to center"
//  (after a commit), "Calibrating…". The parent controls visibility by
//  choosing whether to render it at all.
//

import SwiftUI

struct RecenterButton: View {
    let calibration: HeadCalibrationState
    let needsRecenter: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: "scope")
                Text(label)
            }
            .font(.caption.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: Capsule())
        }
        .disabled(calibration == .calibrating)
        .padding(.bottom, 8)
    }

    private var label: String {
        switch calibration {
        case .uncalibrated: return "Start tracking"
        case .calibrating: return "Calibrating…"
        case .ready:
            return needsRecenter ? "Return to center" : "Recenter"
        case .failed: return "Unavailable"
        }
    }
}
