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

/// Xorshift64 seeded random number generator (deterministic, fast).
private struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        // Non-zero initial state required for xorshift.
        state = seed == 0 ? 0xcafef00dd15ea5e5 : seed
        _ = next()  // warm up
    }

    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}

/// Generates solvable puzzles with deceptive number placement.
///
/// # Strategy Overview
///
/// The generator creates puzzles where numbers are strategically placed
/// to maximize difficulty through visual deception and spatial distribution.
///
/// ## Phase 1 — Base Path Generation
///
/// While we generate a Hamiltonian path internally for variety, players
/// are NOT required to follow it. The path is used only as a framework
/// for distributing numbers across the grid.
///
/// We use **Warnsdorff's algorithm** for path generation:
///
/// ```
/// ┌───┬───┬───┬───┬───┐
/// │ 1 │ 2 │ 9 │10 │11 │   Warnsdorff's rule: always move to the
/// ├───┼───┼───┼───┼───┤   unvisited neighbor with the fewest
/// │ 4 │ 3 │ 8 │13 │12 │   remaining unvisited neighbors.
/// ├───┼───┼───┼───┼───┤
/// │ 5 │ 6 │ 7 │14 │15 │   Ties are broken randomly → each game
/// ├───┼───┼───┼───┼───┤   produces a unique layout.
/// │20 │19 │18 │17 │16 │
/// ├───┼───┼───┼───┼───┤   Complexity: O(N) where N = cells.
/// │21 │22 │23 │24 │25 │   Fallback: snake/zigzag if heuristic fails.
/// └───┴───┴───┴───┴───┘
/// ```
///
/// ## Phase 2 — Strategic Number Placement
///
/// Numbers are placed at evenly-spaced intervals along the Hamiltonian path,
/// creating segments that the player must navigate. The placement uses a
/// two-pass optimization to maximize difficulty:
///
/// **Pass 1 — Even distribution along path:**
/// ```
/// Divide the path into roughly equal segments:
///   - Path length: 49 cells
///   - Number count: 9
///   - Segment size: 49 ÷ 9 ≈ 5-6 cells per number
///   
/// Numbers are placed at segment boundaries with small randomization
/// to prevent predictable patterns.
/// ```
///
/// **Pass 2 — Maximize spatial spread with minimum distance:**
/// ```
/// Within each segment's valid range, pick the position that:
///   → Maximizes Manhattan distance from the previous number
///   → Must be at least gridSize/2 cells apart (minimum distance)
///   → At minimum, must not be adjacent (distance > 1)
///
/// Example on 7×7 grid (minimum distance = 3):
///   Number 3 at (0, 0) top-left corner
///   Number 4 at (6, 6) bottom-right corner
///   → Distance = 12 (maximum possible on 7×7)
///   → Player must trace VERY LONG winding path between them
/// ```
///
/// **Pass 3 — Aggressive multi-iteration optimization:**
/// ```
/// Run 3 optimization passes, each trying 15 alternative positions:
///   → ONLY optimize for consecutive distance (ignore other factors)
///   → Keep shuffling positions to maximize spread
///   → No "confusion" optimization - pure distance maximization
///
/// Result: Consecutive numbers appear on OPPOSITE sides of grid
///   → Number 5 at top-left, Number 6 at bottom-right
///   → Forces complex navigation through entire grid
///   → Players easily make mistakes choosing wrong paths
/// ```
///
/// The result: Consecutive numbers placed at MAXIMUM distance from each other,
/// creating extremely challenging puzzles where players must carefully plan
/// long winding routes across the entire grid. Easy to make mistakes!
///
/// ## Difficulty Scaling
///
/// Difficulty is controlled by grid size and FIXED number count from ``Difficulty``.
/// Each level has a consistent number count to ensure predictable challenge.
///
/// ```
/// ┌──────────┬───────┬──────────┬────────────┬──────────────────────────┐
/// │ Level    │ Grid  │ Cells    │ Numbers    │ Avg. Segment Length      │
/// ├──────────┼───────┼──────────┼────────────┼──────────────────────────┤
/// │ Easy     │ 5×5   │  25      │    9       │ ~2.7 cells/number        │
/// │ Medium   │ 6×6   │  36      │   11       │ ~3.2 cells/number        │
/// │ Hard     │ 7×7   │  49      │   13       │ ~3.7 cells/number        │
/// └──────────┴───────┴──────────┴────────────┴──────────────────────────┘
/// ```
///
/// **Extreme Distance Strategy:** Consecutive numbers are placed at MAXIMUM
/// distance from each other. Minimum distances by level:
///   - **Easy (5×5)**: min 2 cells, typically 4-6 cells apart
///   - **Medium (6×6)**: min 3 cells, typically 5-8 cells apart
///   - **Hard (7×7)**: min 3 cells, typically 6-12 cells apart
///
/// Players must navigate long winding paths across the grid. The next number
/// always appears FAR away, making mistakes easy and planning essential!
enum PuzzleGenerator {

    /// Generate a random puzzle for the given difficulty.
    static func generate(for difficulty: Difficulty) -> PuzzleConfiguration {
        var rng = SystemRandomNumberGenerator()
        return generate(for: difficulty, rng: &rng)
    }

    /// Generate a deterministic puzzle using the provided seed (used for Daily Challenge).
    static func generate(for difficulty: Difficulty, seed: UInt64) -> PuzzleConfiguration {
        var rng = SeededRNG(seed: seed)
        return generate(for: difficulty, rng: &rng)
    }

    // MARK: - Core Generation (generic over RNG)

    private static func generate<R: RandomNumberGenerator>(
        for difficulty: Difficulty,
        rng: inout R
    ) -> PuzzleConfiguration {
        let gridSize  = difficulty.gridSize
        let maxNumber = difficulty.numberCount
        let path = generateHamiltonianPath(gridSize: gridSize, rng: &rng)
        let numberPositions = placeNumbers(along: path, maxNumber: maxNumber, rng: &rng)
        return PuzzleConfiguration(gridSize: gridSize, maxNumber: maxNumber, numberPositions: numberPositions)
    }

    // MARK: - Hamiltonian Path Generation (Warnsdorff's Algorithm)

    /// Generate a Hamiltonian path visiting every cell exactly once.
    ///
    /// Uses randomized Warnsdorff's heuristic: from the current cell, move to
    /// the unvisited neighbor with the fewest unvisited neighbors of its own.
    /// Ties are broken randomly for puzzle variety.
    private static func generateHamiltonianPath<R: RandomNumberGenerator>(
        gridSize: Int,
        rng: inout R
    ) -> [GridPosition] {
        let totalCells = gridSize * gridSize

        for _ in 0..<100 {
            let start = GridPosition(
                row: Int.random(in: 0..<gridSize, using: &rng),
                col: Int.random(in: 0..<gridSize, using: &rng)
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

                let next = best.randomElement(using: &rng)!
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

    /// Place numbers strategically along the Hamiltonian path:
    ///
    /// 1. **Divide path into segments** — spread numbers evenly along the path
    /// 2. **MAXIMIZE consecutive distance** — consecutive numbers EXTREMELY far apart
    /// 3. **Enforce minimum distance** — consecutive numbers must meet distance threshold
    ///
    /// **Strategy:** Place consecutive numbers as far apart as possible on the grid
    /// to maximize difficulty. Players will struggle to find the correct path because
    /// the next number appears on the opposite side of the grid.
    private static func placeNumbers<R: RandomNumberGenerator>(
        along path: [GridPosition],
        maxNumber: Int,
        rng: inout R
    ) -> [Int: GridPosition] {
        let totalCells = path.count

        // Determine segment boundaries - divide path into roughly equal parts
        let segmentSize = Double(totalCells) / Double(maxNumber)
        var segments: [ClosedRange<Int>] = []

        for number in 1...maxNumber {
            let floatStart = Double(number - 1) * segmentSize
            let floatEnd   = Double(number) * segmentSize

            let start = Int(floatStart)
            let end   = number == maxNumber ? totalCells - 1 : min(Int(floatEnd) - 1, totalCells - 1)

            // Add some padding to allow flexibility in placement
            let paddedStart = max(0, start - Int(segmentSize * 0.2))
            let paddedEnd   = min(totalCells - 1, end + Int(segmentSize * 0.2))

            segments.append(paddedStart...paddedEnd)
        }

        // --- Pass 1: Place first number randomly in its segment ---
        var chosenIndices: [Int] = []
        chosenIndices.append(segments[0].randomElement(using: &rng)!)

        // --- Pass 2: MAXIMIZE spatial distance between consecutive numbers ---
        let gridSize = Int(sqrt(Double(totalCells)))
        let minConsecutiveDistance = max(2, gridSize / 2)

        for i in 1..<maxNumber {
            let prevPos = path[chosenIndices[i - 1]]
            var bestIdx = segments[i].lowerBound
            var bestDist = -1

            // First try: Find position that meets MINIMUM distance requirement
            for idx in segments[i] {
                let pos  = path[idx]
                let dist = manhattan(prevPos, pos)

                if dist < minConsecutiveDistance { continue }

                if dist > bestDist || (dist == bestDist && Bool.random(using: &rng)) {
                    bestDist = dist
                    bestIdx  = idx
                }
            }

            // Second try: If no position meets minimum, ensure at least non-adjacent (dist > 1)
            if bestDist == -1 {
                for idx in segments[i] {
                    let pos  = path[idx]
                    let dist = manhattan(prevPos, pos)

                    if dist <= 1 { continue }

                    if dist > bestDist || (dist == bestDist && Bool.random(using: &rng)) {
                        bestDist = dist
                        bestIdx  = idx
                    }
                }
            }

            // Last resort: just pick the farthest in segment
            if bestDist == -1 {
                for idx in segments[i] {
                    let pos  = path[idx]
                    let dist = manhattan(prevPos, pos)
                    if dist > bestDist || (dist == bestDist && Bool.random(using: &rng)) {
                        bestDist = dist
                        bestIdx  = idx
                    }
                }
            }

            chosenIndices.append(bestIdx)
        }

        // --- Pass 3: Aggressive optimization for MAXIMUM consecutive spread ---
        for _ in 0..<3 {
            for i in 0..<maxNumber {
                let currentSpread = consecutiveSpread(chosenIndices, path: path)

                var bestIdx    = chosenIndices[i]
                var bestSpread = currentSpread

                let candidates = Array(segments[i]).shuffled(using: &rng).prefix(15)
                for candidateIdx in candidates {
                    var trial    = chosenIndices
                    trial[i]     = candidateIdx

                    if !meetsMinimumDistanceConstraint(trial, path: path, minDist: minConsecutiveDistance) {
                        continue
                    }

                    let spread = consecutiveSpread(trial, path: path)
                    if spread > bestSpread {
                        bestSpread = spread
                        bestIdx    = candidateIdx
                    }
                }

                chosenIndices[i] = bestIdx
            }
        }

        // Build final number → position mapping
        var positions: [Int: GridPosition] = [:]
        for i in 0..<maxNumber {
            positions[i + 1] = path[chosenIndices[i]]
        }
        return positions
    }

    // MARK: - Optimization Helpers

    /// Validates that all consecutive numbers meet minimum distance requirement.
    private static func meetsMinimumDistanceConstraint(
        _ indices: [Int],
        path: [GridPosition],
        minDist: Int
    ) -> Bool {
        for i in 1..<indices.count {
            if manhattan(path[indices[i - 1]], path[indices[i]]) < minDist {
                return false
            }
        }
        return true
    }

    /// Sum of Manhattan distances between consecutive number pairs.
    private static func consecutiveSpread(_ indices: [Int], path: [GridPosition]) -> Int {
        var total = 0
        for i in 1..<indices.count {
            total += manhattan(path[indices[i - 1]], path[indices[i]])
        }
        return total
    }

    /// Manhattan distance between two grid positions.
    private static func manhattan(_ a: GridPosition, _ b: GridPosition) -> Int {
        abs(a.row - b.row) + abs(a.col - b.col)
    }
}
