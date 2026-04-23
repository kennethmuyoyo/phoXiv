//
//  AmbientBackground.swift
//  phoXiv
//
//  Layered background behind the archive stack:
//    1. System background color (always)
//    2. Heavily blurred top-card image (when a card is present)
//    3. Top gradient fade to keep the nav bar title legible
//
//  Takes the top card's image directly (or nil). Doesn't observe a view
//  model — the parent decides what to pass.
//

import SwiftUI

struct AmbientBackground: View {
    /// The top card's item, if any. When nil, only the base system color
    /// shows — clean fallback for the all-done state.
    let topItem: ImageItem?

    var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .ignoresSafeArea()

            if let item = topItem {
                blurredImage(for: item)
                topFadeOverlay
            }
        }
    }

    private func blurredImage(for item: ImageItem) -> some View {
        GeometryReader { geo in
            Image(item.image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: geo.size.width * 1.2, height: geo.size.height * 1.2)
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
                .blur(radius: 70)
                .saturation(1.4)
                .overlay(Color.black.opacity(0.25))
        }
        .ignoresSafeArea()
        // Keying on item.id means SwiftUI treats each card change as a new
        // view — enabling the opacity cross-fade between backgrounds.
        .id(item.id)
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.8), value: item.id)
    }

    private var topFadeOverlay: some View {
        GeometryReader { geo in
            LinearGradient(
                stops: [
                    .init(color: Color(UIColor.systemBackground), location: 0),
                    .init(color: Color(UIColor.systemBackground).opacity(0.0), location: 0.18),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: geo.size.height)
            .blur(radius: 70)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}
