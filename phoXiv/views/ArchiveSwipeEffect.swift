//
//  ArchiveSwipeEffect.swift
//  PhotoRecreate
//
//  Created by Kenneth Muyoyo on 20/04/26.
//

import SwiftUI

// Applies a stack-position-dependent visual transform to a card in the archive stack.
//
// Index 0 is the top card — it follows the drag and tilts.
// Indices 1–3 sit beneath in tiers; as the top card is dragged away, each tier
// rises up and scales toward the next position, pre-animating into place.
// Indices 4+ are hidden so they don't affect layout.
//
// The numeric constants (offsets and scale ranges) are tuning values, chosen
// to make the stack feel like a physical deck of cards. Adjust to taste.
struct ArchiveSwipeEffect: ViewModifier {
    let index: Int
    let offset: CGPoint
    let triggerThreshold: CGFloat

    func body(content: Content) -> some View {
        switch index {
        case 0:
            // Top card: follows the finger, tilts proportional to horizontal drag.
            // Anchor the rotation at the bottom so the card pivots from its base
            // (the top of the card sweeps wider than the bottom).
            let angle = Angle(degrees: Double(offset.x) / 20)
            content
                .offset(x: offset.x, y: offset.y)
                .rotationEffect(angle, anchor: .bottom)
                .zIndex(4)

        case 1:
            // Second card: rises from 50pt below to 0pt as drag progresses.
            // Scales from 0.9 up to 1.0 (the top card's resting scale).
            let progress = normalizedProgress
            content
                .offset(y: (1 - progress) * 50)
                .scaleEffect(0.9 + progress * 0.1)
                .zIndex(3)

        case 2:
            // Third card: rises from 110pt below to 50pt below.
            // Scales from 0.8 up to 0.9 (where the second card was at rest).
            let progress = normalizedProgress
            content
                .offset(y: 110 - progress * 60)
                .scaleEffect(0.8 + progress * 0.1)
                .zIndex(2)

        case 3:
            // Fourth card: only visible when the top card is being actively dragged.
            // Rises from 180pt below to 110pt below, scales from 0.7 to 0.8.
            // Opacity fades in with progress so the card doesn't pop into existence
            // when the third tier promotes to second.
            let progress = normalizedProgress
            content
                .opacity(progress)
                .offset(y: 180 - progress * 70)
                .scaleEffect(0.7 + progress * 0.1)
                .zIndex(1)

        default:
            // Beyond the visible stack — render invisibly so layout is unaffected.
            content.opacity(0)
        }
    }

    // Normalized 0...1 drag progress used for interpolating cards below the top.
    private var normalizedProgress: CGFloat {
        min(abs(offset.x) / triggerThreshold, 1)
    }
}
