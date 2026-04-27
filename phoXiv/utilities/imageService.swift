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
            completion(Image(uiImage: image ?? UIImage()))
        }
    }

    // Toggles the archived state of an image and persists the new state.
    // vm.saveRecord reads the updated in-memory value and writes it to SwiftData.
    func moveImage(asset: PHAsset, vm: LibraryViewModel) {
        if let idx = vm.images.firstIndex(where: { $0.id == asset.localIdentifier }) {
            vm.images[idx].archived.toggle()
            if !vm.images[idx].sorted {
                vm.images[idx].sorted.toggle()
            }
            vm.saveRecord(for: asset.localIdentifier)
        }
    }

    // Marks an image as sorted and sets its archived state based on swipe direction.
    // Persists immediately so the decision survives the next launch.
    func sortImage(asset: PHAsset, direction: CardSwipeDirection, vm: LibraryViewModel) {
        if let idx = vm.images.firstIndex(where: { $0.id == asset.localIdentifier }) {
            vm.images[idx].sorted = true
            vm.images[idx].archived = (direction == .left)
            vm.saveRecord(for: asset.localIdentifier)
        }
    }

    // Deletes one or multiple photos and removes persistence records.
    func delete(assets: [PHAsset], vm: LibraryViewModel, completion: @escaping (Bool) -> Void) {

        let identifiers = Set(assets.map { $0.localIdentifier })

        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets(assets as NSArray)
        }) { success, error in
            DispatchQueue.main.async {
                if success && error == nil {
                    vm.images.removeAll { identifiers.contains($0.id) }
                    identifiers.forEach { vm.deleteRecord(for: $0) }
                }
                completion(success && error == nil)
            }
        }
    }
    
    func delete(asset: PHAsset, vm: LibraryViewModel, completion: @escaping (Bool) -> Void) {
        delete(assets: [asset], vm: vm, completion: completion)
    }
}
