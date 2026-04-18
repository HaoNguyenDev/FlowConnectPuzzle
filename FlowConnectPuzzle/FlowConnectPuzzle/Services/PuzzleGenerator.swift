//
//  PuzzleGenerator.swift
//  FlowConnectPuzzle
//
//  Created by Hao Nguyen on 18/04/2026.
//

import Foundation

struct PuzzleConfiguration {
    let gridSize: Int
    let maxNumber: Int
    let numberPositions: [Int: GridPosition]
}

/// Generates guaranteed-solvable puzzles with deceptive number placement.
///
/// # Strategy Overview
///
/// The generator uses a **reverse-engineering** approach instead of
/// brute-force trial-and-error. This guarantees solvability and runs in
/// near-linear time, even for large grids.
///
/// ## Phase 1 — Hamiltonian Path (the hidden solution)
///
/// A Hamiltonian path visits every cell on the grid exactly once.
/// We generate one using **Warnsdorff's algorithm**:
///
/// ```
/// ┌───┬───┬───┬───┬───┐
/// │ 1 │ 2 │ 9 │10 │11 │   Warnsdorff's rule: always move to the
/// ├───┼───┼───┼───┼───┤   unvisited neighbor with the fewest
/// │ 4 │ 3 │ 8 │13 │12 │   remaining unvisited neighbors.
/// ├───┼───┼───┼───┼───┤
/// │ 5 │ 6 │ 7 │14 │15 │   Ties are broken randomly → each game
/// ├───┼───┼───┼───┼───┤   produces a unique path.
/// │20 │19 │18 │17 │16 │
/// ├───┼───┼───┼───┼───┤   Complexity: O(N) where N = cells.
/// │21 │22 │23 │24 │25 │   Fallback: snake/zigzag if heuristic fails.
/// └───┴───┴───┴───┴───┘
/// ```
///
/// Because this path IS a valid solution, any puzzle built on it is
/// automatically solvable — no solver verification needed.
///
/// ## Phase 2 — Deceptive Number Placement (two-pass)
///
/// The path is divided into `maxNumber` equal segments. Each number is
/// placed within its segment using a two-pass optimization:
///
/// **Pass 1 — Maximize consecutive spread:**
/// ```
/// For consecutive numbers N and N+1:
///   → Pick positions that are SPATIALLY FAR on the grid
///   → Forces long, winding routes between checkpoints
///
/// Example: number 3 is at top-left, number 4 at bottom-right
///   → Player must zigzag across the entire board
/// ```
///
/// **Pass 2 — Maximize non-consecutive confusion:**
/// ```
/// For non-consecutive numbers (e.g. 3 and 7):
///   → Try to place them CLOSE together on the grid
///   → Creates "wrong number" traps near the player
///
/// Example: player reaches number 4, sees "7" right next to them
///   → Tempted to path toward 7, but actually needs to find 5
///     which is on the opposite side of the board
/// ```
///
/// The combination: the number you NEED is always far away,
/// while numbers you DON'T need are sitting right next to you.
///
/// ## Difficulty Scaling
///
/// Difficulty is controlled by two factors from ``Difficulty``:
///
/// ```
/// ┌──────────┬───────┬──────────┬──────────────────────────────┐
/// │ Level    │ Grid  │ Numbers  │ Why it's harder              │
/// ├──────────┼───────┼──────────┼──────────────────────────────┤
/// │ Easy     │ 5×5   │  6–8     │ Small grid, fewer checkpoints│
/// │ Medium   │ 6×6   │  9–12    │ More checkpoints, longer path│
/// │ Hard     │ 8×8   │ 13–16    │ Many checkpoints force a     │
/// │          │       │          │ very specific winding route   │
/// └──────────┴───────┴──────────┴──────────────────────────────┘
/// ```
///
/// More numbers = smaller segments = less freedom between checkpoints
/// = the player must follow a nearly exact route to succeed.
///
/// Combined with deceptive placement, hard puzzles present many
/// "obvious" paths that are actually dead ends.
enum PuzzleGenerator {
    
    /// Generate a puzzle for the given difficulty with random number placements.
    static func generate(for difficulty: Difficulty) -> PuzzleConfiguration {
        let gridSize = difficulty.gridSize
        let maxNumber = Int.random(in: difficulty.numberRange)
        
        let path = generateHamiltonianPath(gridSize: gridSize)
        let numberPositions = placeNumbers(along: path, maxNumber: maxNumber)
        
        return PuzzleConfiguration(
            gridSize: gridSize,
            maxNumber: maxNumber,
            numberPositions: numberPositions
        )
    }
    
    // MARK: - Hamiltonian Path Generation (Warnsdorff's Algorithm)
    
    /// Generate a Hamiltonian path visiting every cell exactly once.
    ///
    /// Uses randomized Warnsdorff's heuristic: from the current cell, move to
    /// the unvisited neighbor with the fewest unvisited neighbors of its own.
    /// Ties are broken randomly for puzzle variety.
    private static func generateHamiltonianPath(gridSize: Int) -> [GridPosition] {
        let totalCells = gridSize * gridSize
        
        for _ in 0..<100 {
            let start = GridPosition(
                row: Int.random(in: 0..<gridSize),
                col: Int.random(in: 0..<gridSize)
            )
            
            var visited = Set<GridPosition>()
            var path: [GridPosition] = []
            
            visited.insert(start)
            path.append(start)
            
            while path.count < totalCells {
                guard let current = path.last else { break }
                
                let neighbors = unvisitedNeighbors(
                    of: current, gridSize: gridSize, visited: visited
                )
                
                if neighbors.isEmpty { break }
                
                // Warnsdorff: pick neighbor with fewest onward moves, break ties randomly
                let minDegree = neighbors.map {
                    unvisitedNeighbors(of: $0, gridSize: gridSize, visited: visited).count
                }.min()!
                
                let best = neighbors.filter {
                    unvisitedNeighbors(of: $0, gridSize: gridSize, visited: visited).count == minDegree
                }
                
                let next = best.randomElement()!
                visited.insert(next)
                path.append(next)
            }
            
            if path.count == totalCells {
                return path
            }
        }
        
        // Fallback: deterministic snake/zigzag pattern (always valid)
        return snakePath(gridSize: gridSize)
    }
    
    private static func snakePath(gridSize: Int) -> [GridPosition] {
        var path: [GridPosition] = []
        for row in 0..<gridSize {
            let cols = row.isMultiple(of: 2)
                ? Array(0..<gridSize)
                : Array((0..<gridSize).reversed())
            for col in cols {
                path.append(GridPosition(row: row, col: col))
            }
        }
        return path
    }
    
    private static func unvisitedNeighbors(
        of position: GridPosition,
        gridSize: Int,
        visited: Set<GridPosition>
    ) -> [GridPosition] {
        let directions = [(-1, 0), (1, 0), (0, -1), (0, 1)]
        return directions.compactMap { dRow, dCol in
            let r = position.row + dRow
            let c = position.col + dCol
            guard r >= 0, r < gridSize, c >= 0, c < gridSize else { return nil }
            let neighbor = GridPosition(row: r, col: c)
            return visited.contains(neighbor) ? nil : neighbor
        }
    }
    
    // MARK: - Number Placement
    
    /// Place numbers to maximize difficulty:
    ///
    /// 1. **Consecutive numbers are spatially FAR apart** — forces the player
    ///    to find long, winding routes across the board between checkpoints.
    /// 2. **Non-consecutive numbers end up near each other** as a side effect,
    ///    creating "traps" where the player is tempted toward the wrong number.
    ///
    /// The combination means: the next number you need is always on the other
    /// side of the grid, while a wrong number is sitting right next to you.
    private static func placeNumbers(
        along path: [GridPosition],
        maxNumber: Int
    ) -> [Int: GridPosition] {
        let totalCells = path.count
        let segmentSize = totalCells / maxNumber
        
        // Build segment index ranges for each number
        var segments: [ClosedRange<Int>] = []
        for number in 1...maxNumber {
            let start = (number - 1) * segmentSize
            let end = (number == maxNumber) ? totalCells - 1 : number * segmentSize - 1
            segments.append(start...end)
        }
        
        // --- Pass 1: Maximize distance between consecutive numbers ---
        // For each pair (N, N+1), pick the position in N+1's segment that is
        // spatially FARTHEST from N on the grid. This forces zigzag routes.
        var chosenIndices: [Int] = []
        chosenIndices.append(segments[0].randomElement()!)
        
        for i in 1..<maxNumber {
            let prevPos = path[chosenIndices[i - 1]]
            var bestIdx = segments[i].lowerBound
            var bestDist = -1
            
            for idx in segments[i] {
                let pos = path[idx]
                let dist = manhattan(prevPos, pos)
                if dist > bestDist || (dist == bestDist && Bool.random()) {
                    bestDist = dist
                    bestIdx = idx
                }
            }
            
            chosenIndices.append(bestIdx)
        }
        
        // --- Pass 2: Maximize non-consecutive neighbor confusion ---
        // Try swapping each number's position within its segment to place
        // non-consecutive numbers closer together (creating wrong-number traps)
        // while keeping consecutive numbers far apart.
        for i in 0..<maxNumber {
            let prevDist = consecutiveSpread(chosenIndices, path: path)
            let confusionBefore = nonConsecutiveCloseness(chosenIndices, path: path)
            
            var bestSwapIdx = chosenIndices[i]
            var bestScore = prevDist + confusionBefore
            
            // Sample up to 10 random candidates in this segment
            let candidates = segments[i].shuffled().prefix(10)
            for candidateIdx in candidates {
                var trial = chosenIndices
                trial[i] = candidateIdx
                let spread = consecutiveSpread(trial, path: path)
                let confusion = nonConsecutiveCloseness(trial, path: path)
                let score = spread + confusion
                if score > bestScore {
                    bestScore = score
                    bestSwapIdx = candidateIdx
                }
            }
            
            chosenIndices[i] = bestSwapIdx
        }
        
        var positions: [Int: GridPosition] = [:]
        for i in 0..<maxNumber {
            positions[i + 1] = path[chosenIndices[i]]
        }
        return positions
    }
    
    /// Sum of Manhattan distances between all consecutive number pairs.
    /// Higher = numbers are more spread out = harder to navigate.
    private static func consecutiveSpread(
        _ indices: [Int], path: [GridPosition]
    ) -> Int {
        var total = 0
        for i in 1..<indices.count {
            total += manhattan(path[indices[i - 1]], path[indices[i]])
        }
        return total
    }
    
    /// Measures how close non-consecutive numbers are to each other.
    /// Higher = more "wrong number" traps near the player's position.
    /// We sum inverse distances for non-consecutive pairs that are nearby.
    private static func nonConsecutiveCloseness(
        _ indices: [Int], path: [GridPosition]
    ) -> Int {
        guard indices.count >= 3 else { return 0 }
        var total = 0
        for i in 0..<(indices.count - 2) {
            for j in (i + 2)..<indices.count {
                let dist = manhattan(path[indices[i]], path[indices[j]])
                // Reward pairs that are within 2 cells of each other
                if dist <= 2 {
                    total += (3 - dist) * 2
                }
            }
        }
        return total
    }
    
    private static func manhattan(_ a: GridPosition, _ b: GridPosition) -> Int {
        abs(a.row - b.row) + abs(a.col - b.col)
    }
}
