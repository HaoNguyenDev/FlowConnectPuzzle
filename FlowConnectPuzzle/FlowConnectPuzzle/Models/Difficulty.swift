//
//  Difficulty.swift
//  FlowConnectPuzzle
//
//  Created by Hao Nguyen on 18/04/2026.
//

import Foundation

/// Puzzle difficulty levels controlling grid size and number count.
///
/// # How Difficulty Works
///
/// Each level defines two parameters that together determine how hard
/// the puzzle is:
///
/// 1. **Grid size** — larger grids have more cells to fill, creating
///    longer paths with more opportunities to go wrong.
///
/// 2. **Number count** (`numberRange`) — more numbered checkpoints
///    divide the solution path into smaller segments, reducing the
///    player's freedom to choose their own route. With 16 checkpoints
///    on a 64-cell grid, each segment is only ~4 cells long, so the
///    player must follow a nearly exact path.
///
/// The actual number count is randomized within `numberRange` each
/// game so that replaying the same difficulty still feels varied.
///
/// See ``PuzzleGenerator`` for how these values feed into the
/// deceptive placement algorithm.
enum Difficulty: String, CaseIterable, Identifiable {
    case easy
    case medium
    case hard
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .easy:   return "Easy"
        case .medium: return "Medium"
        case .hard:   return "Hard"
        }
    }
    
    var gridSize: Int {
        switch self {
        case .easy:   return 5
        case .medium: return 6
        case .hard:   return 8
        }
    }
    
    /// Range of how many numbers to place (inclusive).
    /// The actual count is chosen randomly within this range each game.
    var numberRange: ClosedRange<Int> {
        switch self {
        case .easy:   return 6...8
        case .medium: return 9...12
        case .hard:   return 13...16
        }
    }
    
    var description: String {
        "\(gridSize)×\(gridSize) grid, \(numberRange.lowerBound)–\(numberRange.upperBound) numbers"
    }
    
    var iconName: String {
        switch self {
        case .easy:   return "leaf"
        case .medium: return "flame"
        case .hard:   return "bolt.fill"
        }
    }
}
