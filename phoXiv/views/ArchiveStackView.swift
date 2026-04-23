//
//  ArchiveView.swift
//  phoXiv
//
//  Created by Kenneth Muyoyo on 20/04/26.
//

import SwiftUI

// Renders the archive stack of cards.
//
// All business state (which cards, drag offset, popped card) lives in the
// view model. This view's only responsibilities are:
//   1. Render the visible cards with the appropriate stack-position transform.
//   2. Forward drag gestures to the view model.
//   3. Render the popped card overlay during its fly-away animation.
//
// Generic over the item type and a content closure, so it can be used for
// any card content — image cards, profile cards, etc. The content closure
// receives the current drag progress (0…1, top card only) and direction so
// it can render its own per-card overlays like LIKE/NOPE badges.
struct ArchiveStackView<Item: Identifiable & Hashable, CardContent: View>: View {
    var viewModel: CardStackViewModel<Item>
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
            stackLayer
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay { poppedLayer }
        .gesture(dragGesture)
    }
    
    // MARK: - Stack Layer
    
    private var stackLayer: some View {
        ForEach(
            Array(viewModel.items.prefix(viewModel.configuration.visibleCount).enumerated()),
            id: \.element.id
        ) { index, item in
            content(item, progressForCard(at: index), viewModel.lastDirection)
                .modifier(
                    ArchiveSwipeEffect(
                        index: index,
                        offset: viewModel.dragOffset,
                        triggerThreshold: viewModel.configuration.dragTriggerThreshold
                    )
                )
        }
    }
    
    // Progress is only meaningful for the top card — cards beneath aren't
    // being directly dragged, so they get 0.
    private func progressForCard(at index: Int) -> CGFloat {
        guard index == 0 else { return 0 }
        return min(abs(viewModel.dragOffset.x) / viewModel.configuration.dragTriggerThreshold, 1)
    }
    
    // MARK: - Popped Card Layer
    
    @ViewBuilder
    private var poppedLayer: some View {
        if let popped = viewModel.poppedCard {
            PoppedCardView(
                popped: popped,
                configuration: viewModel.configuration,
                content: content,
                onCompleted: { viewModel.completePopAnimation() }
            )
            // .id ensures SwiftUI treats each new popped card as a fresh view,
            // so its @State (the animated offset) resets for each card.
            .id(popped.id)
        }
    }
    
    // MARK: - Drag Gesture
    
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: viewModel.configuration.minimumDragDistance)
            .onChanged { value in
                viewModel.touchDragBegan()
                viewModel.updateDrag(translation: value.translation)
            }
            .onEnded { value in
                viewModel.endDrag(translation: value.translation)
                viewModel.touchDragEnded()
            }
    }
    
}

// MARK: - Popped Card View

// Owns the fly-away animation for a single popped card.
//
// Lives as a separate view because the animated offset is presentation state,
// not business state — it belongs in @State here, not in the view model.
// When the animation completes, calls back to the view model to clear itself.
private struct PoppedCardView<Item: Identifiable & Hashable, CardContent: View>: View {
    let popped: PoppedCard<Item>
    let configuration: CardConfig
    let content: (Item, CGFloat, CardSwipeDirection) -> CardContent
    let onCompleted: () -> Void
    
    @State private var offset: CGPoint
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
        self._offset = State(initialValue: popped.initialOffset)
    }
    
    var body: some View {
        content(popped.item, progress, popped.direction)
            .modifier(
                ArchiveSwipeEffect(
                    index: 0,
                    offset: offset,
                    triggerThreshold: configuration.dragTriggerThreshold
                )
            )
            .onAppear {
                guard !hasAnimated else { return }
                hasAnimated = true
                animateAway()
            }
    }

    private func animateAway() {
        let multiplier: CGFloat = popped.direction == .left ? -1 : 1
        // 1000pt is plenty to exit any phone or iPad screen from any start position.
        let target = offset.x + (1000 * multiplier)

        withAnimation(.easeOut(duration: 0.55)) {
            offset.x = target
        } completion: {
            onCompleted()
        }
    }
    
    private var progress: CGFloat {
        min(abs(offset.x) / configuration.dragTriggerThreshold, 1)
    }
    
}


