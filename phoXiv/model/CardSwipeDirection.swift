//
//  CardSwipeDirection.swift
//  phoXiv
//
//  Created by Kenneth Muyoyo on 21/04/26.
//

import Foundation

public enum CardSwipeDirection: Sendable, Equatable {
    case left
    case right
    case idle
    
    init(offset: CGFloat) {
        if offset > 0 {
            self = .right
        }
        else if offset < 0 {
            self = .left
        }
        else {
            self = .idle }
    }
}

