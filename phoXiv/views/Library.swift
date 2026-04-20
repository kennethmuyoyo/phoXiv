//
//  Library.swift
//  PhotoRecreate
//
//  Created by Kenneth Muyoyo on 15/04/26.
//

import SwiftUI

struct Library: View {
    let grids: [GridItem] = [GridItem(.adaptive(minimum: 80), spacing:1)]
    var body: some View {
        NavigationStack {
            
            
            ScrollView {
                LazyVGrid(columns: grids, spacing: 1) {
                    
                    Group {
                        Image(.photo10)
                            .resizable()
                            .scaledToFit()
                        Image(.photo11)
                            .resizable()
                            .scaledToFit()
                        Image(.photo12)
                            .resizable()
                            .scaledToFit()
                        Image(.photo13)
                            .resizable()
                            .scaledToFit()
                        Image(.photo10)
                            .resizable()
                            .scaledToFit()
                        Image(.photo11)
                            .resizable()
                            .scaledToFit()
                        Image(.photo12)
                            .resizable()
                            .scaledToFit()
                        Image(.photo13)
                            .resizable()
                            .scaledToFit()
                    }
                    
                    Group {
                        Image(.photo10)
                            .resizable()
                            .scaledToFit()
                        Image(.photo11)
                            .resizable()
                            .scaledToFit()
                        Image(.photo12)
                            .resizable()
                            .scaledToFit()
                        Image(.photo13)
                            .resizable()
                            .scaledToFit()
                        Image(.photo10)
                            .resizable()
                            .scaledToFit()
                        Image(.photo11)
                            .resizable()
                            .scaledToFit()
                        Image(.photo12)
                            .resizable()
                            .scaledToFit()
                        Image(.photo13)
                            .resizable()
                            .scaledToFit()
                    }
                    
                    Group {
                        Image(.photo10)
                            .resizable()
                            .scaledToFit()
                        Image(.photo11)
                            .resizable()
                            .scaledToFit()
                        Image(.photo12)
                            .resizable()
                            .scaledToFit()
                        Image(.photo13)
                            .resizable()
                            .scaledToFit()
                        Image(.photo10)
                            .resizable()
                            .scaledToFit()
                        Image(.photo11)
                            .resizable()
                            .scaledToFit()
                        Image(.photo12)
                            .resizable()
                            .scaledToFit()
                        Image(.photo13)
                            .resizable()
                            .scaledToFit()
                    }
                    
                    Group {
                        Image(.photo10)
                            .resizable()
                            .scaledToFit()
                        Image(.photo11)
                            .resizable()
                            .scaledToFit()
                        Image(.photo12)
                            .resizable()
                            .scaledToFit()
                        Image(.photo13)
                            .resizable()
                            .scaledToFit()
                        Image(.photo10)
                            .resizable()
                            .scaledToFit()
                        Image(.photo11)
                            .resizable()
                            .scaledToFit()
                        Image(.photo12)
                            .resizable()
                            .scaledToFit()
                        Image(.photo13)
                            .resizable()
                            .scaledToFit()
                    }
                    
                    Group {
                        Image(.photo10)
                            .resizable()
                            .scaledToFit()
                        Image(.photo11)
                            .resizable()
                            .scaledToFit()
                        Image(.photo12)
                            .resizable()
                            .scaledToFit()
                        Image(.photo13)
                            .resizable()
                            .scaledToFit()
                        Image(.photo10)
                            .resizable()
                            .scaledToFit()
                        Image(.photo11)
                            .resizable()
                            .scaledToFit()
                        Image(.photo12)
                            .resizable()
                            .scaledToFit()
                        Image(.photo13)
                            .resizable()
                            .scaledToFit()
                    }
                    
                }
            }
            .navigationTitle("Photos")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Image(systemName: "line.3.horizontal.decrease")
                }
                ToolbarSpacer(placement: .topBarTrailing)
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
