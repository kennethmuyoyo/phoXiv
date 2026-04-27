import SwiftUI
import Photos
import Combine
import SwiftData

final class LibraryViewModel: ObservableObject {
    @Published var images: [ImageItem] = []
    @Published var authorizationStatus: PHAuthorizationStatus = .notDetermined
    var service = ImageService()

    var unsortedImages: [ImageItem] {
        images.filter { !$0.sorted }
    }

    // The SwiftData context used to read and write ImageItemPersistence records.
    // Injected at init so views never need to interact with persistence directly.
    private let context: ModelContext
    private let imageManager = PHImageManager.default()

    init(context: ModelContext) {
        self.context = context
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

    // Archives a set of images by id and persists the change.
    func archiveItems(ids: Set<String>) {
        for i in images.indices where ids.contains(images[i].id) {
            images[i].archived = true
            images[i].sorted = true
            upsertRecord(id: images[i].id, archived: true, sorted: true)
        }
    }

    // Unarchives a set of images by id and persists the change.
    func unarchiveItems(ids: Set<String>) {
        for i in images.indices where ids.contains(images[i].id) {
            images[i].archived = false
            upsertRecord(id: images[i].id, archived: false, sorted: images[i].sorted)
        }
    }
    
    func deleteItems(ids: Set<String>, completion: @escaping (Bool) -> Void) {
        let assets = images
            .filter { ids.contains($0.id) }
            .compactMap { $0.asset }

        service.delete(assets: assets, vm: self, completion: completion)
    }

    // Called by ImageService after it mutates an image in-place (move/sort).
    // Reads the current in-memory state and writes it to SwiftData.
    func saveRecord(for id: String) {
        guard let item = images.first(where: { $0.id == id }) else { return }
        upsertRecord(id: id, archived: item.archived, sorted: item.sorted)
    }

    // Called by ImageService after a photo is deleted from the Photos library.
    // Removes the associated persistence record so it does not accumulate as an orphan.
    func deleteRecord(for id: String) {
        let descriptor = FetchDescriptor<ImageItemPersistence>(
            predicate: #Predicate { $0.id == id }
        )
        if let record = try? context.fetch(descriptor).first {
            context.delete(record)
            try? context.save()
        }
    }

    func filterImages(archived: Bool?, mediaSubtype: PHAssetMediaSubtype?) -> [ImageItem] {
        images.filter { item in
            if let archived, item.archived != archived { return false }
            if let mediaSubtype, !item.asset.mediaSubtypes.contains(mediaSubtype) { return false }
            return true
        }
    }

    // Fetches all PHAssets from the Photos library and merges them with
    // persisted ImageItemPersistence records.
    //
    // Flow:
    //   1. Load all ImageItemPersistence records into a dictionary keyed by id
    //      for O(1) lookup during the merge.
    //   2. Enumerate PHAssets. For each new asset (not already in memory):
    //      - If a persistence record exists → use its archived/sorted values.
    //      - If not (first time seeing this photo) → default to false/false and
    //        the record will be created the first time the user acts on it.
    //   3. Delete any persistence records whose id no longer appears in the
    //      Photos library (photos deleted outside the app).
    private func fetchAssets() {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let result = PHAsset.fetchAssets(with: .image, options: options)

        // Step 1 — load all persisted records into a dictionary for fast lookup.
        let allRecords = (try? context.fetch(FetchDescriptor<ImageItemPersistence>())) ?? []
        let recordMap = Dictionary(uniqueKeysWithValues: allRecords.map { ($0.id, $0) })

        var existingIds = Set(self.images.map { $0.id })
        var fetchedItems: [ImageItem] = self.images
        var liveIds: Set<String> = existingIds

        // Step 2 — merge PHAssets with persistence records.
        result.enumerateObjects { asset, _, _ in
            let id = asset.localIdentifier
            liveIds.insert(id)
            guard !existingIds.contains(id) else { return }

            let record = recordMap[id]
            let item = ImageItem(
                id: id,
                asset: asset,
                archived: record?.archived ?? false,
                sorted: record?.sorted ?? false
            )
            fetchedItems.append(item)
            existingIds.insert(id)
        }

        // Step 3 — remove orphaned records for photos deleted from the library.
        for record in allRecords where !liveIds.contains(record.id) {
            context.delete(record)
        }
        try? context.save()

        DispatchQueue.main.async {
            self.images = fetchedItems
        }
    }

    // Upserts an ImageItemPersistence record: updates it if it exists,
    // inserts a new one if it does not.
    private func upsertRecord(id: String, archived: Bool, sorted: Bool) {
        let descriptor = FetchDescriptor<ImageItemPersistence>(
            predicate: #Predicate { $0.id == id }
        )
        if let record = try? context.fetch(descriptor).first {
            record.archived = archived
            record.sorted = sorted
        } else {
            context.insert(ImageItemPersistence(id: id, archived: archived, sorted: sorted))
        }
        try? context.save()
    }
}
