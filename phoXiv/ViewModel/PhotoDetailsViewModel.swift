import SwiftUI
import Combine
import Photos

class PhotoDetailsViewModel: ObservableObject {
    @Published var image: Image?
    let service: ImageService
    
    init() {
        self.service = ImageService()
    }
    
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
    
    func moveFromToArchive(image: ImageItem, vm: LibraryViewModel, dismiss: DismissAction) {
        service.moveImage(asset: image.asset, vm: vm)
        dismiss()
    }
}
