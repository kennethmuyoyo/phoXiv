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
    @State private var isSelectMode = false
    @State private var selectedIDs: Set<String> = []
    @State private var navigateTo: ImageItem? = nil

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
                        }
                        Spacer()
                        Button {
                            withAnimation(.default) {
                                screenshotsExpanded.toggle()
                            }
                        } label: {
                            Image(systemName: screenshotsExpanded ? "chevron.down" : "chevron.right")
                                .frame(width: 30, height: 30)
                                .font(Font.system(size: 14, weight: .bold))
                        }
                        .glassEffect(.regular.tint(.gray.opacity(0.2)), in: .circle)
                    }
                    .padding(20)

                    if screenshotsExpanded {
                        ScrollView(.horizontal) {
                            LazyHStack(spacing: 12) {
                                ForEach(archivedScreenshots) { screenshot in
                                    CollectionItem(width: 200, height: 200, fontSize: 18, asset: screenshot.asset)
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

                LazyVGrid(columns: columns, spacing: 1) {
                    ForEach(allArchivedPhotos) { image in
                        let isSelected = selectedIDs.contains(image.id)

                        PhotoContainer(asset: image.asset)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if isSelectMode {
                                    toggleSelection(image.id)
                                } else {
                                    navigateTo = image
                                }
                            }
                            .overlay {
                                if isSelectMode && isSelected {
                                    Color.black.opacity(0.25)
                                        .allowsHitTesting(false)
                                }
                            }
                            .overlay(alignment: .bottomTrailing) {
                                if isSelectMode {
                                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                        .font(.system(size: 22))
                                        .foregroundStyle(isSelected ? Color.accentColor : .white)
                                        .shadow(color: .black.opacity(0.5), radius: 2)
                                        .padding(6)
                                        .allowsHitTesting(false)
                                }
                            }
                            .animation(.easeInOut(duration: 0.15), value: isSelected)
                            .animation(.easeInOut(duration: 0.15), value: isSelectMode)
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
            }
            .navigationTitle("Archive")
            .navigationDestination(item: $navigateTo) { image in
                PhotoDetails(image: image)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if isSelectMode {
                        Button("Unarchive\(selectedIDs.isEmpty ? "" : " (\(selectedIDs.count))")") {
                            vm.unarchiveItems(ids: selectedIDs)
                            selectedIDs = []
                            isSelectMode = false
                            refreshPhotos()
                        }
                        .disabled(selectedIDs.isEmpty)
                    }
                }
                ToolbarSpacer(placement: .topBarTrailing)
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isSelectMode ? "Cancel" : "Select") {
                        isSelectMode.toggle()
                        if !isSelectMode { selectedIDs = [] }
                    }
                }
            }
            .toolbarTitleDisplayMode(.inlineLarge)
            .onAppear { refreshPhotos() }
        }
    }

    private func toggleSelection(_ id: String) {
        if selectedIDs.contains(id) {
            selectedIDs.remove(id)
        } else {
            selectedIDs.insert(id)
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

    private func refreshPhotos() {
        archivedScreenshots = vm.filterImages(archived: true, mediaSubtype: .photoScreenshot)
        allArchivedPhotos = vm.filterImages(archived: true, mediaSubtype: nil)
        screenshotsExpanded = !archivedScreenshots.isEmpty
    }
}


#Preview {
    Archive()
}
