import SwiftData

// Stores only the user's decisions about a photo between app launches.
//
// PHAsset itself cannot be persisted — it is a live reference managed by the
// Photos framework and must always be fetched at runtime. This model acts as
// a lightweight sidecar: it holds the two flags the user controls (archived,
// sorted) keyed by the asset's localIdentifier, which is stable across launches.
//
// On every launch, LibraryViewModel fetches PHAssets from Photos and merges
// them with these records to reconstruct the full ImageItem list.
@Model
class ImageItemPersistence {
    // PHAsset.localIdentifier — the stable key shared between Photos and SwiftData.
    @Attribute(.unique) var id: String
    var archived: Bool
    var sorted: Bool

    init(id: String, archived: Bool, sorted: Bool) {
        self.id = id
        self.archived = archived
        self.sorted = sorted
    }
}
