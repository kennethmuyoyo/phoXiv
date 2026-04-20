//
//  Collections.swift
//  PhotoRecreate
//
//  Created by Kenneth Muyoyo on 15/04/26.
//

import SwiftUI

struct Collections: View {
    @State private var memoriesExpanded = true
    @State private var pinnedExpanded = true
    @State private var allbumExpanded = true
    @State private var peopleExpanded = true
    var body: some View {
        NavigationStack {
            
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("Memories")
                            .font(.title2.bold())
                        if memoriesExpanded {
                            Button {} label: {
                                Image(systemName: "chevron.right")
                                    .font(Font.system(size: 14, weight: .bold))
                                    .foregroundStyle(Color(.black.opacity(0.5)))
                            }
                        }
                        Spacer()
                        Button {
                            withAnimation(.default){
                                memoriesExpanded.toggle()}
                        } label: {
                            Image(systemName: memoriesExpanded ? "chevron.down" : "chevron.right")
                                .frame(width: 30, height: 30)
                                .font(Font.system(size: 14, weight: .bold))
                            
                        }
                        .glassEffect(.regular.tint(.gray.opacity(0.2)), in: .circle
                        )
                        
                    }
                    .padding(20)
                    
                    if memoriesExpanded {
                        ScrollView(.horizontal) {
                            LazyHStack(spacing: 12) {
                                CollectionItem(width: 200, height: 200, fontSize: 18, image: Image(.photo15))
                                CollectionItem(width: 200, height: 200, fontSize: 18, image: Image(.photo17))
                            }
                            .scrollTargetLayout()
                            .padding(.horizontal, 20)
                        }
                        .scrollTargetBehavior(.viewAligned)
                        .scrollIndicators(.hidden)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("Pinned")
                            .font(.title2.bold())
                        if pinnedExpanded {
                            Button {} label: {
                                Image(systemName: "chevron.right")
                                    .font(Font.system(size: 14, weight: .bold))
                                    .foregroundStyle(Color(.black.opacity(0.5)))
                            }
                        }
                        Spacer()
                        Button {} label: {
                            Text("Edit")
                                .frame(width: 50, height: 30)
                                .font(Font.system(size: 14, weight: .bold))
                        }
                        .glassEffect(.regular.tint(.gray.opacity(0.2)), in: .capsule)
                        
                        Button {
                            withAnimation(.default){
                                pinnedExpanded.toggle()}
                        } label: {
                            Image(systemName: pinnedExpanded ? "chevron.down" : "chevron.right")
                                .frame(width: 30, height: 30)
                                .font(Font.system(size: 14, weight: .bold))
                            
                        }
                        .glassEffect(.regular.tint(.gray.opacity(0.2)), in: .circle
                        )
                        
                    }
                    .padding(20)
                    
                    if pinnedExpanded {
                        ScrollView(.horizontal) {
                            LazyHStack(spacing: 12) {
                                CollectionItem(width: 110, height: 110, image: Image(.photo10))
                                CollectionItem(width: 110, height: 110, image:Image(.photo11))
                                CollectionItem(width: 110, height: 110, image:Image(.photo12))
                                CollectionItem(width: 110, height: 110, image:Image(.photo13))
                                CollectionItem(width: 110, height: 110, image:Image(.photo15))
                                CollectionItem(width: 110, height: 110, image:Image(.photo16))
                            }
                            .scrollTargetLayout()
                            .padding(.horizontal, 20)
                        }
                        .scrollTargetBehavior(.viewAligned)
                        .scrollIndicators(.hidden)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("Albums")
                            .font(.title2.bold())
                        if allbumExpanded {
                            Button {} label: {
                                Image(systemName: "chevron.right")
                                    .font(Font.system(size: 14, weight: .bold))
                                    .foregroundStyle(Color(.black.opacity(0.5)))
                            }
                        }
                        Spacer()
                        Button {
                            withAnimation(.default){
                                allbumExpanded.toggle()}
                        } label: {
                            Image(systemName: allbumExpanded ? "chevron.down" : "chevron.right")
                                .frame(width: 30, height: 30)
                                .font(Font.system(size: 14, weight: .bold))
                            
                        }
                        .glassEffect(.regular.tint(.gray.opacity(0.2)), in: .circle
                        )
                        
                    }
                    .padding(20)
                    
                    if allbumExpanded {
                        ScrollView(.horizontal) {
                            LazyHStack(spacing: 12) {
                                CollectionItem(width: 110, height: 110, image:Image(.photo13))
                                CollectionItem(width: 110, height: 110, image:Image(.photo15))
                                CollectionItem(width: 110, height: 110, image:Image(.photo16))
                                CollectionItem(width: 110, height: 110, image:Image(.photo17))
                                CollectionItem(width: 110, height: 110, image:Image(.photo18))
                                CollectionItem(width: 110, height: 110, image:Image(.photo19))
                            }
                            .scrollTargetLayout()
                            .padding(.horizontal, 20)
                        }
                        .scrollTargetBehavior(.viewAligned)
                        .scrollIndicators(.hidden)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("People & Pets")
                            .font(.title2.bold())
                        if peopleExpanded {
                            Button {} label: {
                                Image(systemName: "chevron.right")
                                    .font(Font.system(size: 14, weight: .bold))
                                    .foregroundStyle(Color(.black.opacity(0.5)))
                            }
                        }
                        Spacer()
                        Button {
                            withAnimation(.default){
                                peopleExpanded.toggle()}
                        } label: {
                            Image(systemName: peopleExpanded ? "chevron.down" : "chevron.right")
                                .frame(width: 30, height: 30)
                                .font(Font.system(size: 14, weight: .bold))
                            
                        }
                        .glassEffect(.regular.tint(.gray.opacity(0.2)), in: .circle
                        )
                        
                    }
                    .padding(20)
                    
                    if peopleExpanded {
                        ScrollView(.horizontal) {
                            LazyHStack(spacing: 12) {
                                CollectionItem(width: 110, height: 110, image:Image(.photo17))
                                CollectionItem(width: 110, height: 110, image:Image(.photo18))
                                CollectionItem(width: 110, height: 110, image:Image(.photo19))
                                CollectionItem(width: 110, height: 110)
                                CollectionItem(width: 110, height: 110)
                                CollectionItem(width: 110, height: 110)
                            }
                            .scrollTargetLayout()
                            .padding(.horizontal, 20)
                        }
                        .scrollTargetBehavior(.viewAligned)
                        .scrollIndicators(.hidden)
                        .transition(.move(edge: .top).combined(with: .opacity))
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
            .navigationTitle("Collections")
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
    Collections()
    //    ContentView()
}
