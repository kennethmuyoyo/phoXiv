//
//  ContentView.swift
//  PhotoRecreate
//
//  Created by Kenneth Muyoyo on 15/04/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        
        TabView {
            Tab("Sort", systemImage: "move.3d") {
                ArchiveView()
            }
            Tab("Library", systemImage: "photo.fill") {
                Library()
            }
            Tab("Archive", systemImage: "archivebox.fill") {
                Collections()
            }
            
        }
    }
}

#Preview {
    ContentView()
}
