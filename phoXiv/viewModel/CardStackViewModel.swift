//
//  CardStackViewModel.swift
//  phoXiv
//
//  Created by Kenneth Muyoyo on 21/04/26.
//

import SwiftUI

/// Manages a stack of swipeable cards. Owns the item list, tracks drag state,
/// decides when a swipe commits, and coordinates the fly-away animation.
///
/// Generic over any Identifiable & Hashable item type so it works for
/// image cards, profile cards, or anything else.
///
/// Both finger drags and head tilt feed into the same updateDrag/endDrag
/// pipeline — the view model doesn't care about the input source.
@MainActor
@Observable
final class CardStackViewModel<Item: Identifiable & Hashable> {

    // The ordered list of cards still in the stack. The first item is the top card.
    var items: [Item]

    // The item currently on top of the stack, or nil if the stack is empty.
    // private(set) = only this class can change it; views can read it.
    private(set) var topCard: Item?

    // How far the top card has been dragged from its resting position (in points).
    // The view reads this to position and rotate the card.
    private(set) var dragOffset: CGPoint = .zero

    // Which direction the card is currently being dragged: .left, .right, or .idle.
    // Used by the view to show KEEP/ARCHIVE overlays.
    private(set) var lastDirection: CardSwipeDirection = .idle

    // True when the drag distance exceeds the commit threshold.
    // The head tilt bridge reads this to know when to trigger a commit.
    private(set) var hasCrossedThreshold: Bool = false

    // The card currently animating off-screen after a commit, or nil.
    // The view renders this in an overlay so the next card is already interactive.
    private(set) var poppedCard: PoppedCard<Item>?

    // True while the user's finger is actively touching/dragging.
    // The head tilt bridge checks this to avoid conflicting with finger input.
    private(set) var isUserDragging: Bool = false

    // MARK: - Callbacks

    // Fired after a swipe commits. The parent uses this to update model state
    // (e.g., mark an image as archived or kept).
    var onSwipeCommitted: ((Item, CardSwipeDirection) -> Void)?

    // Tunable parameters (threshold, minimum drag distance, visible card count).
    let configuration: CardConfig

    // MARK: - Init

    init(
        items: [Item],
        configuration: CardConfig = .init()
    ) {
        self.items = items             // store the full card list
        self.topCard = items.first     // the first item is on top
        self.configuration = configuration
    }

    // MARK: - Drag Handling

    // Called continuously as the user drags (finger or head tilt).
    // Updates the card's position, direction, and threshold state.
    func updateDrag(translation: CGSize) {
        // Subtract the DragGesture's minimumDistance so the card doesn't
        // jump when the gesture first activates (see dragCorrection docs).
        let correctedX = translation.width + dragCorrection(for: translation.width)

        // Only allow vertical movement if configured (off by default).
        let y = configuration.animateOnYAxis ? translation.height : 0

        // Update the offset that the view reads for positioning.
        dragOffset = CGPoint(x: correctedX, y: y)

        // Determine direction from the corrected horizontal offset.
        lastDirection = CardSwipeDirection(offset: correctedX)

        // Check if the drag has crossed the commit threshold.
        let crossed = abs(correctedX) >= configuration.dragTriggerThreshold
        if crossed != hasCrossedThreshold {
            hasCrossedThreshold = crossed
        }
    }

    // Called when the user lifts their finger (or head tilt triggers a commit).
    // If past the threshold, commits the swipe. Otherwise springs the card back.
    func endDrag(translation: CGSize) {
        if abs(translation.width) < configuration.dragTriggerThreshold {
            // Didn't drag far enough — bounce the card back to center.
            withAnimation(.bouncy) {
                dragOffset = .zero
            }
            hasCrossedThreshold = false
            lastDirection = .idle
        } else {
            // Past the threshold — commit the swipe in the current direction.
            commitSwipe(direction: lastDirection)
        }
    }

    // Called by the view when the user's finger first touches down.
    // Lets the head tilt bridge know to back off.
    func touchDragBegan() {
        isUserDragging = true
    }

    // Called by the view when the user lifts their finger.
    func touchDragEnded() {
        isUserDragging = false
    }

    // MARK: - Commit

    // Removes the top card from the stack and starts its fly-away animation.
    //
    // direction: which side the card flies off (.left or .right). .idle is a no-op.
    // notifyCaller: when false, skips the onSwipeCommitted callback. Used for
    //   programmatic swipes where the parent already knows about the action.
    func commitSwipe(direction: CardSwipeDirection, notifyCaller: Bool = true) {
        // Don't commit if direction is idle or the stack is empty.
        guard direction != .idle, !items.isEmpty else { return }

        // Remove the top card from the items array.
        let popped = items.removeFirst()

        // Record the direction for the fly-away animation.
        lastDirection = direction

        // Create the popped card with its current offset so the fly-away
        // animation starts from where the card currently is, not from zero.
        poppedCard = PoppedCard(
            item: popped,
            initialOffset: dragOffset,
            direction: direction
        )

        // Reset drag state for the next card WITHOUT animation.
        // disablesAnimations prevents the stack from visually interpolating
        // positions during the handoff between cards.
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            topCard = items.first       // next card becomes top (or nil if empty)
            dragOffset = .zero          // reset drag to center
            hasCrossedThreshold = false // reset threshold flag
        }

        // Notify the parent so it can update model state (archive/keep).
        if notifyCaller {
            onSwipeCommitted?(popped, direction)
        }
    }

    // Called by the view once the popped card's fly-away animation finishes.
    // Clears the popped slot so the next card becomes fully interactive.
    func completePopAnimation() {
        poppedCard = nil
    }

    // MARK: - Reset

    // Replaces all items at once and resets all drag state.
    // Used when loading fresh data or when the user taps "Start Over".
    func reset(with newItems: [Item]) {
        items = newItems                // replace the full list
        topCard = newItems.first        // first item on top
        dragOffset = .zero              // no drag in progress
        lastDirection = .idle           // no direction
        hasCrossedThreshold = false     // not past threshold
        poppedCard = nil                // no fly-away in progress
    }

    // MARK: - Drag Correction

    // Cancels out the initial jump caused by DragGesture(minimumDistance:).
    //
    // DragGesture(minimumDistance: 20) doesn't fire onChanged until the finger
    // has moved 20pt — but when it does, translation.width is already 20.
    // Without correction the card would jump 20pt the moment the gesture starts.
    // This subtracts that minimum back out so movement starts from zero.
    private func dragCorrection(for translation: CGFloat) -> CGFloat {
        let min = configuration.minimumDragDistance
        if translation >= min { return -min }    // dragging right: subtract minimum
        if translation <= -min { return min }    // dragging left: add minimum back
        return -translation                      // within minimum: cancel out entirely
    }
}
