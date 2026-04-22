import SwiftUI
import Photos
import Combine

final class LibraryViewModel: ObservableObject {
    @Published var images: [ImageItem] = []
    @Published var authorizationStatus: PHAuthorizationStatus = .notDetermined
    
    private let imageManager = PHImageManager.default()
    
    init() {
        checkPermissions()
    }
    
    func checkPermissions() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        authorizationStatus = status
        
        if status == .authorized || status == .limited {
            fetchAssets()
        } else if status == .notDetermined {
            requestPermission()
        }
    }
    
    func requestPermission() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
            DispatchQueue.main.async {
                self?.authorizationStatus = status
                if status == .authorized || status == .limited {
                    self?.fetchAssets()
                }
            }
        }
    }
    
    // It fetches all assets and only adds the new ones.
    private func fetchAssets() {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let result = PHAsset.fetchAssets(with: .image, options: options)
        
        // Track existing asset identifiers
        var existingIds = Set(self.images.map { $0.id })
        
        var fetchedItems: [ImageItem] = self.images // start from current items
        
        result.enumerateObjects { asset, _, _ in
            let id = asset.localIdentifier
            
            // Only append if not already present
            if !existingIds.contains(id) {
                let item = ImageItem(id: asset.localIdentifier, asset: asset, archived: false)
                fetchedItems.append(item)
                existingIds.insert(id)
            }
        }
        
        DispatchQueue.main.async {
            self.images = fetchedItems
        }
    }
}
