import SwiftUI
import Combine
import Photos

@MainActor
struct ImageService {
    @EnvironmentObject var vm: LibraryViewModel

    func getImage(from asset: PHAsset, size: CGSize, completion: @escaping (Image?) -> Void) {
        let manager = PHImageManager.default()
        
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        
        manager.requestImage(
            for: asset,
            targetSize: size,
            contentMode: .aspectFill,
            options: options
        ) { image, _ in
            // Convert UIImage to Image
            completion(Image(uiImage: image ?? UIImage()))
        }
    }
    
    func moveImage(asset: PHAsset) {
            if let idx = vm.images.firstIndex(where: {
                $0.id == asset.localIdentifier
            }) {
                vm.images[idx].archived.toggle()
            }
    }

    func sortImage(asset: PHAsset, direction: CardSwipeDirection) {
        if let idx = vm.images.firstIndex(where: {
            $0.id == asset.localIdentifier
        }) {
            vm.images[idx].isSorted = true
            vm.images[idx].archived = (direction == .left)
        }
    }
}
