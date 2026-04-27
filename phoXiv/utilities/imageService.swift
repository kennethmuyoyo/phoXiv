import SwiftUI
import Combine
import Photos

@MainActor
struct ImageService {
    
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
    
    func moveImage(asset: PHAsset, vm: LibraryViewModel) {
        if let idx = vm.images.firstIndex(where: {
            $0.id == asset.localIdentifier
        }) {
            vm.images[idx].archived.toggle()
            if !vm.images[idx].sorted {
                vm.images[idx].sorted.toggle()
            }
        }
    }

    func sortImage(asset: PHAsset, direction: CardSwipeDirection, vm: LibraryViewModel) {
        if let idx = vm.images.firstIndex(where: {
            $0.id == asset.localIdentifier
        }) {
            vm.images[idx].sorted = true
            vm.images[idx].archived = (direction == .left)
        }
    }
    
    func delete(asset: PHAsset, vm: LibraryViewModel, completion: @escaping (Bool) -> Void) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets([asset] as NSArray)
        }) { success, error in
            DispatchQueue.main.async {
                if success {
                    vm.images.removeAll { $0.id == asset.localIdentifier }
                }
                completion(success && error == nil)
            }
        }
    }
}
