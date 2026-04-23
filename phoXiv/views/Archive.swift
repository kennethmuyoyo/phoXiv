//
//  Collections.swift
//  PhotoRecreate
//
//  Created by Kenneth Muyoyo on 15/04/26.
//

import SwiftUI
import Photos

struct Archive: View {
    @EnvironmentObject var vm: LibraryViewModel

    let columns: [GridItem] = [
        GridItem(.adaptive(minimum: 80), spacing: 1)
    ]

    var body: some View {
        NavigationStack {
            Group {
                let archivedImages = vm.images.filter { $0.archived }
                if archivedImages.isEmpty {
                    ContentUnavailableView(
                        "No Archived Photos",
                        systemImage: "archivebox",
                        description: Text("Photos you archive will appear here.")
                    )
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 1) {
                            ForEach(archivedImages) { image in
                                NavigationLink {
                                    PhotoDetails(image: image, isArchived: true)
                                } label: {
                                    PhotoContainer(asset: image.asset)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Archive")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Image(systemName: "ellipsis")
                }
                ToolbarSpacer(placement: .topBarTrailing)
                ToolbarItem(placement: .topBarTrailing) {
                    Image(systemName: "person.fill")
                        .font(.body.bold())
                        .foregroundStyle(.blue)
                }
            }
            .toolbarTitleDisplayMode(.inlineLarge)
        }
    }
}


#Preview {
    Archive()
    //    ContentView()
}
