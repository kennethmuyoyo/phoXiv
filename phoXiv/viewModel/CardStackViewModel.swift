//
//  CardStackViewModel.swift
//  phoXiv
//
//  Created by Kenneth Muyoyo on 21/04/26.
//
import SwiftUI
import Combine
// What do I want to do?
// I want a stack of image cards. The user drags the top one. If they drag far enough, it flies away and the next card becomes the top. If they don't drag far enough, it springs back.

// What should this view model do?
// It owns the list of cards waiting to be sorted, knows which one is on top, tracks the user's current drag, and decides when a swipe is committed.

// A view model exists to serve a view. So question, what does the view need to render, and what does it need to call?
/// It needs to Render the photos in the stack: so it needs photoItems.
/// Animate the top card as it's being dragged: so it needs the current dragOffset.
/// Show "ACHIVED"/"KEEP" overlays based on direction: so it needs lastDirection.
/// Animate a card flying away after a commit: so it needs to know which card was just popped.
/// It will also need to call the view model when The user moves their finger updateDrag(translation:) and The user releases their finger endDrag(translation:)

/// Tunable parameters for the drag gesture.
///
/// Grouped into a single value type so the view model takes one configuration
/// argument rather than five separate parameters. Defaults are sensible for
/// portrait phone screens; override what you need.

 
/// Represents a card that has been removed from the stack and is currently
/// animating off-screen. The view renders this in an overlay so the next card
/// can already be on top and interactive while the popped card flies away.


@MainActor
@Observable
final class CardStackViewModel<Item: Identifiable & Hashable> {
 
    var items: [Item] // can be changed by the parent if needed
    private(set) var topCard: Item? // top item can be empty // se means only this view can change it
    private(set) var dragOffset: CGPoint = .zero // how far the card has been dragged from rest. Starts at 0 and the view uses this to track
    private(set) var lastDirection: CardSwipeDirection = .idle
    private(set) var hasCrossedThreshold: Bool = false
    private(set) var poppedCard: PoppedCard<Item>?
    private(set) var isUserDragging: Bool = false
    

 
    var onSwipeCommitted: ((Item, CardSwipeDirection) -> Void)?
    var onThresholdPassed: (() -> Void)?
    var onStackEmptied: (() -> Void)?

    let configuration: CardConfig
 
    init(
        items: [Item],
        configuration: CardConfig = .init()
    ) {
        self.items = items
        self.topCard = items.first
        self.configuration = configuration
    }
 

    func updateDrag(translation: CGSize) {
        let correctedX = translation.width + dragCorrection(for: translation.width)
        let y = configuration.animateOnYAxis ? translation.height : 0
        dragOffset = CGPoint(x: correctedX, y: y)
 
        let direction = CardSwipeDirection(offset: correctedX)
        if direction != lastDirection {
            lastDirection = direction
        }
 
        let crossed = abs(correctedX) >= configuration.dragTriggerThreshold
        if crossed != hasCrossedThreshold {
            hasCrossedThreshold = crossed
            if crossed {
                onThresholdPassed?()
            }
        }
    }
 
    /// Either commits the swipe or springs the card back to center.
    func endDrag(translation: CGSize) {
        if abs(translation.width) < configuration.dragTriggerThreshold {
            withAnimation(.bouncy) {
                dragOffset = .zero
            }
            hasCrossedThreshold = false
            lastDirection = .idle
        } else {
            commitSwipe(direction: lastDirection)
        }
    }
    
    /// Called by the view when the user starts a touch drag.
    func touchDragBegan() {
        isUserDragging = true
    }

    /// Called by the view when the user lifts their finger.
    func touchDragEnded() {
        isUserDragging = false
    }
  
    /// Removes the top card from the stack and starts its fly-away animation.
    ///
    /// - Parameters:
    ///   - direction: Which side the card flies off toward. `.idle` is a no-op.
    ///   - notifyCaller: When true, fires `onSwipeCommitted`. Set to false for
    ///     programmatic swipes initiated by the parent (which already knows
    ///     about the swipe and doesn't need a callback).
    func commitSwipe(direction: CardSwipeDirection, notifyCaller: Bool = true) {
        guard direction != .idle, !items.isEmpty else { return }

        let popped = items.removeFirst()
        lastDirection = direction

        poppedCard = PoppedCard(
            item: popped,
            initialOffset: dragOffset,
            direction: direction
        )

        // Mute implicit animations on the bookkeeping state changes, so the
        // stack doesn't try to interpolate card positions during the handoff.
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            topCard = items.first
            dragOffset = .zero
            hasCrossedThreshold = false
        }

        if notifyCaller {
            onSwipeCommitted?(popped, direction)
        }
    }
    /// Called by the view once the popped card finishes its fly-away animation.
    /// Clears the popped slot and fires `onStackEmptied` if the stack is now empty.
    func completePopAnimation() {
        poppedCard = nil
        if items.isEmpty {
            onStackEmptied?()
        }
    }
 
 
    /// Replaces all items atomically. Resets drag state so the stack is in a
    /// clean state regardless of what the user was doing when this was called.
    func reset(with newItems: [Item]) {
        items = newItems
        topCard = newItems.first
        dragOffset = .zero
        lastDirection = .idle
        hasCrossedThreshold = false
        poppedCard = nil
    }
 
 
    /// Cancels out the initial jump caused by `DragGesture(minimumDistance:)`.
    ///
    /// `DragGesture(minimumDistance: 20)` doesn't fire `onChanged` until the
    /// finger has moved 20 points — but when it does, `value.translation.width`
    /// is already 20. Without correction the card would jump 20 points the
    /// moment the gesture activates. This subtracts the minimum back out so
    /// the card moves smoothly from where the finger actually is.
    private func dragCorrection(for translation: CGFloat) -> CGFloat {
        let min = configuration.minimumDragDistance
        if translation >= min { return -min }
        if translation <= -min { return min }
        return -translation
    }
}
