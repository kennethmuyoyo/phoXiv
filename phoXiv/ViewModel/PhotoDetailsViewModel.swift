import SwiftUI
import Combine
import Photos

class PhotoDetailsViewModel: ObservableObject {
    @Environment(\.dismiss) var dismiss
    @Published var image: Image?
    let service = ImageService()
    
    func loadImageThumbnail(from asset: PHAsset) {
        service.getImage(from: asset, size: CGSize(width: 300, height: 300)) { [weak self] image in
            DispatchQueue.main.async {
                self?.image = image
            }
        }
    }
    
    func loadFullSizeImage(from asset: PHAsset) {
        service.getImage(from: asset, size: PHImageManagerMaximumSize) { [weak self] image in
            DispatchQueue.main.async {
                self?.image = image
            }
        }
    }
    
    func moveToArchive(image: ImageItem) {
        service.moveImage(asset: image.asset)
        dismiss()
    }
}
