//
//  phoXivApp.swift
//  phoXiv
//
//  Created by Kenneth Muyoyo on 20/04/26.
//

import SwiftUI
import SwiftData

@main
struct phoXivApp: App {
    // The SwiftData container manages the on-disk store for ImageItemPersistence.
    // It is created once at app startup and lives for the entire app lifetime.
    let container: ModelContainer

    // LibraryViewModel is initialised with the container's main context so it
    // can read and write persistence records directly, without views needing
    // to know about SwiftData at all.
    let photoLibrary: LibraryViewModel

    init() {
        do {
            container = try ModelContainer(for: ImageItemPersistence.self)
        } catch {
            fatalError("SwiftData failed to initialise: \(error)")
        }
        // mainContext is bound to the main actor — safe because LibraryViewModel
        // always mutates images on the main queue.
        photoLibrary = LibraryViewModel(context: container.mainContext)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(photoLibrary)
        }
    }
}
