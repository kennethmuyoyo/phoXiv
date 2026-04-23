//
//  PoppedCard.swift
//  phoXiv
//
//  Created by Kenneth Muyoyo on 21/04/26.
//
import Combine
import Foundation

struct PoppedCard<Item: Identifiable & Hashable>: Identifiable, Equatable {
    let item: Item
    let initialOffset: CGPoint
    let direction: CardSwipeDirection
    var id: Item.ID { item.id }
}
