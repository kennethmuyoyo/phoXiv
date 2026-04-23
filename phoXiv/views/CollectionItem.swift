//
//  SwiftUIView.swift
//  PhotoRecreate
//
//  Created by Kenneth Muyoyo on 15/04/26.
//

import SwiftUI
import Photos

struct CollectionItem: View {
    var width: CGFloat = 120
    var height: CGFloat = 120
    var fontSize: CGFloat = 14
    var asset: PHAsset

    @State private var uiImage: UIImage?

    var body: some View {
        ZStack{

            VStack {
                Spacer()
                HStack {

//                    Text("Cool Image")
//                        .foregroundColor(.white)
//                        .font(.system(size: fontSize))
//                        .fontWeight(.bold)
//                    Spacer()
                }
            }
            .padding(10)

        }
        .background(
            Group {
                if let uiImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    Color.gray
                }
            }
            .overlay(LinearGradient(gradient: Gradient(colors: [ .black.opacity(0.1),.black.opacity(0.1), .black.opacity(0.5)]), startPoint: .top, endPoint: .bottom))
        )


        .clipShape(RoundedRectangle(cornerRadius: 20))
        .cornerRadius(20)
        .frame(width: width, height: height)
        .onAppear {
            let options = PHImageRequestOptions()
            options.isNetworkAccessAllowed = true
            options.deliveryMode = .opportunistic

            PHImageManager.default().requestImage(
                for: asset,
                targetSize: CGSize(width: width * 2, height: height * 2),
                contentMode: .aspectFill,
                options: options
            ) { image, _ in
                self.uiImage = image
            }
        }
    }
}

//#Preview {
//    CollectionItem()
//}
