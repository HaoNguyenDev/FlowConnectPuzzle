# AGENT.md — Agent Intelligence Guide

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

**Note**: This AGENT.md file MUST ALWAYS be updated in English only.

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
- **Persistence**: UserDefaults (statistics, achievements, theme, onboarding state)
- **Architecture**: MVVM-like with GameState as the central controller

---

## 🏗️ Overall Architecture

```
FlowConnectPuzzle/
├── App Entry
│   ├── FlowConnectPuzzleApp.swift          # @main App
│   └── ContentView.swift                   # Home screen (difficulty selection, daily challenge, settings)
│
├── Models
│   ├── GridCell.swift                      # GridPosition, GridCell, PathSegment
│   ├── Difficulty.swift                    # enum Difficulty: easy/medium/hard/veryHard/expert
│   ├── GameTheme.swift                     # GameTheme struct + ThemeManager (@Observable)
│   └── DailyChallenge.swift                # Daily puzzle seed, completion tracking
│
├── ViewModels
│   └── GameState.swift                     # @Observable class — core game logic + undo tracking
│
├── Services
│   ├── PuzzleGenerator.swift               # Puzzle generation (Warnsdorff + SeededRNG)
│   ├── StatisticsManager.swift             # Best times + solve counts (UserDefaults)
│   ├── AchievementManager.swift            # 10 achievements, unlock logic
│   └── HapticManager.swift                 # Centralized haptic feedback
│
├── Views
│   ├── PuzzleGameView.swift                # Main game UI
│   ├── StatisticsView.swift                # Stats + achievements sheet
│   ├── OnboardingView.swift                # First-launch 4-step tutorial
│   └── AchievementBannerView.swift         # Achievement unlock notification banner
│
└── Documentation
    ├── README.md                           # User-facing documentation
    └── AGENT.md                            # This file (AI assistant guide)
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
    var isHighlighted: Bool = false  // Is number 1? (starting cell)
}
```

### 2. Difficulty Levels

```swift
enum Difficulty: String, CaseIterable, Identifiable {
    case easy     // 5×5 grid,  9 numbers  (~2.7 cells/number)
    case medium   // 6×6 grid, 11 numbers  (~3.2 cells/number)
    case hard     // 7×7 grid, 13 numbers  (~3.7 cells/number)
    case veryHard // 8×8 grid, 15 numbers  (~4.2 cells/number)
    case expert   // 9×9 grid, 17 numbers  (~4.7 cells/number)
}
```

**Design Principles:**
- Grid size is FIXED per difficulty level
- Number count is FIXED (not random) to ensure consistent challenge
- Average path length between consecutive numbers increases with difficulty
- **Backtracking behavior varies by difficulty:**
  - **Easy**: Players can backtrack by dragging to the previous cell
  - **Medium/Hard/Very Hard/Expert**: No backtracking allowed; must use Undo button
- **Undo button**: Always resets to the nearest number (checkpoint behavior) for all difficulties

---

## 🧩 Puzzle Generation Algorithm

### Seeded vs. Random Generation

```swift
// Random game
static func generate(for difficulty: Difficulty) -> PuzzleConfiguration

// Daily Challenge — deterministic, same puzzle for all players on the same day
static func generate(for difficulty: Difficulty, seed: UInt64) -> PuzzleConfiguration
```

**SeededRNG** — Private Xorshift64 struct conforming to `RandomNumberGenerator`:

```swift
private struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed == 0 ? 0xcafef00dd15ea5e5 : seed; _ = next() }
    mutating func next() -> UInt64 {
        state ^= state << 13; state ^= state >> 7; state ^= state << 17; return state
    }
}
```

All internal generator methods are generic over `R: RandomNumberGenerator` and take `rng: inout R`. This ensures both random and seeded generation share the exact same logic path.

### Phase 1: Hamiltonian Path Generation

**Algorithm**: **Warnsdorff's Algorithm** (heuristic backtracking)

```
Warnsdorff's Rule:
  From the current cell, always move to an unvisited cell that has
  the FEWEST unvisited neighbors (lowest degree first).

  If multiple cells have the same degree → pick randomly → creates puzzle variety.
```

**Fallback**: If 100 attempts fail → snake/zigzag pattern (always valid).

### Phase 2: Strategic Number Placement

3-pass optimization to maximize consecutive distance:

- **Pass 1**: Place numbers at evenly-spaced segments along the Hamiltonian path
- **Pass 2**: Within each segment, pick the cell with MAXIMUM Manhattan distance from the previous number
- **Pass 3**: 3 iterations × 15 candidates each — aggressively maximize total consecutive spread

**Result**: Consecutive numbers placed at OPPOSITE ENDS of the grid, forcing long winding paths.

---

## 🗓️ Daily Challenge System

```swift
enum DailyChallenge {
    static var todaySeed: UInt64          // Based on YYYYMMDD integer
    static var todayDifficulty: Difficulty // Rotates through all 5 difficulties by day-of-year
    static var isCompletedToday: Bool     // Persisted in UserDefaults per seed key
    static var formattedDate: String      // Human-readable date string
}
```

**Daily puzzle rules:**
- Same seed → same puzzle for all users on the same day
- Only one attempt — "New Puzzle" button is hidden during daily mode
- After completion, the card shows "Done" badge on the home screen
- Unlocks "Daily Champion" achievement on first completion

---

## 🎮 Game State Management

### GameState (@Observable)

```swift
@Observable
class GameState {
    var grid: [[GridCell]]
    var path: [GridPosition]
    var currentNumber: Int
    var isComplete: Bool          // Deprecated — DO NOT USE
    var allNumbersConnected: Bool // WIN condition
    var usedUndo: Bool            // Whether Undo was used this session (for achievements/stats)

    private(set) var isDaily: Bool
    private(set) var gridSize: Int
    private(set) var maxNumber: Int
    private(set) var numberPositions: [Int: GridPosition]
    private(set) var difficulty: Difficulty

    // Random game
    init(difficulty: Difficulty = .medium)

    // Daily Challenge
    init(dailyDifficulty: Difficulty, seed: UInt64)
}
```

**Key Rules:**
- `usedUndo` is set to `true` in `undo()` and reset on `newGame()` / `reset()`
- `isComplete` is deprecated — always use `allNumbersConnected`
- Win condition: `currentNumber == maxNumber`

---

## 📊 Statistics System

```swift
@Observable
class StatisticsManager {
    static let shared = StatisticsManager()

    func bestTime(for difficulty: Difficulty) -> TimeInterval?     // nil if never completed
    func solveCount(for difficulty: Difficulty) -> Int
    func noUndoCount(for difficulty: Difficulty) -> Int
    var totalSolveCount: Int

    @discardableResult
    func recordCompletion(difficulty:, time:, usedUndo:) -> Bool   // Returns true if new personal best
}
```

**Storage**: UserDefaults keys: `bestTime_{difficulty}`, `solveCount_{difficulty}`, `noUndoCount_{difficulty}`

---

## 🏆 Achievement System

### Achievement Definitions

| ID | Title | Condition |
|----|-------|-----------|
| `first_solve` | First Step | Solve first puzzle (any difficulty) |
| `speed_easy` | Speed Demon | Easy in under 60 seconds |
| `speed_medium` | Lightning | Medium in under 2 minutes |
| `speed_hard` | Blazing | Hard in under 5 minutes |
| `purist` | Purist | Any puzzle without using Undo |
| `iron_will` | Iron Will | Hard/Very Hard/Expert without Undo |
| `collector` | Collector | 10 total puzzles solved |
| `veteran` | Veteran | 50 total puzzles solved |
| `expert_solver` | Expert | Complete Expert difficulty |
| `daily_champion` | Daily Champion | Complete the Daily Challenge |

```swift
@Observable
class AchievementManager {
    static let shared = AchievementManager()
    var recentlyUnlocked: Achievement?  // Observed by PuzzleGameView to show banner

    func check(difficulty:, time:, usedUndo:, isDaily:)  // Call AFTER recordCompletion
    func isUnlocked(_ achievement: Achievement) -> Bool
    func clearRecentlyUnlocked()
}
```

**Achievement unlock flow** (called in `PuzzleGameView.handleCompletion()`):
1. `StatisticsManager.shared.recordCompletion(...)` → updates counts + best time
2. `AchievementManager.shared.check(...)` → reads updated stats, unlocks achievements
3. If daily: `DailyChallenge.isCompletedToday = true`
4. `AchievementManager.recentlyUnlocked` changes → banner appears for 4 seconds

---

## 🎨 Theme System

```swift
struct GameTheme: Identifiable, Equatable {
    let id: String
    let name: String
    let pathColor: Color           // Path line + selected cells
    let cellHighlightColor: Color  // Starting cell (number 1)
    let completedColor: Color      // Path after winning
    let accentColor: Color         // Hint glow / LED comet ring
}
```

**Available themes:**

| ID | Name | Path Color | Completed |
|----|------|-----------|-----------|
| `ocean` | Ocean | Blue | Green |
| `sunset` | Sunset | Orange | Red-Orange |
| `forest` | Forest | Green | Mint |
| `cosmos` | Cosmos | Purple | Pink |

```swift
@Observable
class ThemeManager {
    static let shared = ThemeManager()
    var current: GameTheme  // Persisted in UserDefaults under key "selected_theme_id"
}
```

**Usage in views**: Always read `ThemeManager.shared.current` — never hardcode `.blue` for game colors.

---

## 🎮 UI/UX Design

### ContentView Structure

```
VStack {
    Top Bar
    ├─ "Flow Connect" title (left)
    ├─ Stats button → StatisticsView sheet (right)
    └─ Settings button → Settings sheet (right)

    ScrollView
    ├─ Daily Challenge Card
    │   ├─ Calendar icon
    │   ├─ Date + today's difficulty description
    │   └─ "Done" badge if completed today
    │
    └─ Difficulty List (ForEach Difficulty.allCases)
        └─ Each row: icon, name, description, personal best time, chevron
}

Sheets:
├─ StatisticsView  — best times, solve counts, achievements grid
└─ Settings Sheet  — theme picker, replay onboarding

Full Screen Overlay (on first launch):
└─ OnboardingView  — 4-step tutorial
```

### PuzzleGameView Structure

```
VStack {
    Header Row
    ├─ Back button (left)
    ├─ Difficulty name or "Daily Challenge" label (with calendar icon) (center-left)
    └─ Timer (right) — Clock icon + elapsed time (MM:SS.CS format)

    Puzzle Grid (DragGesture)
    │
    ├─ ForEach row/col
    │   └─ Rectangle cell (theme-colored background)
    │
    ├─ Canvas overlay (path lines, theme-colored)
    │
    └─ Number badges overlay
        ├─ Black circle with white number
        └─ Hint: LED comet ring + breathing glow (accent color)

    Action Buttons Row
    ├─ Undo (adds +3 second time penalty) — disabled when path is empty
    ├─ Reset (replay same puzzle, timer continues)
    ├─ Hint (breathing glow on next number)
    └─ New (regenerate + reset timer) — HIDDEN during daily mode

    Achievement Banner (top overlay, auto-dismisses after 4 seconds)

    Completion Overlay (if allNumbersConnected)
    ├─ "Puzzle Complete!" or "Daily Complete!" title
    ├─ Completion time badge
    ├─ "New Personal Best!" badge (if isPersonalBest == true)
    └─ "Next Puzzle" button (or "Back to Menu" for daily)
}
```

---

## ⏱️ Timer System

- Starts automatically when puzzle loads
- Stops when `allNumbersConnected` becomes `true`
- **Penalties & Resets:**

| Button | Timer Behavior | Rationale |
|--------|---------------|-----------|
| **Undo** | +3 seconds penalty | Discourages excessive undo |
| **Reset** | Timer continues | Penalty for resetting |
| **New** | Reset to 0:00.00 | Fresh puzzle = fresh time |
| **Next Puzzle** | Reset to 0:00.00 | Fresh puzzle after win |

- **Display format**: `M:SS.CS` (e.g., `1:23.45` = 1 min 23.45 sec)
- Update frequency: every 10ms for centisecond precision

---

## 🔊 Haptic Feedback System

All haptics go through `HapticManager.shared`. Never call UIKit haptic generators directly.

| Action | Method | Feel |
|--------|--------|------|
| Drag through empty cell | `pathAdded()` | Light tick |
| Reach next number | `numberReached()` | Medium bump |
| Invalid move | `invalidMove()` | Error buzz |
| Backtrack / undo | `undo()` | Soft click |
| Reset game | `reset()` | Medium bump |
| Win | `completed()` | Heavy → Success → Medium (triple sequence) |

---

## 🎓 Onboarding System

`OnboardingView` is shown on first launch (checked via `UserDefaults.bool(forKey: "onboarding_done")`).

- 4-step animated tutorial covering: connect numbers, draw path, fill grid, use tools
- "Skip" button exits at any step
- "Let's Play!" on final step marks onboarding complete
- Can be replayed from Settings → "Show Onboarding Again"

---

## 🧪 Testing Strategy

### Key Test Cases

**1. Puzzle Generation:**
- [ ] Warnsdorff's algorithm creates valid Hamiltonian path
- [ ] Seeded generation produces identical output for same seed
- [ ] Daily seed is consistent within the same calendar day
- [ ] Fallback snake pattern always works
- [ ] All 5 difficulty levels generate correct grid sizes

**2. Game Logic:**
- [ ] Cannot start from non-1 cell
- [ ] Can only move to adjacent cells (4-directional)
- [ ] Must connect numbers in sequence (1→2→3...)
- [ ] **Easy**: Backtrack by dragging to second-to-last cell works
- [ ] **Medium/Hard/Very Hard/Expert**: No backtracking by dragging
- [ ] **Undo button**: `usedUndo` set to true after first use
- [ ] Win condition triggers when `currentNumber == maxNumber`

**3. Statistics:**
- [ ] `recordCompletion` returns `true` only when new best is set
- [ ] `totalSolveCount` sums across all difficulties
- [ ] Best time is not overwritten if time is worse

**4. Achievements:**
- [ ] Each achievement unlocks exactly once (idempotent)
- [ ] `recentlyUnlocked` is nil after `clearRecentlyUnlocked()`
- [ ] `check()` must be called AFTER `recordCompletion()` for count-based achievements

---

## 🚀 Performance Considerations

1. **Grid Rendering** — `GeometryReader` calculates cell size once; SwiftUI auto-caches views
2. **Path Drawing** — Canvas API redraws only when `path` changes
3. **Haptics** — All generators pre-prepared in `HapticManager.init()`
4. **Puzzle Generation** — O(N) Warnsdorff + O(K×15) placement = very fast on all grid sizes
5. **Seeded RNG** — Xorshift64 is extremely fast; no performance difference vs. system RNG

---

## 🐛 Known Issues & Limitations

1. **No full undo history** — Undo steps back one checkpoint (number) at a time, not cell-by-cell
2. **No solution validator** — Assumes all generated puzzles are solvable (they are, by construction)
3. **No game persistence** — Closing the app mid-game loses current progress
4. **Daily challenge: one attempt only** — No way to retry a failed daily puzzle

---

## 📝 Code Style Guidelines

### SwiftUI Best Practices

```swift
// ✅ GOOD: @Observable macro
@Observable class GameState { var grid: [[GridCell]] }

// ❌ BAD: Legacy @ObservableObject
class GameState: ObservableObject { @Published var grid: [[GridCell]] }
```

### Naming Conventions

- **Properties**: camelCase (`gridSize`, `usedUndo`, `allNumbersConnected`)
- **Functions**: camelCase verbs (`addToPath`, `checkCompletion`, `recordCompletion`)
- **Types**: PascalCase (`GridPosition`, `GameTheme`, `Achievement`)
- **Singletons**: `.shared` static property on `@Observable` classes

### Critical Rules

- `isComplete` is deprecated — use `allNumbersConnected`
- Never use hardcoded colors (`.blue`, `.green`) for game elements — read from `ThemeManager.shared.current`
- All haptic calls go through `HapticManager.shared`
- `AchievementManager.check()` MUST be called after `StatisticsManager.recordCompletion()` — achievements read updated stats

---

## 🔗 File Dependencies Map

```
ContentView.swift
  ├─→ DailyChallenge.swift
  ├─→ StatisticsManager.swift
  ├─→ AchievementManager.swift
  ├─→ ThemeManager (GameTheme.swift)
  ├─→ OnboardingView.swift
  ├─→ StatisticsView.swift
  └─→ PuzzleGameView.swift
        ├─→ GameState.swift
        │     ├─→ GridCell.swift
        │     ├─→ PuzzleGenerator.swift (SeededRNG + Warnsdorff)
        │     │     └─→ Difficulty.swift
        │     └─→ HapticManager.swift
        ├─→ StatisticsManager.swift
        ├─→ AchievementManager.swift
        ├─→ ThemeManager (GameTheme.swift)
        ├─→ DailyChallenge.swift
        └─→ AchievementBannerView.swift
```

---

## 💡 AI Assistant Tips

### When asked about bugs:
1. **Check GameState.swift first** — source of most logic errors
2. **Check `allNumbersConnected` vs `isComplete`** — only use `allNumbersConnected`
3. **Check `usedUndo` reset** — must be false after `newGame()` and `reset()`

### When asked to add features:
1. **Use `@Observable`** — never `@ObservableObject`
2. **Use theme colors** — read `ThemeManager.shared.current.pathColor` etc., don't hardcode
3. **Thread haptics** — every user action needs feedback via `HapticManager.shared`
4. **Statistics integration** — new game modes must call `StatisticsManager.shared.recordCompletion()`

### When working with Daily Challenge:
1. Daily seed = `UInt64(year * 10000 + month * 100 + day)`
2. Difficulty rotates by `dayOfYear % 5`
3. Completion is stored per-seed in UserDefaults (`"daily_done_{seed}"`)
4. `isDaily = true` in `GameState` disables the "New Puzzle" button in the view

---

## 📚 Reference Documentation

### Key Algorithms
- **Warnsdorff's Algorithm**: [Wikipedia](https://en.wikipedia.org/wiki/Knight%27s_tour#Warnsdorff's_rule)
- **Xorshift RNG**: [Wikipedia](https://en.wikipedia.org/wiki/Xorshift)
- **Manhattan Distance**: Taxicab geometry metric

### SwiftUI APIs Used
- `@Observable` macro (iOS 17+)
- `GeometryReader`
- `Canvas` (path drawing)
- `DragGesture`
- `.onReceive(timer)` for animations and game timer
- `.sheet()` for Stats and Settings
- `.overlay(alignment:)` for achievement banner

### UIKit Haptics
- `UIImpactFeedbackGenerator`
- `UINotificationFeedbackGenerator`
- `UISelectionFeedbackGenerator`

---

## ✅ Quick Checklist for AI Assistant

When working with this codebase, remember:

- [ ] Win condition is `allNumbersConnected` (NOT `isComplete`)
- [ ] `usedUndo` is `true` after first Undo, reset on `newGame()` / `reset()`
- [ ] **Easy**: Allows drag-backtracking to previous cell
- [ ] **Medium/Hard/Very Hard/Expert**: No drag-backtracking — Undo button only
- [ ] Undo removes path back to (and including) last number checkpoint
- [ ] `AchievementManager.check()` must be called AFTER `StatisticsManager.recordCompletion()`
- [ ] Never hardcode game colors — always use `ThemeManager.shared.current`
- [ ] All haptics through `HapticManager.shared`
- [ ] Grid coordinates: row (vertical) × col (horizontal)
- [ ] Adjacency: only 4-directional (no diagonal)
- [ ] Seeded generation: pass `seed: UInt64` to `PuzzleGenerator.generate(for:seed:)`
- [ ] Daily mode hides "New Puzzle" button and shows "Back to Menu" on completion

---

**Last Updated**: 2026-04-26
**Version**: 3.0
**Changelog**:
- v3.0 (2026-04-26): Major feature expansion
  - Added **Statistics System** (`StatisticsManager`) — best times, solve counts per difficulty
  - Added **Achievement System** (`AchievementManager`) — 10 unlockable achievements
  - Added **Theme System** (`GameTheme`, `ThemeManager`) — 4 color themes (Ocean, Sunset, Forest, Cosmos)
  - Added **Daily Challenge** (`DailyChallenge`) — date-seeded, one-per-day puzzle
  - Added **Onboarding** (`OnboardingView`) — 4-step first-launch tutorial
  - Added **Statistics View** (`StatisticsView`) — best times, solve counts, achievement progress
  - Added **Achievement Banner** (`AchievementBannerView`) — animated unlock notification
  - Updated `PuzzleGenerator` — `SeededRNG` (Xorshift64) + generic `rng: inout R` methods
  - Updated `GameState` — `usedUndo` tracking, daily game init, correct resets
  - Updated `ContentView` — daily card, best times display, stats/settings buttons
  - Updated `PuzzleGameView` — themes, personal best badge, achievement banner, accessibility labels, daily mode UI
- v2.1 (2026-04-19): Updated timer penalty system
- v2.0 (2026-04-19): Added Very Hard (8×8) and Expert (9×9) difficulty levels
- v1.1 (2026-04-19): Added millisecond precision timer
- v1.0 (2026-04-19): Initial documentation

**Maintained by**: AI Assistant + Development Team
