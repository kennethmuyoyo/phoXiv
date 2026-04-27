//
//  PhotoContainer.swift
//  phoXiv
//
//  Created by Nil on 20/04/26.
//
import SwiftUI
import Photos
import PhotosUI

struct PhotoDetails: View {
    let image: ImageItem
    let location: String = "Bali, Indonesia" // you can make this dynamic
    @EnvironmentObject var lvm: LibraryViewModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = PhotoDetailsViewModel()
    
    @State private var showShare = false
    @State private var showInfo = false
    @State private var shareImage: UIImage?

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
                Button(image.archived ? "Unarchive" : "Archive") {
                    vm.moveFromToArchive(image: image, vm: lvm, dismiss: dismiss)
                }
            }

            // Bottom toolbar
            ToolbarItemGroup(placement: .bottomBar) {
                Button(action: {
                    showShare = true
                }) {
                    Image(systemName: "square.and.arrow.up")
                }

                Spacer()

                Button(action: {
                    showInfo = true
                }) {
                    Image(systemName: "info.circle")
                }

                Spacer()

                Button(role: .destructive) {
                    ImageService().delete(asset: image.asset, vm: lvm) { success in
                        if success { dismiss() }
                    }
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
        .toolbarBackground(.visible, for: .navigationBar, .bottomBar)
        .toolbarColorScheme(.none, for: .navigationBar, .bottomBar)
        .toolbar(.hidden, for: .tabBar)
        .sheet(isPresented: $showShare) {
            if let uiImage = shareImage {
                ShareSheet(activityItems: [uiImage])
            } else {
                Text("Nothing to share")
            }
        }
        .sheet(isPresented: $showInfo) {
            InfoView(image: image)
                .presentationDetents([.medium, .large])
        }
        .onAppear {
            vm.loadFullSizeImage(from: image.asset)
            let targetSize = CGSize(width: 2048, height: 2048)
            ImageService().getImage(from: image.asset, size: targetSize) { _ in
                // Always fetch a UIImage for sharing via PHImageManager
                let options = PHImageRequestOptions()
                options.isSynchronous = false
                options.isNetworkAccessAllowed = true
                options.deliveryMode = .highQualityFormat
                PHImageManager.default().requestImage(for: image.asset, targetSize: targetSize, contentMode: .aspectFill, options: options) { ui, _ in
                    self.shareImage = ui
                }
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct InfoView: View {
    let image: ImageItem

    var body: some View {
        List {
            if let date = image.asset.creationDate {
                HStack {
                    Text("Date")
                    Spacer()
                    Text(DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .short))
                        .foregroundStyle(.secondary)
                }
            }
            HStack {
                Text("Identifier")
                Spacer()
                Text(image.id)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.trailing)
            }
            HStack {
                Text("Dimensions")
                Spacer()
                Text("\(image.asset.pixelWidth) × \(image.asset.pixelHeight)")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Info")
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
