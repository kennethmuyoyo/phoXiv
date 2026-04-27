//
//  SwipeHint.swift
//  phoXiv
//
//  First-run hint that teaches users which direction means what. Two
//  asymmetric pills: red "Archive ←" on the left, green "Keep →" on the
//  right. Pure presentation — parent controls when to show and hide it.
//

import SwiftUI

struct SwipeHint: View {
    var body: some View {
        HStack(spacing: 16) {
            HintPill(label: "Archive", systemImage: "chevron.left", color: .red, direction: .leading)
            HintPill(label: "Keep", systemImage: "chevron.right", color: .green, direction: .trailing)
        }
        .offset(y: -150)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
}

private struct HintPill: View {
    let label: String
    let systemImage: String
    let color: Color
    let direction: Direction

    enum Direction { case leading, trailing }

    var body: some View {
        HStack(spacing: 6) {
            if direction == .leading {
                Image(systemName: systemImage)
                Text(label)
            } else {
                Text(label)
                Image(systemName: systemImage)
            }
        }
        .font(.subheadline.bold())
        .foregroundStyle(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(color.opacity(0.85), in: Capsule())
    }
}
