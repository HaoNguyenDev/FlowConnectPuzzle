# Flow Connect Puzzle

A SwiftUI number-connecting puzzle game inspired by LinkedIn's "Zip" game.

## Overview

Players connect numbered dots in sequence by dragging a path across a grid.
The path can only move horizontally or vertically to adjacent cells and cannot cross itself.
Each game generates a random puzzle that is guaranteed to be solvable.

## Project Structure

```
FlowConnectPuzzle/
├── App/
│   ├── FlowConnectPuzzleApp.swift    # Entry point, SwiftData container
│   └── ContentView.swift             # Difficulty selection → game navigation
├── Models/
│   ├── GridCell.swift                # GridPosition, GridCell, PathSegment
│   └── Difficulty.swift              # Easy/Medium/Hard enum + config
├── ViewModels/
│   └── GameState.swift               # @Observable game state & logic
├── Views/
│   └── PuzzleGameView.swift          # Main game UI (grid, buttons, overlays)
├── Services/
│   ├── PuzzleGenerator.swift         # Hamiltonian path + deceptive placement
│   ├── PuzzleSolver.swift            # DFS solver for hints & validation
│   └── HapticManager.swift           # Haptic feedback singleton
└── SwiftData/
    └── Item.swift                    # Template model (unused)
```

## Difficulty System

| Level  | Grid | Numbers | Description                           |
|--------|------|---------|---------------------------------------|
| Easy   | 5×5  | 6–8     | Small grid, fewer checkpoints         |
| Medium | 6×6  | 9–12    | More checkpoints, longer path         |
| Hard   | 8×8  | 13–16   | Many checkpoints, very specific route |

Number count is randomized within the range each game for variety.
More numbers = smaller path segments = less freedom = harder.

## Puzzle Generation Algorithm

### Phase 1 — Hamiltonian Path (Warnsdorff's Algorithm)

Generates a path that visits every cell exactly once. This path IS the solution.
- Warnsdorff's rule: move to the unvisited neighbor with fewest unvisited neighbors
- Ties broken randomly → unique puzzle each game
- O(N) complexity, runs in microseconds
- Fallback: snake/zigzag pattern if heuristic fails (rare)

### Phase 2 — Deceptive Number Placement (Two-Pass)

Numbers are placed along the Hamiltonian path within equal segments.

**Pass 1 — Maximize consecutive spread:**
- Consecutive numbers (N, N+1) placed spatially FAR apart on the grid
- Forces long, winding routes between checkpoints

**Pass 2 — Maximize non-consecutive confusion:**
- Non-consecutive numbers (e.g., 3 and 7) placed CLOSE together
- Creates "wrong number" traps near the player's position

Result: the number you NEED is always far away, while numbers you DON'T need are right next to you.

## Game Logic

### Path Drawing Rules
- Must start at number 1
- Only horizontal/vertical moves to adjacent cells
- Must visit numbers in sequence (1→2→3→...→N)
- Cannot cross existing path
- Backtracking: only single-step (drag to second-to-last cell)
- Touching any other existing path cell is blocked (no path reset)

### Completion
- Game is won when `currentNumber == maxNumber` (all numbers connected in order)
- Completion overlay with "Next Puzzle" button

### Actions
- **Reset**: Replay same puzzle (same number positions)
- **New**: Generate fresh random puzzle (same difficulty)
- **Hint**: Tap to show breathing glow animation on next target number
- **Back**: Return to difficulty selection

## Hint System

- Default: no animation on any number badge
- Tap Hint button → next target number shows LED comet ring + breathing glow
- Player reaches that number → animation auto-hides
- Button disabled when puzzle not started or already completed

## Haptic Feedback

| Action                     | Feel                         |
|----------------------------|------------------------------|
| Drag through empty cell    | Light tap                    |
| Reach next number          | Medium bump                  |
| Invalid move               | Error buzz                   |
| Backtrack (single step)    | Soft click                   |
| Reset / New game           | Medium bump                  |
| Win (all numbers connected)| Triple celebration sequence   |

## UI Rendering

- Grid rendered with `GeometryReader`, cell size = width / gridSize
- Path drawn with SwiftUI `Canvas` (lines between cell centers)
- Number badges: black circles with white text, scaled by cellSize
- Hint animation: cyan breathing glow + AngularGradient comet ring
- All rendering is fully dynamic — works with any grid size

## Technical Stack

- **iOS 17.0+** / **Xcode 15.0+** / **Swift 5.9+**
- **State**: `@Observable` macro (no Combine for state)
- **Rendering**: SwiftUI `Canvas` for path, `GeometryReader` for layout
- **Gestures**: `DragGesture(minimumDistance: 0)`
- **Haptics**: UIKit feedback generators via singleton

## Architecture Notes

- **PuzzleGenerator vs PuzzleSolver**: Generator creates puzzles (fast, O(N), Warnsdorff).
  Solver validates/hints (slow, DFS brute-force). Generator does NOT use Solver —
  solvability is guaranteed by construction.
- **Navigation**: Simple `@State selectedDifficulty: Difficulty?` conditional view swap,
  no NavigationStack needed for two screens.
- **LedBorderButton**: Reusable component in project but not currently used in game views.

## Authors

Created by Hao Nguyen & Steven Tran — April 2026.
