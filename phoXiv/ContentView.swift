//
//  ContentView.swift
//  PhotoRecreate
//
//  Created by Kenneth Muyoyo on 15/04/26.
//

import SwiftUI
import PhotosUI

struct ContentView: View {
    var body: some View {
        return TabView {
            Tab("Library", systemImage: "photo.fill") {
                Library()
            }
            Tab("Archive", systemImage: "square.and.arrow.down.on.square") {
                Archive()
            }
            Tab("", systemImage: "photo.stack.fill", role: .search){
                SearchView()
            }
        }
    }
}

#Preview {
    ContentView()
}
