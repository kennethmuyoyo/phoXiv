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
        VStack {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 48, weight: .regular))
                    .foregroundStyle(.secondary)
                
                Text("All photos have been sorted.")
                    .font(.title3.weight(.semibold))
                
                Text("Check them out in the Library & Archive pages.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
