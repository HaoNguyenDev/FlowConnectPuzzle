//
//  GameState.swift
//  FlowConnectPuzzle
//
//  Created by Hao Nguyen on 17/04/2026.
//

import SwiftUI

@Observable
class GameState {
    var grid: [[GridCell]]
    var path: [GridPosition] = []
    var currentNumber: Int = 1
    var isComplete: Bool = false
    var allNumbersConnected: Bool = false
    
    private(set) var gridSize: Int
    private(set) var maxNumber: Int
    private(set) var numberPositions: [Int: GridPosition]
    private(set) var difficulty: Difficulty
    
    init(difficulty: Difficulty = .medium) {
        self.difficulty = difficulty
        let config = PuzzleGenerator.generate(for: difficulty)
        self.gridSize = config.gridSize
        self.maxNumber = config.maxNumber
        self.numberPositions = config.numberPositions
        self.grid = Self.buildGrid(
            gridSize: config.gridSize,
            numberPositions: config.numberPositions
        )
    }
    
    /// Generate a fresh random puzzle (same or different difficulty).
    func newGame(difficulty: Difficulty? = nil) {
        let diff = difficulty ?? self.difficulty
        self.difficulty = diff
        let config = PuzzleGenerator.generate(for: diff)
        self.gridSize = config.gridSize
        self.maxNumber = config.maxNumber
        self.numberPositions = config.numberPositions
        self.grid = Self.buildGrid(
            gridSize: config.gridSize,
            numberPositions: config.numberPositions
        )
        
        path.removeAll()
        currentNumber = 1
        isComplete = false
        allNumbersConnected = false
        
        HapticManager.shared.reset()
    }
    
    /// Reset the current puzzle (replay same number positions).
    func reset() {
        path.removeAll()
        currentNumber = 1
        isComplete = false
        allNumbersConnected = false
        
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                grid[row][col].isInPath = false
                grid[row][col].isHighlighted = (grid[row][col].number == 1)
            }
        }
        
        HapticManager.shared.reset()
    }
    
    func undo() {
        guard !path.isEmpty else { return }
        
        // Find the last number in the path (working backwards)
        var lastNumberIndex = -1
        for i in stride(from: path.count - 1, through: 0, by: -1) {
            let pos = path[i]
            if grid[pos.row][pos.col].number != nil {
                lastNumberIndex = i
                break
            }
        }
        
        // If we found a number in the path
        if lastNumberIndex >= 0 {
            // Check if there are empty cells after the last number
            let hasEmptyCellsAfter = path.count > lastNumberIndex + 1
            
            if hasEmptyCellsAfter {
                // First undo: Remove all cells AFTER the last number (keep the number)
                while path.count > lastNumberIndex + 1 {
                    let removed = path.removeLast()
                    grid[removed.row][removed.col].isInPath = false
                }
                
                // Update current number to the last number in path
                if let lastPos = path.last {
                    let cell = grid[lastPos.row][lastPos.col]
                    if let number = cell.number {
                        currentNumber = number
                    }
                }
            } else {
                // Second undo: Remove current number and cells after previous number
                // Remove the current number
                let removed = path.removeLast()
                grid[removed.row][removed.col].isInPath = false
                
                // Find the previous number (now the new last number)
                var previousNumberIndex = -1
                for i in stride(from: path.count - 1, through: 0, by: -1) {
                    let pos = path[i]
                    if grid[pos.row][pos.col].number != nil {
                        previousNumberIndex = i
                        break
                    }
                }
                
                if previousNumberIndex >= 0 {
                    // Remove cells after the previous number (keep the previous number)
                    while path.count > previousNumberIndex + 1 {
                        let removed = path.removeLast()
                        grid[removed.row][removed.col].isInPath = false
                    }
                    
                    // Update current number to the previous number
                    if let lastPos = path.last {
                        let cell = grid[lastPos.row][lastPos.col]
                        if let number = cell.number {
                            currentNumber = number
                        }
                    }
                } else {
                    // No previous number found, clear everything
                    path.removeAll()
                    for row in 0..<gridSize {
                        for col in 0..<gridSize {
                            grid[row][col].isInPath = false
                        }
                    }
                    currentNumber = 1
                }
            }
        } else {
            // If no numbers found in path (only empty cells after number 1)
            // Clear the entire path
            path.removeAll()
            for row in 0..<gridSize {
                for col in 0..<gridSize {
                    grid[row][col].isInPath = false
                }
            }
            currentNumber = 1
        }
        
        HapticManager.shared.undo()
        checkCompletion()
    }
    
    func addToPath(_ position: GridPosition) -> Bool {
        guard position.row >= 0 && position.row < gridSize &&
              position.col >= 0 && position.col < gridSize else {
            return false
        }
        
        // If path is empty, must start at number 1
        if path.isEmpty {
            guard grid[position.row][position.col].number == 1 else {
                HapticManager.shared.invalidMove()
                return false
            }
            path.append(position)
            grid[position.row][position.col].isInPath = true
            HapticManager.shared.numberReached()
            return true
        }
        
        // Backtrack behavior depends on difficulty:
        // - Easy: Allow backtracking by dragging to the second-to-last cell
        // - Medium/Hard/Very Hard/Expert: No backtracking allowed (must use Undo button)
        if path.contains(position) {
            // For medium, hard, very hard, and expert - block all backtracking attempts
            if difficulty == .medium || difficulty == .hard || difficulty == .veryHard || difficulty == .expert {
                HapticManager.shared.invalidMove()
                return true
            }
            
            // For easy, allow backtracking to the second-to-last cell
            if path.count >= 2 && position == path[path.count - 2] {
                let removed = path.removeLast()
                grid[removed.row][removed.col].isInPath = false
                updateCurrentNumber()
                HapticManager.shared.undo()
            }
            return true
        }
        
        // Check if adjacent to last position
        guard let lastPosition = path.last else { return false }
        let isAdjacent = (abs(position.row - lastPosition.row) == 1 && position.col == lastPosition.col) ||
                        (abs(position.col - lastPosition.col) == 1 && position.row == lastPosition.row)
        
        guard isAdjacent else {
            HapticManager.shared.invalidMove()
            return false
        }
        
        // Check number sequence
        let cell = grid[position.row][position.col]
        if let number = cell.number {
            guard number == currentNumber + 1 else {
                HapticManager.shared.invalidMove()
                return false
            }
            currentNumber = number
            HapticManager.shared.numberReached()
        } else {
            HapticManager.shared.pathAdded()
        }
        
        path.append(position)
        grid[position.row][position.col].isInPath = true
        
        checkCompletion()
        return true
    }
    
    func checkCompletion() {
        let wasConnected = allNumbersConnected
        
        // Check if all numbers have been connected in sequence
        // Player wins by connecting all numbers, regardless of cells visited
        allNumbersConnected = currentNumber == maxNumber
        
        if allNumbersConnected && !wasConnected {
            HapticManager.shared.completed()
        }
    }
    
    // MARK: - Private
    
    private func updateCurrentNumber() {
        currentNumber = 1
        for pos in path {
            if let number = grid[pos.row][pos.col].number, number > currentNumber {
                currentNumber = number
            }
        }
    }
    
    private static func buildGrid(
        gridSize: Int,
        numberPositions: [Int: GridPosition]
    ) -> [[GridCell]] {
        var grid: [[GridCell]] = []
        for row in 0..<gridSize {
            var rowCells: [GridCell] = []
            for col in 0..<gridSize {
                let position = GridPosition(row: row, col: col)
                let number = numberPositions.first(where: { $0.value == position })?.key
                var cell = GridCell(position: position, number: number)
                if number == 1 {
                    cell.isHighlighted = true
                }
                rowCells.append(cell)
            }
            grid.append(rowCells)
        }
        return grid
    }
}
