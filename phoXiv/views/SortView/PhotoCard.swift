//
//  MattedPhotoCard.swift
//  phoXiv
//
//  The white-matted photo card with a KEEP/ARCHIVE stamp overlay that fades
//  in as the card is dragged. Pure presentation — takes what it needs to
//  render, has no state of its own.
//

import SwiftUI
import Photos

struct PhotoCard: View {
    static var cache: [String: UIImage] = [:]

    let item: ImageItem
    let progress: CGFloat
    let direction: CardSwipeDirection

    @State private var uiImage: UIImage?

    var body: some View {
        ZStack {
            Group {
                if let uiImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Color.gray
                }
            }
            .frame(width: 280, height: 420)
            .clipped()
            .padding(20)
            .background(Color.white)
            .shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: 10)

            stampOverlay
        }
        .frame(width: 320, height: 460)
        .onAppear {
            if let cached = PhotoCard.cache[item.id] {
                uiImage = cached
                return
            }

            let options = PHImageRequestOptions()
            options.isNetworkAccessAllowed = true
            options.deliveryMode = .opportunistic

            PHImageManager.default().requestImage(
                for: item.asset,
                targetSize: CGSize(width: 560, height: 840),
                contentMode: .aspectFill,
                options: options
            ) { image, _ in
                guard let image else { return }
                PhotoCard.cache[item.id] = image
                self.uiImage = image
            }
        }
    }

    @ViewBuilder
    private var stampOverlay: some View {
        if progress > 0 && direction != .idle {
            let isKeep = direction == .right
            Text(isKeep ? "KEEP" : "ARCHIVE")
                .font(.system(size: 42, weight: .heavy, design: .rounded))
                .foregroundStyle(isKeep ? Color.green : Color.red)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isKeep ? Color.green : Color.red, lineWidth: 4)
                )
                .rotationEffect(.degrees(isKeep ? -15 : 15))
                .opacity(Double(progress))
                .frame(maxWidth: .infinity, maxHeight: .infinity,
                       alignment: isKeep ? .topLeading : .topTrailing)
                .padding(40)
        }
    }
}
