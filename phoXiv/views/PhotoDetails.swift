//
//  PhotoContainer.swift
//  phoXiv
//
//  Created by Nil on 20/04/26.
//
import SwiftUI
import Photos

struct PhotoDetails: View {
    let image: ImageItem
    var isArchived: Bool = false
    let location: String = "Bali, Indonesia" // you can make this dynamic
    @EnvironmentObject var lvm: LibraryViewModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = PhotoDetailsViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // Image full width
            if let image = vm.image {
                image
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .background(Color.black)
            }
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(location)
                    .foregroundColor(.primary)
                    .font(.headline)
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isArchived ? "Unarchive" : "Archive") {
                    vm.moveToArchive(image: image, vm: lvm, dismiss: dismiss)
                }
            }

            // Bottom toolbar
            ToolbarItemGroup(placement: .bottomBar) {
                Button(action: {
                    // share action
                }) {
                    Image(systemName: "square.and.arrow.up")
                }

                Spacer()

                Button(action: {
                    // info action
                }) {
                    Image(systemName: "info.circle")
                }
            }
        }
        .toolbarBackground(.visible, for: .navigationBar, .bottomBar)
        .toolbarColorScheme(.none, for: .navigationBar, .bottomBar)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            vm.loadFullSizeImage(from: image.asset)
        }
    }
}

#Preview {
    NavigationStack {
        // TODO: Provide a real PHAsset from the photo library in a live preview context.
        // For now, use a placeholder UI by initializing with a temporary empty asset surrogate if available.
        Text("PhotoDetails Preview requires a PHAsset")
            .navigationTitle("Preview")
    }
}
