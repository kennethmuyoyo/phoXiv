//
//  AllDoneView.swift
//  phoXiv
//
//  Celebratory empty state shown after every card has been sorted. Points
//  users to where their decisions landed and offers a "Start over" button.
//  Takes a callback rather than a view model — stays decoupled.
//

import SwiftUI

struct AllDoneView: View {
    let onStartOver: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(.tint)
                .shadow(color: .black.opacity(0.15), radius: 10)

            VStack(spacing: 8) {
                Text("All done!")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.primary)

                Text("Your minimal gallery is in the Library tab.\nArchived photos are in the Archive tab.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Button(action: onStartOver) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Start over")
                }
                .font(.subheadline.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(Color.accentColor, in: Capsule())
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }
}
