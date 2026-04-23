//
//  phoXivApp.swift
//  phoXiv
//
//  Created by Kenneth Muyoyo on 20/04/26.
//

import SwiftUI

@main
struct phoXivApp: App {
    var photoLibrary = LibraryViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(photoLibrary)
        }
    }
}

#Preview {
    ContentView()
}
