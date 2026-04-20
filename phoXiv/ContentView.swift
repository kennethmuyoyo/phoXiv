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
            Tab("Library", systemImage: "photo.fill") {
                Library()
            }
            Tab("Collections", systemImage: "heart.fill") {
                Collections()
            }
            Tab(role: .search){
                SearchView()
            }
        }
    }
}

#Preview {
    ContentView()
}
