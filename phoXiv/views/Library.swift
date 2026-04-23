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
    
    let columns: [GridItem] = [
        GridItem(.adaptive(minimum: 80), spacing: 1)
    ]
    
    var body: some View {
        NavigationStack {
            Group {
                switch vm.authorizationStatus {
                case .authorized, .limited:
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 1) {
                            ForEach(vm.images) { image in
                                if !image.archived {
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
            .toolbar {
                ToolbarSpacer()
                ToolbarItem(placement: .topBarTrailing) {
                    Text("Select")
                        .padding()
                }
            }
            .toolbarTitleDisplayMode(.inlineLarge)
        }
    }
}

#Preview {
    Library()
}
