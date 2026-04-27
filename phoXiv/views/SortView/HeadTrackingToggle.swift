//
//  HeadTrackingToggle.swift
//  phoXiv
//
//  Toolbar button in the nav bar that controls head tracking. Takes the
//  current enabled state and a tap handler. The priming flow logic
//  (routing to alerts based on permission status) lives in the parent —
//  this view is just the button UI.
//

import SwiftUI

struct HeadTrackingToggle: View {
    let isEnabled: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Image(systemName: "accessibility")
                .font(.body.bold())
                .foregroundStyle(isEnabled ? .blue : .secondary)
                .symbolEffect(.bounce, value: isEnabled)
        }
        .accessibilityLabel(isEnabled ? "Disable head tracking" : "Enable head tracking")
    }
}
