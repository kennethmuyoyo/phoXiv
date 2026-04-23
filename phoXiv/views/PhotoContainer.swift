//
//  PhotoContainer.swift
//  phoXiv
//
//  Created by Nil on 20/04/26.
//
import SwiftUI
import Photos

struct PhotoContainer: View {
    let asset: PHAsset    
    @StateObject private var vm = PhotoDetailsViewModel()


    var body: some View {
        GeometryReader { proxy in
            let side = proxy.size.width
            
            ZStack {
                vm.image?
                    .resizable()
                    .scaledToFill()
            }
            .frame(width: side, height: side)
            .clipped()
        }
        .aspectRatio(1, contentMode: .fit)
        .onAppear {
            vm.loadImageThumbnail(from: asset)
        }
    }
}
