//
//  ImageItem.swift
//  PhotoRecreate
//
//  Created by Kenneth Muyoyo on 20/04/26.
//

import Foundation
import SwiftUI

struct ImageItem: Identifiable {
    let id = UUID()
    var title: String
    var description: String
    let imageName: String
    let image: Image
    var imageHeight: Float
    var imageWidth: Float
    
    let imageMock: [ImageItem] = [
        ImageItem(
            title: "Mountain Sunrise",
            description: "Golden light breaking over snow-capped peaks in the early morning.",
            imageName: "photo_1",
            image: Image("photo_1"),
            imageHeight: 1920,
            imageWidth: 1080
        ),
        ImageItem(
            title: "Ocean Waves",
            description: "Turquoise waves crashing against a rocky shoreline at sunset.",
            imageName: "photo_2",
            image: Image("photo_2"),
            imageHeight: 1440,
            imageWidth: 2160
        ),
        ImageItem(
            title: "Forest Path",
            description: "A misty trail winding through ancient redwood trees.",
            imageName: "photo_3",
            image: Image("photo_3"),
            imageHeight: 2048,
            imageWidth: 1365
        ),
        ImageItem(
            title: "City Skyline",
            description: "Downtown skyscrapers illuminated against a deep blue twilight sky.",
            imageName: "photo_4",
            image: Image("photo_4"),
            imageHeight: 1080,
            imageWidth: 1920
        ),
        ImageItem(
            title: "Desert Dunes",
            description: "Rolling sand dunes casting long shadows at golden hour.",
            imageName: "photo_5",
            image: Image("photo_5"),
            imageHeight: 1600,
            imageWidth: 2400
        ),
        ImageItem(
            title: "Autumn Leaves",
            description: "Vibrant red and orange maple leaves scattered on a forest floor.",
            imageName: "photo_6",
            image: Image("photo_6"),
            imageHeight: 1800,
            imageWidth: 1200
        ),
        ImageItem(
            title: "Northern Lights",
            description: "Green aurora borealis dancing across a starry Arctic sky.",
            imageName: "photo_7",
            image: Image("photo_7"),
            imageHeight: 1440,
            imageWidth: 2560
        ),
        ImageItem(
            title: "Tropical Beach",
            description: "White sand and palm trees bordering crystal-clear turquoise water.",
            imageName: "photo_8",
            image: Image("photo_8"),
            imageHeight: 1365,
            imageWidth: 2048
        ),
        ImageItem(
            title: "Snowy Village",
            description: "A quiet alpine village blanketed in fresh winter snow.",
            imageName: "photo_9",
            image: Image("photo_9"),
            imageHeight: 1920,
            imageWidth: 1280
        ),
        ImageItem(
            title: "Cherry Blossoms",
            description: "Pink sakura petals framing a traditional Japanese temple.",
            imageName: "photo_10",
            image: Image("photo_10"),
            imageHeight: 2160,
            imageWidth: 1440
        ),
        ImageItem(
            title: "Lavender Fields",
            description: "Endless rows of purple lavender stretching toward the horizon in Provence.",
            imageName: "photo_11",
            image: Image("photo_11"),
            imageHeight: 1200,
            imageWidth: 1800
        ),
        ImageItem(
            title: "Waterfall Cascade",
            description: "A powerful waterfall plunging into a mist-covered rocky pool.",
            imageName: "photo_12",
            image: Image("photo_12"),
            imageHeight: 2400,
            imageWidth: 1600
        ),
        ImageItem(
            title: "Starry Night",
            description: "The Milky Way arching over silhouetted mountain peaks.",
            imageName: "photo_13",
            image: Image("photo_13"),
            imageHeight: 1440,
            imageWidth: 2160
        ),
        ImageItem(
            title: "Coastal Cliffs",
            description: "Dramatic sea cliffs meeting the Atlantic ocean along the Irish coast.",
            imageName: "photo_14",
            image: Image("photo_14"),
            imageHeight: 1080,
            imageWidth: 1920
        ),
        ImageItem(
            title: "Lotus Pond",
            description: "Pink lotus flowers floating on a serene reflective pond at dawn.",
            imageName: "photo_15",
            image: Image("photo_15"),
            imageHeight: 1600,
            imageWidth: 1600
        )
    ]
}
