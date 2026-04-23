//
//  MattedPhotoCard.swift
//  phoXiv
//
//  The white-matted photo card with a KEEP/ARCHIVE stamp overlay that fades
//  in as the card is dragged. Pure presentation — takes what it needs to
//  render, has no state of its own.
//

import SwiftUI

struct PhotoCard: View {
    let item: ImageItem
    let progress: CGFloat
    let direction: CardSwipeDirection

    var body: some View {
        ZStack {
            Image(item.image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 280, height: 420)
                .clipped()
                .padding(20)
                .background(Color.white)
                .shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: 10)

            stampOverlay
        }
        .frame(width: 320, height: 460)
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
