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
    @State private var screenshotsExpanded = true
    @State private var allArchivedPhotos: [ImageItem] = []
    @State private var archivedScreenshots: [ImageItem] = []
    let columns: [GridItem] = [
        GridItem(.adaptive(minimum: 80), spacing: 1)
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if (!archivedScreenshots.isEmpty) {
                        
                        HStack {
                            Text("Screenshots")
                                .font(.title2.bold())
                            if screenshotsExpanded {
                                Button {} label: {
                                    Image(systemName: "chevron.right")
                                        .font(Font.system(size: 14, weight: .bold))
                                        .foregroundStyle(Color(.black.opacity(0.5)))
                                }
                            }
                            Spacer()
                            Button {
                                withAnimation(.default){
                                    screenshotsExpanded.toggle()
                                }
                            } label: {
                                Image(systemName: screenshotsExpanded ? "chevron.down" : "chevron.right")
                                    .frame(width: 30, height: 30)
                                    .font(Font.system(size: 14, weight: .bold))
                                
                            }
                            .glassEffect(.regular.tint(.gray.opacity(0.2)), in: .circle
                            )
                            
                        }
                        .padding(20)
                        
                        if screenshotsExpanded {
                            ScrollView(.horizontal) {
                                LazyHStack(spacing: 12) {
                                    ForEach(archivedScreenshots) { screenshot in
                                        CollectionItem(width: 200, height: 200, fontSize: 18, asset: screenshot.asset)
                                    }
                                }
                                .scrollTargetLayout()
                                .padding(.horizontal, 20)
                            }
                            .scrollTargetBehavior(.viewAligned)
                            .scrollIndicators(.hidden)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                if !allArchivedPhotos.isEmpty {
                    LazyVGrid(columns: columns, spacing: 1) {
                        ForEach(allArchivedPhotos) { image in
                            NavigationLink {
                                PhotoDetails(image: image)
                            } label: {
                                PhotoContainer(asset: image.asset)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                
                //            DisclosureGroup("Pinned", isExpanded: $collectionsExpanded) {
                //                ScrollView(.horizontal) {
                //                        HStack (spacing: 16){
                //                            CollectionItem()
                //                            CollectionItem()
                //                            CollectionItem()
                //                            CollectionItem()
                //                            CollectionItem()
                //                            CollectionItem()
                //                        }
                //                        .scrollTargetLayout()
                //
                //                }
                //                .scrollTargetBehavior(.viewAligned)
                //                .scrollIndicators(.hidden)
                //            }
                //            .font(.title.bold())
                //            .padding(10)
                //            .foregroundColor(.primary)
                //
                //            DisclosureGroup("Albums", isExpanded: $collectionsExpanded) {
                //                CollectionItem()
                //            }
                //            .font(.title.bold())
                //            .padding(10)
                //            .foregroundColor(.primary)
                //
            }
            .navigationTitle("Archive")
            .toolbar {
                ToolbarSpacer()
                ToolbarItem(placement: .topBarTrailing) {
                    Text("Select")
                        .padding()
                }
            }
            .toolbarTitleDisplayMode(.inlineLarge)
            .onAppear(
                perform: {
                    archivedScreenshots = vm.filterImages(archived: true, mediaSubtype: PHAssetMediaSubtype.photoScreenshot)
                    allArchivedPhotos = vm.filterImages(archived: true, mediaSubtype: nil)
                    if $archivedScreenshots.count > 0 { screenshotsExpanded = true } else { screenshotsExpanded = false }
                }
            )
            if (allArchivedPhotos.isEmpty) {
                VStack {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "archivebox")
                            .font(.system(size: 48, weight: .regular))
                            .foregroundStyle(.secondary)
                        Text("No archived photos yet")
                            .font(.title3.weight(.semibold))
                        Text("Archive some photos from the Sort tab to see them here.")
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                    }
                    .padding(40)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}


#Preview {
    Archive()
    //    ContentView()
}
