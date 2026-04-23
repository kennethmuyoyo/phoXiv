//
//  ImageItem.swift
//  PhotoRecreate
//
//  Created by Kenneth Muyoyo on 20/04/26.
//

import Foundation
import SwiftUI

struct ImageItem: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var description: String
    let imageName: String
    let image: String
    var imageHeight: Float
    var imageWidth: Float
}
 
#if DEBUG
let imageMock: [ImageItem] = [
    ImageItem(
        title: "Mountain Sunrise",
        description: "Golden light breaking over snow-capped peaks in the early morning.",
        imageName: "photo_1",
        image: "photo_10",
        imageHeight: 1920,
        imageWidth: 1080
    ),
    ImageItem(
        title: "City Lights",
        description: "Cityscape illuminated at dusk with twinkling lights.",
        imageName: "photo_2",
        image: "photo_11",
        imageHeight: 1920,
        imageWidth: 1080
    ),
    ImageItem(
        title: "Ocean View",
        description: "Relaxing beach scene with gentle waves crashing on the shore.",
        imageName: "photo_3",
        image: "photo_12",
        imageHeight: 1920,
        imageWidth: 1080
    ),
    ImageItem(
        title: "Desert Sunset",
        description: "Sunset over a vast desert landscape with fiery hues.",
        imageName: "photo_5",
        image: "photo_14",
        imageHeight: 1920,
        imageWidth: 1080
    ),
    ImageItem(
        title: "Forest Path",
        description: "Path through a dense forest with towering trees and a tranquil atmosphere.",
        imageName: "photo_6",
        image: "photo_15",
        imageHeight: 1920,
        imageWidth: 1080
    ),
    ImageItem(
        title: "Underwater City",
        description: "City-like structures submerged in water, creating an otherworldly scene.",
        imageName: "photo_7",
        image: "photo_16",
        imageHeight: 1920,
        imageWidth: 1080
    ),
    ImageItem(
        title: "Frozen Lake",
        description: "Scene of a serene lake frozen over with pristine white ice.",
        imageName: "photo_8",
        image: "photo_17",
        imageHeight: 1920,
        imageWidth: 1080
    ),
    ImageItem(
        title: "Desert Valley",
        description: "Stretching horizon of a vast, sandy desert valley.",
        imageName: "photo_9",
        image: "photo_13",
        imageHeight: 1920,
        imageWidth: 1080
    ),
    ImageItem(
        title: "Placeholder",
        description: "A placeholder image for when more data is not yet available.",
        imageName: "placeholder",
        image: "placeholder",
        imageHeight: 1,
        imageWidth: 1
    )
]
#endif

