//
//  ImageItem.swift
//  PhotoRecreate
//
//  Created by Kenneth Muyoyo on 20/04/26.
//

import Foundation
import SwiftUI
import Photos

struct ImageItem: Identifiable, Hashable {
    let id: String
    let asset: PHAsset
    var archived: Bool = false
}
