//
//  ArchiveStackView.swift
//  phoXiv
//
//  Created by Kenneth Muyoyo on 20/04/26.
//

import SwiftUI

// Renders the card stack and handles the drag gesture.
//
// Responsibilities:
//   1. Render the visible cards with stack-position transforms (via ArchiveSwipeEffect).
//   2. Forward drag gestures to the CardStackViewModel.
//   3. Render the popped card overlay during its fly-away animation.
//
// Generic over Item (the data type) and CardContent (what each card looks like).
// The content closure receives drag progress (0…1) and direction so each card
// can render its own overlays (KEEP/ARCHIVE stamps).
struct SortStackView<Item: Identifiable & Hashable, CardContent: View>: View {

    // The view model that owns all card stack state (items, drag offset, etc.).
    var viewModel: CardStackViewModel<Item>

    // Closure that builds the visual content for each card.
    // Parameters: the item, drag progress (0…1, top card only), and current direction.
    let content: (Item, _ progress: CGFloat, _ direction: CardSwipeDirection) -> CardContent

    init(
        viewModel: CardStackViewModel<Item>,
        @ViewBuilder content: @escaping (Item, _ progress: CGFloat, _ direction: CardSwipeDirection) -> CardContent
    ) {
        self.viewModel = viewModel
        self.content = content
    }

    var body: some View {
        ZStack {
            stackLayer           // the visible stack of cards (up to visibleCount)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay { poppedLayer } // the card currently flying away (if any)
        .gesture(dragGesture)    // finger drag input
    }

    // MARK: - Stack Layer

    // Renders the top N cards from the items array, each with a stack-position
    // transform applied by ArchiveSwipeEffect.
    private var stackLayer: some View {
        ForEach(
            // Take up to visibleCount items and pair each with its index.
            // id: \.element.id ensures SwiftUI tracks cards by their identity,
            // preserving @State (like loaded images) when cards shift position.
            Array(viewModel.items.prefix(viewModel.configuration.visibleCount).enumerated()),
            id: \.element.id
        ) { index, item in
            // Build the card content with progress (top card only) and direction.
            content(item, progressForCard(at: index), viewModel.lastDirection)
                .modifier(
                    // Apply the stack transform: top card follows drag + tilts,
                    // cards beneath scale and offset based on drag progress.
                    SortSwipeEffect(
                        index: index,
                        offset: viewModel.dragOffset,
                        triggerThreshold: viewModel.configuration.dragTriggerThreshold
                    )
                )
        }
    }

    // Returns the normalized drag progress (0…1) for a card at the given index.
    // Only the top card (index 0) gets a non-zero progress — cards beneath
    // aren't being directly dragged, so they always get 0.
    private func progressForCard(at index: Int) -> CGFloat {
        guard index == 0 else { return 0 }
        return min(abs(viewModel.dragOffset.x) / viewModel.configuration.dragTriggerThreshold, 1)
    }

    // MARK: - Popped Card Layer

    // Renders the card that was just swiped away, animating it off-screen.
    // Shown as an overlay so the next card is already visible and interactive
    // underneath while the popped card flies away.
    @ViewBuilder
    private var poppedLayer: some View {
        if let popped = viewModel.poppedCard {
            PoppedCardView(
                popped: popped,
                configuration: viewModel.configuration,
                content: content,
                onCompleted: { viewModel.completePopAnimation() }
            )
            // .id forces SwiftUI to treat each popped card as a new view,
            // so @State (the animated offset) resets for each card.
            .id(popped.id)
        }
    }

    // MARK: - Drag Gesture

    // The finger drag gesture. Forwards all events to the view model.
    // minimumDistance prevents accidental swipes from taps.
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: viewModel.configuration.minimumDragDistance)
            .onChanged { value in
                viewModel.touchDragBegan()                        // tell VM a finger is down
                viewModel.updateDrag(translation: value.translation) // update card position
            }
            .onEnded { value in
                viewModel.endDrag(translation: value.translation) // commit or spring back
                viewModel.touchDragEnded()                        // tell VM finger is up
            }
    }

}

// MARK: - Popped Card View

// Owns the fly-away animation for a single card that was just swiped.
//
// This is a separate view because the animated offset is presentation state
// (@State), not business state — it belongs here, not in the view model.
// When the animation finishes, it calls back to the view model to clear
// the popped slot.
private struct PoppedCardView<Item: Identifiable & Hashable, CardContent: View>: View {

    // The card data and its initial position when it was popped.
    let popped: PoppedCard<Item>

    // Card configuration (needed for the swipe effect threshold).
    let configuration: CardConfig

    // The same content closure used by the stack, so the card looks identical.
    let content: (Item, CGFloat, CardSwipeDirection) -> CardContent

    // Called when the fly-away animation completes.
    let onCompleted: () -> Void

    // The animated offset — starts at the card's position when it was swiped,
    // then animates 1000pt off-screen.
    @State private var offset: CGPoint

    // Prevents the animation from firing more than once if the view re-renders.
    @State private var hasAnimated = false

    init(
        popped: PoppedCard<Item>,
        configuration: CardConfig,
        content: @escaping (Item, CGFloat, CardSwipeDirection) -> CardContent,
        onCompleted: @escaping () -> Void
    ) {
        self.popped = popped
        self.configuration = configuration
        self.content = content
        self.onCompleted = onCompleted
        // Initialize offset to where the card was when the user committed the swipe.
        self._offset = State(initialValue: popped.initialOffset)
    }

    var body: some View {
        // Render the card content with full progress (1.0) and the swipe direction.
        content(popped.item, progress, popped.direction)
            .modifier(
                // Apply the same swipe effect as the top card (index 0)
                // so the card continues to tilt as it flies away.
                SortSwipeEffect(
                    index: 0,
                    offset: offset,
                    triggerThreshold: configuration.dragTriggerThreshold
                )
            )
            .onAppear {
                // Fire the fly-away animation exactly once.
                guard !hasAnimated else { return }
                hasAnimated = true
                animateAway()
            }
    }

    // Animates the card 1000pt off-screen in the swipe direction.
    // When the animation completes, notifies the view model to clear the slot.
    private func animateAway() {
        // -1 for left swipes, +1 for right swipes.
        let multiplier: CGFloat = popped.direction == .left ? -1 : 1
        // 1000pt is enough to exit any phone or iPad screen.
        let target = offset.x + (1000 * multiplier)

        withAnimation(.easeOut(duration: 0.55)) {
            offset.x = target   // animate the card off-screen
        } completion: {
            onCompleted()       // tell the view model the animation is done
        }
    }

    // Normalized progress for the stamp overlay. Always at or above 1.0
    // since the card was already past the threshold when it was popped.
    private var progress: CGFloat {
        min(abs(offset.x) / configuration.dragTriggerThreshold, 1)
    }

}
