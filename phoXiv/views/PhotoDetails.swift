//
//  PhotoContainer.swift
//  phoXiv
//
//  Created by Nil on 20/04/26.
//
import SwiftUI
import Photos
import PhotosUI
import MapKit

struct PhotoDetails: View {
    let image: ImageItem
    let location: String = "Bali, Indonesia" // you can make this dynamic
    @EnvironmentObject var lvm: LibraryViewModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = PhotoDetailsViewModel()
    
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
            ToolbarItem(placement: .topBarTrailing) {
                Button(image.archived ? "Unarchive" : "Archive") {
                    vm.moveFromToArchive(image: image, vm: lvm, dismiss: dismiss)
                }
            }
            ToolbarSpacer(placement: .topBarTrailing)
            ToolbarItem(placement: .topBarTrailing) {
                if image.archived {
                    Button(role: .destructive) {
                        ImageService().delete(asset: image.asset, vm: lvm) { success in
                            if success { dismiss() }
                        }
                    } label: {
                        Image(systemName: "trash")
                            .foregroundStyle(.red)
                    }
                }
            }

            // Bottom toolbar
            ToolbarItemGroup(placement: .bottomBar) {
                if let uiImage = shareImage {
                    ShareLink(item: Image(uiImage: uiImage), preview: SharePreview("Photo", image: Image(uiImage: uiImage))) {
                        Image(systemName: "square.and.arrow.up")
                    }
                } else {
                    Button {
                        let targetSize = CGSize(width: 2048, height: 2048)
                        let options = PHImageRequestOptions()
                        options.isSynchronous = false
                        options.isNetworkAccessAllowed = true
                        options.deliveryMode = .highQualityFormat
                        PHImageManager.default().requestImage(
                            for: image.asset,
                            targetSize: targetSize,
                            contentMode: .aspectFill,
                            options: options
                        ) { ui, _ in
                            self.shareImage = ui
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }

                Spacer()

                Button(action: {
                    showInfo = true
                }) {
                    Image(systemName: "info.circle")
                }
            }
        }
        .toolbarBackground(.visible, for: .navigationBar, .bottomBar)
        .toolbarColorScheme(.none, for: .navigationBar, .bottomBar)
        .toolbar(.hidden, for: .tabBar)
        .sheet(isPresented: $showInfo) {
            InfoView(image: image)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            vm.loadFullSizeImage(from: image.asset)
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
                Text("Dimensions")
                Spacer()
                Text("\(image.asset.pixelWidth) × \(image.asset.pixelHeight)")
                    .foregroundStyle(.secondary)
            }
            // Map section if location is available
            if let coordinate = image.asset.location?.coordinate {
                Section("Location") {
                    Map(initialPosition: .region(MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02))))
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .navigationTitle("Info")
        .scrollDisabled(true)
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

