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
/// Each level has a FIXED grid size and number count to ensure consistent
/// challenge. The key constraint: connecting all numbers in sequence (1→2→3→...→N)
/// must force the player to visit EVERY cell on the grid.
///
/// **Grid size** — larger grids create longer paths with more cells to cover.
///
/// **Number count** — fixed at the hardest level for consistency. Numbers are
/// strategically placed so consecutive numbers are NEVER adjacent, forcing
/// players to navigate complex winding paths through all cells.
///
/// **Win condition:** Visit ALL cells while connecting numbers 1→2→3→...→N.
///
/// Difficulty progression:
/// - **Easy**: 5×5 grid (25 cells) with 9 numbers — ~2.7 cells per segment
/// - **Medium**: 6×6 grid (36 cells) with 11 numbers — ~3.2 cells per segment
/// - **Hard**: 7×7 grid (49 cells) with 13 numbers — ~3.7 cells per segment
/// - **Very Hard**: 8×8 grid (64 cells) with 15 numbers — ~4.2 cells per segment
/// - **Expert**: 9×9 grid (81 cells) with 17 numbers — ~4.7 cells per segment
///
/// See ``PuzzleGenerator`` for how numbers are strategically placed to
/// maximize puzzle difficulty through deceptive positioning.
enum Difficulty: String, CaseIterable, Identifiable {
    case easy
    case medium
    case hard
    case veryHard
    case expert
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .easy:     return "Easy"
        case .medium:   return "Medium"
        case .hard:     return "Hard"
        case .veryHard: return "Very Hard"
        case .expert:   return "Expert"
        }
    }
    
    var gridSize: Int {
        switch self {
        case .easy:     return 5
        case .medium:   return 6
        case .hard:     return 7
        case .veryHard: return 8
        case .expert:   return 9
        }
    }
    
    /// Fixed number of checkpoints for this difficulty level.
    /// Always uses the maximum count to ensure consistent challenge.
    /// Numbers are placed along a Hamiltonian path that visits all cells,
    /// ensuring that connecting all numbers requires traversing every cell.
    var numberCount: Int {
        switch self {
        case .easy:     return 9   // 25 cells ÷ 9 numbers ≈ 2.7 cells per segment
        case .medium:   return 11  // 36 cells ÷ 11 numbers ≈ 3.2 cells per segment
        case .hard:     return 13  // 49 cells ÷ 13 numbers ≈ 3.7 cells per segment
        case .veryHard: return 15  // 64 cells ÷ 15 numbers ≈ 4.2 cells per segment
        case .expert:   return 17  // 81 cells ÷ 17 numbers ≈ 4.7 cells per segment
        }
    }
    
    var description: String {
        return "\(gridSize)×\(gridSize) grid, \(numberCount) numbers"
    }
    
    var iconName: String {
        switch self {
        case .easy:     return "leaf"
        case .medium:   return "flame"
        case .hard:     return "bolt.fill"
        case .veryHard: return "hurricane"
        case .expert:   return "crown.fill"
        }
    }
}
