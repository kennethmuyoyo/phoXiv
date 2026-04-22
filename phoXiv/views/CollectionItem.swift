//
//  SwiftUIView.swift
//  PhotoRecreate
//
//  Created by Kenneth Muyoyo on 15/04/26.
//

import SwiftUI

struct CollectionItem: View {
    var width: CGFloat = 120
    var height: CGFloat = 120
    var fontSize: CGFloat = 14
    var image: Image = Image(.photo20)
    
    var body: some View {
        ZStack{
            
            VStack {
                Spacer()
                HStack {
                    
                    Text("Cool Image")
                        .foregroundColor(.white)
                        .font(.system(size: fontSize))
                        .fontWeight(.bold)
                    Spacer()
                }
            }
            .padding(10)
            
        }
        .background(image
            .resizable()
            .scaledToFill()
            .overlay(LinearGradient(gradient: Gradient(colors: [ .black.opacity(0.1),.black.opacity(0.1), .black.opacity(0.5)]), startPoint: .top, endPoint: .bottom))
                    
        )
        
        
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .cornerRadius(20)
        .frame(width: width, height: height)
        
    }
}

#Preview {
    CollectionItem()
}
