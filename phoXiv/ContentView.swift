//
//  ContentView.swift
//  PhotoRecreate
//
//  Created by Kenneth Muyoyo on 15/04/26.
//

import SwiftUI
import PhotosUI

struct ContentView: View {
    @State private var selectedTab = 1

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Sort", systemImage: "move.3d", value: 0) {
                SortView()
            }
            Tab("Library", systemImage: "photo.fill", value: 1) {
                Library()
            }
            Tab("Archive", systemImage: "archivebox.fill", value: 2) {
                Archive()
            }
        }
    }
}

#Preview {
    ContentView()
}
