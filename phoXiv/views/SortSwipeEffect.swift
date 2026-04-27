//
//  ArchiveSwipeEffect.swift
//  phoXiv
//
//  Created by Kenneth Muyoyo on 20/04/26.
//

import SwiftUI

// A ViewModifier that applies stack-position-dependent visual transforms to each card.
//
// Index 0 (top card): follows the drag offset and tilts proportionally.
// Indices 1–3 (cards beneath): sit in stacked tiers below the top card.
//   As the top card is dragged away, each tier rises and scales toward
//   the next position, pre-animating into place for a smooth handoff.
// Index 4+: hidden so they don't consume rendering resources.
//
// All numeric constants are tuning values chosen to feel like a physical
// deck of cards. Adjust to taste.
struct SortSwipeEffect: ViewModifier {

    // Which position in the stack this card occupies (0 = top).
    let index: Int

    // The current drag offset of the top card (in points).
    // Cards beneath use this to calculate their interpolated positions.
    let offset: CGPoint

    // The horizontal distance (in points) needed to commit a swipe.
    // Used to normalize the drag progress to 0…1.
    let triggerThreshold: CGFloat

    func body(content: Content) -> some View {
        switch index {
        case 0:
            // --- Top card ---
            // Moves with the drag offset (follows the finger/head).
            // Tilts proportional to horizontal drag: every 20pt of drag = 1° rotation.
            // Anchored at the bottom so the top of the card sweeps wider than the base,
            // like fanning a card from the bottom of a deck.
            let angle = Angle(degrees: Double(offset.x) / 20)
            content
                .offset(x: offset.x, y: offset.y)         // follow the drag position
                .rotationEffect(angle, anchor: .bottom)    // tilt from the base
                .zIndex(4)                                 // always on top

        case 1:
            // --- Second card ---
            // At rest: 50pt below the top card, scaled to 90%.
            // As the top card drags away (progress 0→1): rises to 0pt offset, scales to 100%.
            // This makes it smoothly take over as the new top card.
            let progress = normalizedProgress
            content
                .offset(y: (1 - progress) * 50)            // 50pt → 0pt
                .scaleEffect(0.9 + progress * 0.1)         // 90% → 100%
                .zIndex(3)

        case 2:
            // --- Third card ---
            // At rest: 110pt below, scaled to 80%.
            // Rises to where the second card was (50pt below, 90% scale).
            let progress = normalizedProgress
            content
                .offset(y: 110 - progress * 60)            // 110pt → 50pt
                .scaleEffect(0.8 + progress * 0.1)         // 80% → 90%
                .zIndex(2)

        case 3:
            // --- Fourth card ---
            // At rest: 180pt below, scaled to 70%, fully transparent.
            // Fades in and rises to where the third card was (110pt below, 80% scale).
            // The opacity fade prevents the card from popping into existence abruptly.
            let progress = normalizedProgress
            content
                .opacity(progress)                         // 0% → 100% opacity
                .offset(y: 180 - progress * 70)            // 180pt → 110pt
                .scaleEffect(0.7 + progress * 0.1)         // 70% → 80%
                .zIndex(1)

        default:
            // --- Beyond visible stack ---
            // Hidden so they don't render or affect layout.
            content.opacity(0)
        }
    }

    // Normalized drag progress (0…1) based on how far the top card has moved
    // relative to the commit threshold. Cards beneath use this to interpolate
    // their position between resting and promoted states.
    private var normalizedProgress: CGFloat {
        min(abs(offset.x) / triggerThreshold, 1)
    }
}
