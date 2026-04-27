//
//  ContentView.swift
//  PhotoRecreate
//
//  Created by Kenneth Muyoyo on 15/04/26.
//

import SwiftUI
import PhotosUI

enum TabSelection {
    case sort
    case library
    case archive
}

struct ContentView: View {

    @State private var selectedTab: TabSelection = .library // Default to Library

    var body: some View {
        TabView(selection: $selectedTab) {
            SortView()
                .tabItem { Label("Sort", systemImage: "arrow.left.arrow.right.circle") }
                .tag(TabSelection.sort)

            Library()
                .tabItem { Label("Library", systemImage: "photo.fill") }
                .tag(TabSelection.library)

            Archive()
                .tabItem { Label("Archive", systemImage: "archivebox.fill") }
                .tag(TabSelection.archive)
        }
    }
}

#Preview {
    ContentView()
}
