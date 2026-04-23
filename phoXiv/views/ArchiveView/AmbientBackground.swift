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
import Photos

struct AmbientBackground: View {
    /// The top card's item, if any. When nil, only the base system color
    /// shows — clean fallback for the all-done state.
    let topItem: ImageItem?

    var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .ignoresSafeArea()

            if let item = topItem {
                BlurredAssetImage(asset: item.asset, itemId: item.id)
                topFadeOverlay
            }
        }
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

private struct BlurredAssetImage: View {
    let asset: PHAsset
    let itemId: String

    @State private var uiImage: UIImage?

    var body: some View {
        GeometryReader { geo in
            Group {
                if let uiImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Color.clear
                }
            }
            .frame(width: geo.size.width * 1.2, height: geo.size.height * 1.2)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
            .blur(radius: 70)
            .saturation(1.4)
            .overlay(Color.black.opacity(0.25))
        }
        .ignoresSafeArea()
        .id(itemId)
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.8), value: itemId)
        .onAppear {
            let options = PHImageRequestOptions()
            options.isNetworkAccessAllowed = true
            options.deliveryMode = .opportunistic

            PHImageManager.default().requestImage(
                for: asset,
                targetSize: CGSize(width: 200, height: 200),
                contentMode: .aspectFill,
                options: options
            ) { image, _ in
                self.uiImage = image
            }
        }
    }
}
