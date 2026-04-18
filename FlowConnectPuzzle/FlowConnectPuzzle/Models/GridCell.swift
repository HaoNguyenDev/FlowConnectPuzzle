//
//  GridCell.swift
//  FlowConnectPuzzle
//
//  Created by Hao Nguyen on 17/04/2026.
//

import Foundation

struct GridPosition: Hashable, Equatable {
    let row: Int
    let col: Int
}

struct GridCell: Identifiable, Equatable {
    let id = UUID()
    let position: GridPosition
    var number: Int?
    var isInPath: Bool = false
    var isHighlighted: Bool = false
    
    static func == (lhs: GridCell, rhs: GridCell) -> Bool {
        lhs.position == rhs.position &&
        lhs.number == rhs.number &&
        lhs.isInPath == rhs.isInPath &&
        lhs.isHighlighted == rhs.isHighlighted
    }
}

struct PathSegment: Identifiable {
    let id = UUID()
    let from: GridPosition
    let to: GridPosition
}
