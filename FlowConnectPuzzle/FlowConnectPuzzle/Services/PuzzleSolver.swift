//
//  PuzzleSolver.swift
//  FlowConnectPuzzle
//
//  Created by Hao Nguyen on 17/04/2026.
//

import Foundation

/// Helper class to find and validate solutions for the puzzle
class PuzzleSolver {
    let gridSize: Int
    let numberPositions: [Int: GridPosition]
    let maxNumber: Int
    
    init(gridSize: Int, numberPositions: [Int: GridPosition], maxNumber: Int) {
        self.gridSize = gridSize
        self.numberPositions = numberPositions
        self.maxNumber = maxNumber
    }
    
    /// Find the optimal solution path connecting all numbers and filling all cells
    /// Returns the complete path or nil if no solution exists
    func findSolution() -> [GridPosition]? {
        var visited = Set<GridPosition>()
        var path: [GridPosition] = []
        
        guard let startPos = numberPositions[1] else { return nil }
        
        if depthFirstSearch(from: startPos, currentNumber: 1, path: &path, visited: &visited) {
            return path
        }
        
        return nil
    }
    
    /// Get the next step in the solution from current position
    func getHint(currentPath: [GridPosition], currentNumber: Int) -> GridPosition? {
        guard let solution = findSolution() else { return nil }
        
        // Find where we are in the solution
        let currentLength = currentPath.count
        
        // If we're on track with the solution, return next step
        if currentLength < solution.count {
            return solution[currentLength]
        }
        
        return nil
    }
    
    // MARK: - Private Methods
    
    private func depthFirstSearch(
        from position: GridPosition,
        currentNumber: Int,
        path: inout [GridPosition],
        visited: inout Set<GridPosition>
    ) -> Bool {
        // Add current position to path
        path.append(position)
        visited.insert(position)
        
        // Check if we've completed the puzzle
        if currentNumber == maxNumber && path.count == gridSize * gridSize {
            return true
        }
        
        // Get next number position we need to reach
        let nextNumber = currentNumber + 1
        let targetPosition = nextNumber <= maxNumber ? numberPositions[nextNumber] : nil
        
        // Try all possible next moves
        let neighbors = getNeighbors(of: position)
        
        for neighbor in neighbors {
            // Skip if already visited
            if visited.contains(neighbor) {
                continue
            }
            
            // If this is a numbered cell, check if it's the right number
            if isNumberedCell(neighbor) {
                // Must be the next number in sequence
                guard neighbor == targetPosition else {
                    continue
                }
                
                // Try this path
                if depthFirstSearch(
                    from: neighbor,
                    currentNumber: nextNumber,
                    path: &path,
                    visited: &visited
                ) {
                    return true
                }
            } else {
                // Regular cell - but only explore if we haven't reached all numbers yet
                // or if this path could lead to filling all cells
                if currentNumber < maxNumber || canReachTarget(from: neighbor, target: targetPosition, visited: visited) {
                    if depthFirstSearch(
                        from: neighbor,
                        currentNumber: currentNumber,
                        path: &path,
                        visited: &visited
                    ) {
                        return true
                    }
                }
            }
        }
        
        // Backtrack
        path.removeLast()
        visited.remove(position)
        
        return false
    }
    
    private func getNeighbors(of position: GridPosition) -> [GridPosition] {
        var neighbors: [GridPosition] = []
        
        let directions = [
            (-1, 0), // Up
            (1, 0),  // Down
            (0, -1), // Left
            (0, 1)   // Right
        ]
        
        for (dRow, dCol) in directions {
            let newRow = position.row + dRow
            let newCol = position.col + dCol
            
            if newRow >= 0 && newRow < gridSize &&
               newCol >= 0 && newCol < gridSize {
                neighbors.append(GridPosition(row: newRow, col: newCol))
            }
        }
        
        return neighbors
    }
    
    private func isNumberedCell(_ position: GridPosition) -> Bool {
        return numberPositions.values.contains(position)
    }
    
    private func canReachTarget(
        from position: GridPosition,
        target: GridPosition?,
        visited: Set<GridPosition>
    ) -> Bool {
        guard let target = target else { return true }
        
        // Simple heuristic: Manhattan distance
        let distance = abs(position.row - target.row) + abs(position.col - target.col)
        
        // Check if there's enough unvisited cells to potentially reach target
        let unvisitedCount = (gridSize * gridSize) - visited.count
        
        return distance <= unvisitedCount
    }
}

// MARK: - Extension for GameState

extension GameState {
    /// Get a hint for the next move
    func getSmartHint() -> GridPosition? {
        let solver = PuzzleSolver(
            gridSize: gridSize,
            numberPositions: numberPositions,
            maxNumber: maxNumber
        )
        
        return solver.getHint(currentPath: path, currentNumber: currentNumber)
    }
    
    /// Check if the current puzzle is solvable
    func isSolvable() -> Bool {
        let solver = PuzzleSolver(
            gridSize: gridSize,
            numberPositions: numberPositions,
            maxNumber: maxNumber
        )
        
        return solver.findSolution() != nil
    }
    
    /// Get the complete solution path (for debugging/testing)
    func getSolution() -> [GridPosition]? {
        let solver = PuzzleSolver(
            gridSize: gridSize,
            numberPositions: numberPositions,
            maxNumber: maxNumber
        )
        
        return solver.findSolution()
    }
}
