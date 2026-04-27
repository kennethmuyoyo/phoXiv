//
//  Library.swift
//  PhotoRecreate
//
//  Created by Kenneth Muyoyo on 15/04/26.
//

import SwiftUI
import Combine
import Photos

struct Library: View {
    @EnvironmentObject var vm: LibraryViewModel
    @State private var isSelectMode = false
    @State private var selectedIDs: Set<String> = []
    @State private var navigateTo: ImageItem? = nil

    let columns: [GridItem] = [
        GridItem(.adaptive(minimum: 80), spacing: 1)
    ]

    var visibleImages: [ImageItem] {
        vm.images.filter { !$0.archived }
    }

    var body: some View {
        NavigationStack {
            Group {
                switch vm.authorizationStatus {
                case .authorized, .limited:
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 1) {
                            ForEach(visibleImages) { image in
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
                            }
                        }
                    }

                case .denied, .restricted:
                    VStack {
                        Text("Access to photos is denied.")
                        Button("Open Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                    }

                case .notDetermined:
                    ProgressView("Requesting permission...")

                @unknown default:
                    EmptyView()
                }
            }
            .navigationTitle("Photos")
            .navigationDestination(item: $navigateTo) { image in
                PhotoDetails(image: image)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if isSelectMode {
                        Button("Archive\(selectedIDs.isEmpty ? "" : " (\(selectedIDs.count))")") {
                            vm.archiveItems(ids: selectedIDs)
                            selectedIDs = []
                            isSelectMode = false
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
        }
    }

    private func toggleSelection(_ id: String) {
        if selectedIDs.contains(id) {
            selectedIDs.remove(id)
        } else {
            selectedIDs.insert(id)
        }
    }
}

#Preview {
    Library()
}
