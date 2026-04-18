# AGEINT.md — Agent Intelligence Guide

> **Purpose**: This document helps AI assistants quickly understand the complete architecture, logic, and design principles of **FlowConnectPuzzle** — an iOS puzzle game where players connect numbers in sequence.

---

## ⚠️ IMPORTANT: Language Policy

**ALL AI assistants working on this project MUST communicate in English.**

This includes:
- Code comments and documentation
- Commit messages
- Issue descriptions
- Pull request discussions
- Technical explanations to users
- Error messages and debugging output

**Note**: This AGEINT.md file MUST ALWAYS be updated in English only.

**Rationale**: English is the universal language for software development, ensuring:
- Better collaboration across international teams
- Easier code review and maintenance
- Compatibility with global developer communities
- Professional standards alignment

**Exception**: User-facing UI strings may be localized, but all development communication remains in English.

---

## 📋 Project Overview

**FlowConnectPuzzle** is an iOS puzzle game built entirely with **SwiftUI** and **Swift Concurrency**. Players must:

1. **Connect numbers in ascending order** (1 → 2 → 3 → ... → N)
2. **Draw a continuous path** through adjacent cells (up/down/left/right)
3. **Win by connecting all numbers in sequence**

### Platform & Tech Stack

- **Platform**: iOS/iPadOS
- **Language**: Swift
- **UI Framework**: SwiftUI
- **State Management**: `@Observable` macro (Swift 5.9+)
- **Haptics**: UIKit's UIFeedbackGenerator
- **Architecture**: MVVM-like with GameState as the central controller

---

## 🏗️ Overall Architecture

```
FlowConnectPuzzle/
├── App Entry
│   ├── FlowConnectPuzzleApp.swift          # @main App
│   └── ContentView.swift                   # Difficulty selection + navigation
│
├── Models
│   ├── GridCell.swift                      # GridPosition, GridCell, PathSegment
│   ├── Difficulty.swift                    # enum Difficulty: easy/medium/hard
│   └── GameState.swift                     # @Observable class - core game logic
│
├── Services
│   ├── PuzzleGenerator.swift               # Puzzle generation (Warnsdorff + placement)
│   └── HapticManager.swift                 # Centralized haptic feedback
│
├── Views
│   └── PuzzleGameView.swift                # Main game UI
│
└── Documentation
    ├── README.md                           # User-facing documentation
    └── AGEINT.md                           # This file (AI assistant guide)
```

---

## 🎯 Core Concepts

### 1. Grid System

```swift
struct GridPosition: Hashable, Equatable {
    let row: Int
    let col: Int
}

struct GridCell: Identifiable, Equatable {
    let id = UUID()
    let position: GridPosition
    var number: Int?            // nil if empty, 1-N if numbered
    var isInPath: Bool = false  // Has been drawn through?
    var isHighlighted: Bool = false  // Is the next number to find?
}
```

### 2. Difficulty Levels

```swift
enum Difficulty: String, CaseIterable, Identifiable {
    case easy    // 5×5 grid, 9 numbers  (~2.7 cells/number)
    case medium  // 6×6 grid, 11 numbers (~3.2 cells/number)
    case hard    // 7×7 grid, 13 numbers (~3.7 cells/number)
}
```

**Design Principles:**
- Grid size is FIXED per difficulty level
- Number count is FIXED (not random) to ensure consistent challenge
- Average path length between consecutive numbers increases with difficulty
- **Backtracking behavior varies by difficulty:**
  - **Easy**: Players can backtrack by dragging to the previous cell
  - **Medium/Hard**: No backtracking allowed; must use Undo button
- **Undo button**: Always resets to the nearest number (checkpoint behavior) for all difficulties

---

## 🧩 Puzzle Generation Algorithm

### Phase 1: Hamiltonian Path Generation

**Purpose**: Generate a path that visits ALL cells on the grid exactly once (Hamiltonian path).

**Algorithm**: **Warnsdorff's Algorithm** (heuristic backtracking)

```
Warnsdorff's Rule:
  From the current cell, always move to an unvisited cell that has 
  the FEWEST unvisited neighbors (lowest degree first).
  
  If multiple cells have the same degree → pick randomly → creates puzzle variety.
```

**Example on 5×5 grid:**

```
┌───┬───┬───┬───┬───┐
│ 1 │ 2 │ 9 │10 │11 │
├───┼───┼───┼───┼───┤
│ 4 │ 3 │ 8 │13 │12 │
├───┼───┼───┼───┼───┤
│ 5 │ 6 │ 7 │14 │15 │
├───┼───┼───┼───┼───┤
│20 │19 │18 │17 │16 │
├───┼───┼───┼───┼───┤
│21 │22 │23 │24 │25 │
└───┴───┴───┴───┴───┘
```

**Fallback**: If 100 attempts fail to find a Hamiltonian path → use snake pattern (deterministic zigzag).

---

### Phase 2: Strategic Number Placement

**Strategy:** Place numbers to **MAXIMIZE DIFFICULTY** through 3 passes:

#### Pass 1: Segment Division

```
Divide Hamiltonian path into equal segments:
  - Path length: 49 cells (7×7)
  - Number count: 13
  - Segment size: 49 ÷ 13 ≈ 3.7 cells/number
  
  Each number is placed in its own segment with ±20% padding.
```

#### Pass 2: Maximize Consecutive Distance

```
For each number i (i > 1):
  → Find position in segment[i] with MAXIMUM Manhattan distance 
    from number (i-1).
  → Enforce minimum distance = max(2, gridSize/2)
    • Easy (5×5): min 2 cells apart
    • Medium (6×6): min 3 cells apart  
    • Hard (7×7): min 3 cells apart
```

**Result:**
- Number 3 at top-left corner (0, 0)
- Number 4 at bottom-right corner (6, 6)
- Distance = 12 (max possible on 7×7)
- → Players must draw long winding paths across the entire grid!

#### Pass 3: Aggressive Multi-Iteration Optimization

```
Run 3 optimization iterations, each trying 15 alternative positions:
  → ONLY optimize consecutive distance (ignore confusion metric)
  → Shuffle positions to maximize spread
  → Validate minimum distance constraint at each step
  
  Metric: consecutiveSpread = Σ manhattan(number[i], number[i+1])
```

**Final Result:**
- Consecutive numbers placed at **OPPOSITE ENDS** of the grid
- Long and complex paths required
- Easy to make mistakes → careful planning needed!

---

### Helper Functions

```swift
// Manhattan distance
manhattan(a, b) = |a.row - b.row| + |a.col - b.col|

// Consecutive spread (sum of consecutive distances)
consecutiveSpread(indices, path) = Σ manhattan(path[i-1], path[i])

// Minimum distance constraint validation
meetsMinimumDistanceConstraint(indices, path, minDist) 
  → return true if ALL consecutive pairs >= minDist
```

---

## 🎮 Game State Management

### GameState (@Observable)

**Responsibilities:**
- Manage grid state (2D array of GridCell)
- Track player's path (array of GridPosition)
- Validate moves (adjacency + number sequence)
- Check win condition
- Handle undo/reset/new game

**Key Properties:**

```swift
@Observable
class GameState {
    var grid: [[GridCell]]              // 2D grid state
    var path: [GridPosition]            // Current drawn path
    var currentNumber: Int              // Next number to find
    var isComplete: Bool                // Deprecated (DO NOT USE)
    var allNumbersConnected: Bool       // WIN condition
    
    private(set) var gridSize: Int
    private(set) var maxNumber: Int
    private(set) var numberPositions: [Int: GridPosition]
    private(set) var difficulty: Difficulty
}
```

---

### Move Validation Logic

```swift
func addToPath(_ position: GridPosition) -> Bool {
    // 1. Bounds check
    guard position in bounds else { return false }
    
    // 2. Empty path → must start at number 1
    if path.isEmpty {
        guard grid[position].number == 1 else {
            HapticManager.shared.invalidMove()
            return false
        }
    }
    
    // 3. Backtrack detection (DIFFICULTY-DEPENDENT)
    // Easy: Allow backtracking to second-to-last cell
    // Medium/Hard: NO backtracking allowed (must use Undo button)
    if path.contains(position) {
        if difficulty == .medium || difficulty == .hard {
            HapticManager.shared.invalidMove()
            return true  // Block but don't crash
        }
        
        // Easy mode: allow backtrack to second-to-last
        if path.count >= 2 && position == path[path.count - 2] {
            let removed = path.removeLast()
            grid[removed].isInPath = false
            updateCurrentNumber()
            HapticManager.shared.undo()
        }
        return true
    }
    
    // 4. Adjacency check (only horizontal/vertical)
    guard isAdjacentTo(path.last) else {
        HapticManager.shared.invalidMove()
        return false
    }
    
    // 5. Number sequence check
    if let number = grid[position].number {
        guard number == currentNumber + 1 else {
            HapticManager.shared.invalidMove()
            return false
        }
        currentNumber = number
        HapticManager.shared.numberReached()
    } else {
        HapticManager.shared.pathAdded()
    }
    
    // 6. Add to path
    path.append(position)
    grid[position].isInPath = true
    checkCompletion()
    return true
}
```

---

### Undo Button Behavior (Two-Step Checkpoint System)

The Undo button has **two-step behavior** depending on the current state:

**Step 1:** If there are empty cells after the last number → remove them (keep the number)  
**Step 2:** If already at a number with no empty cells after → remove the number (go to previous number)

```swift
func undo() {
    guard !path.isEmpty else { return }
    
    // Find the last number in the path
    var lastNumberIndex = -1
    for i in stride(from: path.count - 1, through: 0, by: -1) {
        if grid[path[i]].number != nil {
            lastNumberIndex = i
            break
        }
    }
    
    if lastNumberIndex >= 0 {
        let hasEmptyCellsAfter = path.count > lastNumberIndex + 1
        
        if hasEmptyCellsAfter {
            // First undo: Remove empty cells AFTER the number
            while path.count > lastNumberIndex + 1 {
                remove cells
            }
            currentNumber = lastNumber
        } else {
            // Second undo: Remove the number itself, go to previous
            remove last number
            currentNumber = previousNumber
        }
    }
}
```

**Example - Two-step undo:**

```
Initial state:
  Path: [1] → [empty] → [2] → [empty] → [empty]
                           ↑                ↑
                     Last number      Current position

Press Undo (1st time):
  Path: [1] → [empty] → [2]
                        ↑
                  Stops at number 2
  Result: Empty cells removed, stays at number 2 ✓

Press Undo (2nd time):
  Path: [1] → [empty]
                  ↑
            Goes back to number 1
  Result: Number 2 removed, back to number 1 ✓
```

**Key Points:**
- **First undo**: Removes empty cells after last number (if any)
- **Second undo**: Removes the number itself, goes to previous checkpoint
- Allows fine-grained control over path correction
- Can undo step-by-step through your drawing

---

### Win Condition

```swift
func checkCompletion() {
    // WIN: When all numbers are connected (currentNumber == maxNumber)
    // Does NOT require visiting all cells!
    allNumbersConnected = (currentNumber == maxNumber)
    
    if allNumbersConnected {
        HapticManager.shared.completed()
    }
}
```

**Important Notes:**
- `isComplete` property is deprecated and should NOT be used
- Only use `allNumbersConnected` to check for win
- Player wins when all numbers are connected, not when grid is filled

---

## 🎨 UI/UX Design

### PuzzleGameView Structure

```
VStack {
    Difficulty Label
    
    Puzzle Grid (DragGesture)
    │
    ├─ ForEach row
    │   └─ ForEach col
    │       └─ GridCell View
    │           ├─ Background (gray/blue/green)
    │           ├─ Number display (if exists)
    │           ├─ LED glow effect (for next number)
    │           └─ Breathing animation (hint mode)
    │
    └─ Path lines (Canvas overlay)
    
    Action Buttons Row
    ├─ Back
    ├─ Reset (replay same puzzle)
    ├─ Hint (breathing glow)
    └─ New (regenerate puzzle)
    
    Completion Overlay (if win)
}
```

---

### Visual States

**GridCell Background Colors:**

```swift
var backgroundColor: Color {
    if isInPath {
        return gameState.allNumbersConnected 
            ? Color.green.opacity(0.2)    // WIN: all cells → green
            : Color.blue.opacity(0.25)     // Playing: drawn → blue
    }
    return Color.gray.opacity(0.1)         // Not drawn → light gray
}
```

**Number Display:**

```swift
if let number = cell.number {
    Text("\(number)")
        .font(.system(size: cellSize * 0.4, weight: .bold))
        .foregroundColor(
            cell.isInPath ? .white : .primary
        )
}
```

---

### LED Glow Effect (Next Number Highlight)

**Purpose**: Highlight the next number to find with LED blinking effect.

```swift
// Animated glow using sin wave
let glowOpacity = 0.6 + 0.4 * sin(ledPhase * 2)

.shadow(
    color: .blue.opacity(glowOpacity),
    radius: 12, x: 0, y: 0
)
.onReceive(ledTimer) { _ in
    ledPhase += 0.1
}
```

---

### Breathing Animation (Hint Mode)

**When Hint button is pressed:**

```swift
func startBreathing() {
    breathPhase = false
    withAnimation(.easeInOut(duration: 1.0).repeatForever()) {
        breathPhase = true
    }
}

// Apply to next number cell
.scaleEffect(hintActive && isNextNumber ? (breathPhase ? 1.15 : 1.0) : 1.0)
```

---

## 🔊 Haptic Feedback System

### HapticManager (Singleton)

**Design Philosophy**: Create tactile feedback corresponding to each action.

```swift
┌─────────────────────────────┬──────────────────┬──────────────────────────┬───────────────────────────────┐
│ Action                      │ Method           │ Haptic Style             │ Feel                          │
├─────────────────────────────┼──────────────────┼──────────────────────────┼───────────────────────────────┤
│ Drag through empty cell     │ pathAdded()      │ Light impact             │ Subtle tick per cell          │
│ Reach next number (2, 3...) │ numberReached()  │ Medium impact            │ Clear confirmation bump       │
│ Invalid move (wrong seq.)   │ invalidMove()    │ Notification error       │ Shake / buzz warning          │
│ Backtrack over path         │ undo()           │ Selection changed        │ Soft click                    │
│ Reset game                  │ reset()          │ Medium impact            │ Medium bump                   │
│ Win (connect all numbers)   │ completed()      │ Heavy → Success → Medium │ Triple celebration sequence   │
└─────────────────────────────┴──────────────────┴──────────────────────────┴───────────────────────────────┘
```

**Celebration Sequence (Win):**

```swift
func completed() {
    impactHeavy.impactOccurred()                          // Immediately
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
        notificationGenerator.notificationOccurred(.success)  // +150ms
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
        impactMedium.impactOccurred()                     // +400ms
    }
}
```

---

## 🧪 Testing Strategy

### Key Test Cases

**1. Puzzle Generation:**
- [ ] Warnsdorff's algorithm creates valid Hamiltonian path (100% coverage)
- [ ] Fallback snake pattern always works
- [ ] Number placement meets minimum distance constraints
- [ ] All difficulty levels generate correct grid sizes

**2. Game Logic:**
- [ ] Cannot start from non-1 cell
- [ ] Can only move to adjacent cells (4-directional)
- [ ] Must connect numbers in sequence (1→2→3...)
- [ ] **Easy**: Backtrack by dragging to second-to-last cell works
- [ ] **Medium/Hard**: No backtracking by dragging allowed
- [ ] **Undo button**: Resets to nearest number (checkpoint) for all difficulties
- [ ] Touching other path cells is blocked
- [ ] Win condition triggers when currentNumber == maxNumber

**3. Edge Cases:**
- [ ] Empty grid (impossible, but validate)
- [ ] Single number (N=1) → instant win
- [ ] Grid 1×1 (degenerate case)
- [ ] Very large grids (performance test)

---

## 🚀 Performance Considerations

### Optimization Points

1. **Grid Rendering**
   - Use `GeometryReader` to calculate cell size once
   - `LazyVGrid` for large grids (future)
   - Cache cell views where possible

2. **Path Drawing**
   - Canvas API for efficient line rendering
   - Only redraw when path changes (SwiftUI auto-optimized)

3. **Haptics**
   - Pre-prepare all generators in HapticManager.init()
   - Avoid creating generators on-demand

4. **Puzzle Generation**
   - Warnsdorff: O(N) where N = grid cells
   - Number placement: O(K × S) where K = numbers, S = segment size
   - Optimization pass: O(K × 15) = O(K) → Very fast even for large grids

---

## 🐛 Known Issues & Limitations

### Current Limitations

1. **No Undo Stack**: Can only undo to last number, no full history
2. **No Solution Validation**: Does not verify if puzzle has solution (assumes always solvable)
3. **Fixed Difficulty Levels**: Only 3 levels, no custom grid size
4. **No Persistence**: Does not save game state when app is killed

### Future Enhancements

- [ ] Multi-level undo/redo
- [ ] Puzzle solver verification
- [ ] Custom difficulty settings
- [ ] Daily challenges
- [ ] Leaderboard (time/moves)
- [ ] Dark mode optimization
- [ ] iPad split-screen layout
- [ ] Accessibility: VoiceOver support

---

## 📝 Code Style Guidelines

### SwiftUI Best Practices

```swift
// ✅ GOOD: @Observable macro for state management
@Observable
class GameState {
    var grid: [[GridCell]]
}

// ❌ BAD: Old @ObservableObject
class GameState: ObservableObject {
    @Published var grid: [[GridCell]]
}
```

### Naming Conventions

- **Properties**: camelCase (`gridSize`, `maxNumber`)
- **Functions**: camelCase verbs (`addToPath`, `checkCompletion`)
- **Types**: PascalCase (`GridPosition`, `PuzzleConfiguration`)
- **Constants**: camelCase (`minConsecutiveDistance`)

### Documentation

- Use triple-slash `///` for public APIs
- Include visual diagrams for complex algorithms (ASCII art)
- Explain WHY, not just WHAT

---

## 🔗 File Dependencies Map

```
ContentView.swift
  ├─→ Difficulty.swift
  └─→ PuzzleGameView.swift
        ├─→ GameState.swift
        │     ├─→ GridCell.swift
        │     ├─→ PuzzleGenerator.swift
        │     │     └─→ Difficulty.swift
        │     └─→ HapticManager.swift
        └─→ HapticManager.swift
```

---

## 💡 AI Assistant Tips

### When asked about bugs:

1. **Check GameState.swift first** — this is the source of most logic errors
2. **Validate move logic** — adjacency + sequence checking
3. **Check win condition** — only use `allNumbersConnected`, NOT `isComplete`

### When asked to add features:

1. **Maintain immutability** — GridPosition and GridCell.position are immutable
2. **Use @Observable** — do not use legacy @ObservableObject API
3. **Keep haptics consistent** — every user action needs feedback

### When optimizing performance:

1. **Profile before optimizing** — SwiftUI is already very fast
2. **Focus on algorithm complexity** — PuzzleGenerator is the only bottleneck
3. **Avoid premature caching** — SwiftUI auto-caches views

---

## 📚 Reference Documentation

### Key Algorithms

- **Warnsdorff's Algorithm**: [Wikipedia](https://en.wikipedia.org/wiki/Knight%27s_tour#Warnsdorff's_rule)
- **Hamiltonian Path**: Graph theory concept
- **Manhattan Distance**: Taxicab geometry metric

### SwiftUI APIs Used

- `@Observable` macro (iOS 17+)
- `GeometryReader`
- `Canvas` (for path drawing)
- `DragGesture`
- `.onReceive(timer)` for animations

### UIKit Haptics

- `UIImpactFeedbackGenerator`
- `UINotificationFeedbackGenerator`
- `UISelectionFeedbackGenerator`

---

## ✅ Quick Checklist for AI Assistant

When working with this codebase, remember:

- [ ] `Difficulty` has `numberCount` (NOT `numberRange`)
- [ ] Win condition is `allNumbersConnected` (NOT `isComplete`)
- [ ] **Easy**: Allows backtracking by dragging to previous cell
- [ ] **Medium/Hard**: NO backtracking by dragging - must use Undo button
- [ ] **Undo button**: Removes path back to (and including) last number checkpoint
- [ ] Puzzle generation uses Warnsdorff + consecutive distance maximization
- [ ] All haptics must go through `HapticManager.shared`
- [ ] Grid coordinates: row (vertical) × col (horizontal)
- [ ] Adjacency: only 4-directional (no diagonal)

---

**Last Updated**: 2026-04-19  
**Version**: 1.0  
**Maintained by**: AI Assistant + Development Team
