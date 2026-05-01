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

- **Platform**: iOS/iPadOS (iOS 17+)
- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI
- **State Management**: `@Observable` macro (Swift 5.9+)
- **Haptics**: UIKit's UIFeedbackGenerator (via `HapticManager`)
- **Sound**: AudioToolbox `AudioServicesPlaySystemSound` (via `SoundManager`)
- **Persistence**: UserDefaults (all managers use stored property + `didSet` pattern)
- **Notifications**: `UNUserNotificationCenter` (via `NotificationManager`)
- **Game Center**: `GameKit` `GKLeaderboard.submitScore` (via `GameCenterManager`)
- **Architecture**: MVVM-like with `@Observable` singletons for cross-cutting concerns

---

## 🏗️ Overall Architecture

```
FlowConnectPuzzle/
├── App Entry
│   ├── FlowConnectPuzzleApp.swift          # @main App — requests notifications + authenticates Game Center on launch
│   └── ContentView.swift                   # Home screen — GameMode-based navigation
│
├── Models
│   ├── GridCell.swift                      # GridPosition, GridCell, PathSegment
│   ├── Difficulty.swift                    # enum Difficulty: easy/medium/hard/veryHard/expert
│   ├── GameTheme.swift                     # GameTheme struct + ThemeManager (@Observable)
│   ├── DailyChallenge.swift                # Daily puzzle seed, completion tracking
│   ├── GameMode.swift                      # enum GameMode: normal/daily/weekly/zen/timeTrial/challenge
│   ├── WeeklyChallenge.swift               # ISO week-based seed, expert difficulty, completion tracking
│   ├── AppColorScheme.swift                # AppColorSchemeProtocol + LightAppColorScheme + DarkAppColorScheme
│   └── AppearanceMode.swift                # enum AppearanceMode (.light/.dark/.system) + AppearanceManager singleton
│
├── ViewModels
│   └── GameState.swift                     # @Observable class — core game logic + undo tracking
│
├── Services
│   ├── PuzzleGenerator.swift               # Puzzle generation (Warnsdorff + SeededRNG)
│   ├── StatisticsManager.swift             # Best times + solve counts (UserDefaults)
│   ├── AchievementManager.swift            # 25 achievements, unlock logic
│   ├── HapticManager.swift                 # Centralized haptic feedback
│   ├── StreakManager.swift                 # Daily streak tracking + completion history
│   ├── NotificationManager.swift           # Local push notifications (8am + 8pm reminders)
│   ├── ProgressionManager.swift            # XP + level system (10 levels, Novice → Champion)
│   ├── SoundManager.swift                  # Sound effects via AudioToolbox
│   ├── GameCenterManager.swift             # Game Center auth + leaderboard submission
│   └── LocalizationManager.swift          # @Observable singleton, loads .strings files at runtime
│
├── Localizations
│   ├── en.strings                          # English (required — fallback for all languages)
│   ├── vi.strings                          # Tiếng Việt
│   ├── es.strings                          # Español
│   ├── fr.strings                          # Français
│   ├── de.strings                          # Deutsch
│   ├── ja.strings                          # 日本語
│   ├── zh_Hans.strings                     # 简体中文
│   ├── pt.strings                          # Português
│   └── ko.strings                          # 한국어
│
├── Views
│   ├── PuzzleGameView.swift                # Main game UI — accepts GameMode, handles all modes
│   ├── StatisticsView.swift                # Stats + achievements + progression + streak calendar
│   ├── OnboardingView.swift                # First-launch 4-step tutorial
│   ├── AchievementBannerView.swift         # Achievement unlock notification banner
│   ├── StreakCalendarView.swift            # GitHub-style 13-week heatmap of daily completions
│   ├── TimeTrialView.swift                 # 3-minute countdown mode, escalating difficulty
│   ├── ChallengeFriendView.swift           # Generate/share/enter challenge codes
│   ├── AppAlertView.swift                  # Reusable custom alert popup + .appAlert() ViewModifier
│   └── ToastModifier.swift                 # Reusable toast notification ViewModifier
│
└── Documentation
    ├── README.md                           # User-facing documentation
    └── AGENT.md                            # This file (AI assistant guide)
```

---

## 🌗 Appearance Mode System

Separate from the game color *theme* (ocean/sunset/forest/cosmos), the **appearance mode** controls whether the app renders in Light, Dark, or System mode — mirroring iOS's native behavior.

### Protocol and Concrete Schemes

```swift
protocol AppColorSchemeProtocol {
    // Backgrounds
    var pageBackground: Color { get }
    var groupedBackground: Color { get }
    var surface: Color { get }
    var elevatedSurface: Color { get }
    // Text
    var primaryText: Color { get }
    var secondaryText: Color { get }
    var tertiaryText: Color { get }
    // UI Elements
    var separator: Color { get }
    var destructive: Color { get }
    // Typography
    var titleFont: Font { get }
    var headlineFont: Font { get }
    var bodyFont: Font { get }
    var subheadlineFont: Font { get }
    var captionFont: Font { get }
}
```

**`LightAppColorScheme`** uses `#F2F2F7` page background (Apple `systemGroupedBackground` light).

**`DarkAppColorScheme`** uses exact Apple UIColor dark mode values:

| Property | UIColor name | Hex |
|----------|-------------|-----|
| `pageBackground` | systemGroupedBackground | `#1C1C1E` |
| `groupedBackground` | secondarySystemGroupedBackground | `#2C2C2E` |
| `surface` | secondarySystemBackground | `#2C2C2E` |
| `elevatedSurface` | tertiarySystemBackground | `#3A3A3C` |
| `primaryText` | label | `#FFFFFF` |
| `secondaryText` | secondaryLabel | `#8E8E93` |
| `tertiaryText` | tertiaryLabel | `#48484A` |
| `separator` | opaqueSeparator | `#38383A` |
| `destructive` | systemRed | `#FF453A` |

### AppearanceManager

```swift
enum AppearanceMode: String, CaseIterable, Identifiable {
    case light, dark, system
    var preferredColorScheme: ColorScheme? // .light / .dark / nil (system)
    var iconName: String       // SF Symbol for picker UI
    var localizationKey: String // settings.appearance_{case}
}

@Observable class AppearanceManager {
    static let shared = AppearanceManager()
    var mode: AppearanceMode { didSet { UserDefaults.standard.set(mode.rawValue, forKey: "appearance_mode") } }
    var preferredColorScheme: ColorScheme? { mode.preferredColorScheme }
    let lightScheme: any AppColorSchemeProtocol = LightAppColorScheme()
    let darkScheme: any AppColorSchemeProtocol = DarkAppColorScheme()
}
```

**Critical rule**: `mode` is a **stored property** with `didSet` (not a computed property) so `@Observable` tracks changes and triggers SwiftUI re-renders.

### Applying the Preference

```swift
// ContentView.swift — root Group
Group { ... }
    .preferredColorScheme(appearanceManager.preferredColorScheme)

// Settings sheet — NavigationStack (sheets don't inherit from parent!)
NavigationStack { ... }
    .tint(themeManager.current.pathColor)
    .preferredColorScheme(appearanceManager.preferredColorScheme)
```

**Sheet inheritance caveat**: `.sheet()` creates a new `UIViewController` presentation context and does **not** automatically inherit `.preferredColorScheme` from the SwiftUI parent hierarchy. Apply `.preferredColorScheme` directly to the root view inside the sheet (here: the `NavigationStack`).

### Localization Keys Added

```
"settings.appearance"        // "Appearance" / "Chế độ hiển thị" / ...
"settings.appearance_light"  // "Light" / "Sáng" / ...
"settings.appearance_dark"   // "Dark" / "Tối" / ...
"settings.appearance_system" // "System" / "Theo hệ thống" / ...
```

Present in all 9 `.strings` files: `en`, `vi`, `es`, `fr`, `de`, `ja`, `zh_Hans`, `pt`, `ko`.

---

## 🎮 Game Modes

The `GameMode` enum is the single source of truth for which mode is active. `PuzzleGameView` accepts `mode: GameMode` instead of separate boolean flags.

```swift
enum GameMode: Equatable {
    case normal(Difficulty)          // Standard timed puzzle
    case daily                       // Daily challenge — date-seeded, one per day
    case weekly                      // Weekly challenge — ISO week-seeded, always Expert
    case zen(Difficulty)             // No timer display, no time penalties, no personal best
    case timeTrial                   // Separate view (TimeTrialView) — 3-min countdown
    case challenge(Difficulty, UInt64) // Friend challenge — seeded puzzle shared via code

    var difficulty: Difficulty  // Derived difficulty for this mode
    var isSeeded: Bool          // true for daily/weekly/challenge
    var seed: UInt64?           // Seed value for seeded modes
    var isZen: Bool             // true for zen(_)
    var displayTitle: String    // Localized title via LocalizationManager.shared
}
```

**Key behavioral differences by mode:**

| Mode | Timer | Undo Penalty | Personal Best | New Puzzle Button |
|------|-------|-------------|---------------|-------------------|
| `normal` | Counts up | +2 sec | Yes | Shown |
| `daily` | Counts up | +2 sec | Yes | Hidden |
| `weekly` | Counts up | +2 sec | Yes | Hidden |
| `zen` | Hidden (leaf icon) | None (skipped) | No | Shown |
| `timeTrial` | Counts down (3 min) | N/A (auto-advance) | N/A | N/A |
| `challenge` | Counts up | +2 sec | Yes | Shown |

**Computed shorthands in `PuzzleGameView`** (so internal code stays readable):
```swift
private var difficulty: Difficulty { mode.difficulty }
private var isDaily: Bool { mode == .daily }
private var isWeekly: Bool { mode == .weekly }
private var isZen: Bool { mode.isZen }
```

---

## 🗓️ Daily Challenge System

```swift
enum DailyChallenge {
    static var todaySeed: UInt64          // UInt64(year * 10000 + month * 100 + day)
    static var todayDifficulty: Difficulty // Rotates through all 5 difficulties by dayOfYear % 5
    static var isCompletedToday: Bool     // Persisted in UserDefaults per seed key ("daily_done_{seed}")
    static var formattedDate: String      // Human-readable date string
}
```

**Daily puzzle rules:**
- Same seed → same puzzle for all users on the same day
- Only one attempt — "New Puzzle" button is hidden during daily mode
- After completion, the card shows "Done" badge on the home screen
- +50 XP bonus on top of base XP
- Recorded in `StreakManager` for streak tracking

---

## 📅 Weekly Challenge System

```swift
@Observable
class WeeklyChallenge {
    // ISO week-based seed: UInt64(year * 1000 + week)
    // Always .expert difficulty
    // Completion stored per seed in UserDefaults

    var isCompletedThisWeek: Bool   // Persisted
    var currentSeed: UInt64         // Computed from current ISO week
    var formattedDateRange: String  // "Mon Apr 28 – Sun May 4"
}
```

**Weekly puzzle rules:**
- Always Expert (9×9, 17 numbers) difficulty — hardest possible
- One per ISO calendar week
- +200 XP bonus on top of base (Expert: 100 XP base + 200 weekly = 300 XP)
- "Weekly Champion" achievement on first completion

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

// Seeded (Daily / Weekly / Challenge) — deterministic, same puzzle for same seed
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

## 🎮 Game State Management

### GameState (@Observable)

```swift
@Observable
class GameState {
    var grid: [[GridCell]]
    var path: [GridPosition]
    var currentNumber: Int
    var allNumbersConnected: Bool // WIN condition
    var usedUndo: Bool            // Whether Undo was used this session (for achievements/stats)

    private(set) var gridSize: Int
    private(set) var maxNumber: Int
    private(set) var numberPositions: [Int: GridPosition]
    private(set) var difficulty: Difficulty

    // Random game
    init(difficulty: Difficulty = .medium)

    // Seeded game (Daily, Weekly, Challenge)
    init(dailyDifficulty: Difficulty, seed: UInt64)
}
```

**Key Rules:**
- `usedUndo` is set to `true` in `undo()` and reset on `newGame()` / `reset()`
- Win condition: `currentNumber == maxNumber` → sets `allNumbersConnected = true`

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

## 🔥 Streak System

```swift
@Observable
class StreakManager {
    static let shared = StreakManager()

    var currentStreak: Int         // Consecutive days with a daily completion (persisted)
    var bestStreak: Int            // All-time best streak (persisted)
    var totalDailySolves: Int      // Total daily challenges completed (persisted)
    var completionDates: Set<String> // "yyyy-MM-dd" strings of completed days (persisted)

    func recordDailyCompletion()   // Idempotent — safe to call multiple times per day
    func hasCompleted(on date: Date) -> Bool
}
```

**Streak logic**: `recordDailyCompletion()` checks if yesterday's date key is in `completionDates`. If yes → increment streak. If no → reset to 1. The method is idempotent so duplicate calls on the same day are safe.

**CRITICAL ORDER**: `StreakManager.recordDailyCompletion()` must be called BEFORE `AchievementManager.check()` so streak-based achievements (`streak_14`) see the updated streak value.

---

## ⭐ XP & Level System

```swift
@Observable
class ProgressionManager {
    static let shared = ProgressionManager()

    var totalXP: Int            // Persisted — stored property + didSet
    var level: Int              // Computed from totalXP
    var levelName: String       // "Novice", "Apprentice", ... "Champion"
    var progressInCurrentLevel: Double  // 0.0–1.0 progress bar value

    func recordCompletion(difficulty:, isPersonalBest:, usedUndo:, isDaily:, isWeekly:)
    static func baseXP(for difficulty: Difficulty) -> Int
}
```

**XP values:**

| Difficulty | Base XP |
|-----------|---------|
| Easy | 10 |
| Medium | 20 |
| Hard | 40 |
| Very Hard | 60 |
| Expert | 100 |

**XP bonuses:**
- Personal Best: +25
- No Undo used: +10
- Daily mode: +50
- Weekly mode: +200

**Level thresholds (cumulative XP):**

| Level | Name | XP Required |
|-------|------|-------------|
| 1 | Novice | 0 |
| 2 | Apprentice | 100 |
| 3 | Solver | 250 |
| 4 | Thinker | 500 |
| 5 | Explorer | 1,000 |
| 6 | Tactician | 2,000 |
| 7 | Strategist | 4,000 |
| 8 | Master | 7,500 |
| 9 | Grandmaster | 12,500 |
| 10 | Champion | 20,000 |

---

## 🏆 Achievement System

### Achievement Definitions (25 total)

| ID | Title | Condition |
|----|-------|-----------|
| `first_solve` | First Steps | Solve 1 puzzle |
| `solve_10` | Getting Started | Solve 10 puzzles |
| `solve_50` | Puzzle Enthusiast | Solve 50 puzzles |
| `solve_100` | Century Solver | Solve 100 puzzles |
| `solve_500` | Puzzle Master | Solve 500 puzzles |
| `easy_master` | Easy Master | Solve 20 Easy puzzles |
| `medium_master` | Medium Master | Solve 15 Medium puzzles |
| `hard_master` | Hard Conqueror | Solve 10 Hard puzzles |
| `very_hard_master` | Extreme Solver | Solve 5 Very Hard puzzles |
| `expert_master` | Expert Elite | Complete any Expert puzzle |
| `speed_demon` | Speed Demon | Solve Easy in under 10 seconds |
| `lightning` | Lightning Fast | Solve Medium in under 20 seconds |
| `streak_3` | Hat Trick | 3-day daily streak |
| `streak_7` | Week Warrior | 7-day daily streak |
| `streak_30` | Monthly Devotion | 30-day daily streak |
| `streak_100` | Centurion | 100-day daily streak |
| `daily_7` | Daily Devotee | Complete 7 daily challenges |
| `daily_30` | Monthly Regular | Complete 30 daily challenges |
| `timetrial_bronze` | Time Trial Bronze | Score 100+ in Time Trial |
| `timetrial_silver` | Time Trial Silver | Score 300+ in Time Trial |
| `timetrial_gold` | Time Trial Gold | Score 500+ in Time Trial |
| `level_5` | Rising Star | Reach Level 5 |
| `level_10` | Veteran | Reach Level 10 |
| `level_20` | Legend | Reach Level 20 |
| `perfectionist` | Perfectionist | Complete Hard+ without backtracking |

```swift
@Observable
class AchievementManager {
    static let shared = AchievementManager()
    var recentlyUnlocked: Achievement?  // Observed by PuzzleGameView to show banner

    // Call AFTER StatisticsManager.recordCompletion() and ProgressionManager.recordCompletion()
    func check(difficulty:, time:, usedUndo:, isDaily:, isWeekly: Bool = false, isZen: Bool = false)
    func checkTimeTrial(score: Int)   // Called from TimeTrialView when time expires
    func isUnlocked(_ achievement: Achievement) -> Bool
    func clearRecentlyUnlocked()
}
```

### Completion Flow in `PuzzleGameView.handleCompletion()`

**Critical ordering — must follow this exact sequence:**

```
1. StatisticsManager.shared.recordCompletion(...)       → updates best times + solve counts
2. StreakManager.shared.recordDailyCompletion()         → (daily/weekly only) updates streak
3. WeeklyChallenge.shared.isCompletedThisWeek = true    → (weekly only)
4. ProgressionManager.shared.recordCompletion(...)      → awards XP, updates level
5. GameCenterManager.shared.submitBestTime(...)         → syncs to leaderboard
6. AchievementManager.shared.check(...)                 → reads all updated state, unlocks achievements
```

**Why this order matters:**
- `AchievementManager.check()` reads `StreakManager.currentStreak` for `streak_14`
- `AchievementManager.check()` reads `ProgressionManager.level` for `level_5`/`level_10`
- If `check()` runs before these are updated, achievements won't unlock correctly

---

## 🌐 Localization System

All user-visible strings are externalized into `.strings` files loaded at runtime by `LocalizationManager`. Language switches take effect **immediately** without restart.

### Supported Languages

| Code | Language | File |
|------|----------|------|
| `en` | English | `Localizations/en.strings` |
| `vi` | Tiếng Việt | `Localizations/vi.strings` |
| `es` | Español | `Localizations/es.strings` |
| `fr` | Français | `Localizations/fr.strings` |
| `de` | Deutsch | `Localizations/de.strings` |
| `ja` | 日本語 | `Localizations/ja.strings` |
| `zh-Hans` | 简体中文 | `Localizations/zh_Hans.strings` (hyphen → underscore) |
| `pt` | Português | `Localizations/pt.strings` |
| `ko` | 한국어 | `Localizations/ko.strings` |

### LocalizationManager

```swift
@Observable
class LocalizationManager {
    static let shared = LocalizationManager()

    var language: AppLanguage {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: "selected_language")
            loadStrings(for: language)   // triggers @Observable re-render in all views
        }
    }

    func t(_ key: String) -> String          // primary lookup with English fallback
    func difficultyName(_ difficulty: Difficulty) -> String  // "difficulty.{rawValue}"
    func achievementTitle(_ id: String) -> String           // "achievement.{id}.title"
    func achievementDesc(_ id: String) -> String            // "achievement.{id}.desc"
    func streakText(_ count: Int) -> String  // handles singular/plural
    func daysText(_ count: Int) -> String    // handles singular/plural
}
```

**Fallback chain**: `currentLanguageStrings[key] ?? englishStrings[key] ?? key`

English is always loaded first; other languages are merged on top, so any missing translation gracefully falls back to English rather than showing a raw key.

**How to use in views:**
```swift
@State private var lm = LocalizationManager.shared

// Simple string
Text(lm.t("settings.title"))

// Format string
Text(String(format: lm.t("stats.level"), level, levelName))

// Difficulty name
Text(lm.difficultyName(difficulty))
```

**CJK word-order format specifiers**: Japanese, Korean, and Chinese use positional specifiers (`%1$d`, `%2$@`) to handle different word order:
```
// English: "200 XP to Master"
"stats.xp_to_next" = "%d XP to %@";
// Japanese: "Masterまで200 XP"
"stats.xp_to_next" = "%2$@まで%1$d XP";
```

**Adding a new string**: Add the key to `en.strings` first (required for fallback), then add translations to the other 8 files. The key itself is displayed if it's missing from English.

**Common keys** (available in all 9 languages — use for shared UI):
- `common.cancel` — "Cancel" / "Hủy" / "Cancelar" / "Annuler" / "Abbrechen" / "キャンセル" / "取消" / "Cancelar" / "취소"

**Adding a new language**: Add a case to `AppLanguage` enum in `LocalizationManager.swift`, create `Localizations/{code}.strings`, and it will appear in the Settings language picker automatically.

### File Location

All `.strings` files are in the `Localizations/` group in the Xcode project navigator (under `FlowConnectPuzzle/Localizations/`). They are loaded at runtime via `Bundle.main.path(forResource:ofType:)` — no `.lproj` folder structure required.

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

    // IMPORTANT: stored property + didSet — NOT a computed property.
    // @Observable only tracks stored properties; computed properties do NOT
    // trigger SwiftUI re-renders when changed.
    var current: GameTheme {
        didSet { UserDefaults.standard.set(current.id, forKey: "selected_theme_id") }
    }
}
```

**Critical rule**: `current` MUST remain a **stored property** with `didSet`. Using a computed property (custom getter/setter) breaks `@Observable` tracking — the UI will not update when the theme changes.

**Usage in views**: Always read `ThemeManager.shared.current` — never hardcode `.blue` for game colors.

---

## 🔔 Notification System

```swift
@Observable
class NotificationManager {
    static let shared = NotificationManager()

    var isEnabled: Bool {   // Stored property + didSet — schedules/cancels on change
        didSet { isEnabled ? scheduleReminders() : cancelAllReminders() }
    }

    func requestPermission() async  // Shows system dialog, sets isEnabled = granted
}
```

**Scheduled reminders (when enabled):**
- **8:00 AM daily**: "Daily Challenge Ready! 🧩"
- **8:00 PM daily**: "Don't break your streak! 🔥"

Permission is requested in `FlowConnectPuzzleApp.swift` `.task {}` block (only after onboarding is complete).

---

## 🎵 Sound System

```swift
@Observable
class SoundManager {
    static let shared = SoundManager()

    var isEnabled: Bool { didSet { UserDefaults.standard.set(isEnabled, forKey: "sound_enabled") } }

    func playStep()      // Cell added to path — subtle tick
    func playComplete()  // Puzzle solved — success chime
    func playUndo()      // Undo action — soft pop
    func playTap()       // Button tap — light click
    func playError()     // Invalid move — error buzz
}
```

Uses `AudioToolbox.AudioServicesPlaySystemSound` with system sound IDs. `playStep()` is called in `PuzzleGameView.handleDrag()` on each new cell; `playComplete()` in `handleCompletion()`.

---

## 🏅 Game Center

```swift
@Observable
class GameCenterManager {
    static let shared = GameCenterManager()

    var isAuthenticated: Bool

    func authenticate()               // Called on app launch via FlowConnectPuzzleApp
    func submitBestTime(_ time: TimeInterval, for difficulty: Difficulty)
    func submitXP(_ xp: Int)
    func submitPendingScores()        // Called after successful auth to sync all existing bests

    enum Leaderboard: String {
        // One leaderboard ID per difficulty (best time in milliseconds) + one for total XP
    }
}
```

`submitBestTime` is called from `handleCompletion()` only when `isPersonalBest == true`. Times are submitted as milliseconds (Int).

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
    ├─ Daily Challenge Card        → mode: .daily
    ├─ Weekly Challenge Card       → mode: .weekly (purple, crown icon, "+200 XP bonus")
    │
    ├─ "Other Modes" section
    │   ├─ Time Trial button       → TimeTrialView sheet
    │   └─ Zen Mode Menu picker    → mode: .zen(selectedDifficulty)
    │
    └─ Difficulty List (ForEach Difficulty.allCases)
        └─ Each row → mode: .normal(difficulty)
}

Sheets:
├─ StatisticsView     — progression, streak calendar, best times, achievements
├─ Settings Sheet     — appearance picker (Light/Dark/System), theme picker, language, sound, notifications, challenge friend, onboarding replay, data reset
├─ TimeTrialView      — 3-minute countdown mode
└─ ChallengeFriendView — generate/share/enter challenge codes

Navigation: selectedMode: GameMode? drives full-screen PuzzleGameView push
```

### PuzzleGameView Structure

```
VStack {
    Header Row
    ├─ Back button (left)
    ├─ Mode title (center-left) — from mode.displayTitle
    └─ Timer (right):
        - normal/daily/weekly: Clock icon + elapsed time (MM:SS.CS)
        - zen: Leaf icon + "Zen" label (no time shown)

    Puzzle Grid (DragGesture — blocked until gameStarted = true)
    │
    ├─ ForEach row/col
    │   └─ Rectangle cell (theme-colored background)
    │
    ├─ Canvas overlay (path lines, theme-colored)
    │
    ├─ Number badges overlay
    │   ├─ Black circle with white number
    │   └─ Hint: LED comet ring + breathing glow (accent color)
    │
    └─ Start Overlay (shown when gameStarted = false)
        ├─ .ultraThinMaterial blur (covers grid — hides numbers/path)
        ├─ Mode icon + title + grid description
        ├─ "Time so far: X:XX.XX" (only shown after Reset in timed modes, as penalty reminder)
        └─ "Start" / "Resume" button (play.fill icon)

    Action Buttons Row
    ├─ Undo (adds +3 second time penalty in timed modes; skipped in zen) — disabled until game started
    ├─ Reset (shows start overlay, timer pauses in timed modes)
    ├─ Hint (breathing glow on next number) — disabled until game started
    └─ New (regenerate + reset timer + show start overlay) — HIDDEN for daily/weekly modes

    Achievement Banner (top overlay, auto-dismisses after 4 seconds)

    Completion Overlay (if allNumbersConnected) — .ultraThinMaterial blur background
    ├─ Title: "Puzzle Complete!" / "Daily Complete!" / "Weekly Complete!"
    ├─ Completion time badge (.regularMaterial pill)
    ├─ "New Personal Best!" badge (timed, non-zen modes only)
    ├─ ShareLink — share result text (.regularMaterial pill)
    └─ "Next Puzzle" / "Back to Menu" button (theme.pathColor filled, shadow)
}
```

---

## 🕹️ Time Trial Mode

`TimeTrialView` is a separate view (not `PuzzleGameView`) with its own state machine.

```
Start Overlay → 3-minute countdown begins → auto-generates puzzles

Puzzle auto-advances on completion (no user action needed)
Difficulty escalates every 5 solved puzzles:
  easy (0-4) → medium (5-9) → hard (10-14) → veryHard (15-19) → expert (20+)

Score = sum of ProgressionManager.baseXP(for: currentDifficulty) per solved puzzle

When countdown reaches 0:
  → Finish overlay shows score, solved count, ShareLink
  → AchievementManager.shared.checkTimeTrial(score:) is called
```

Uses `Timer.publish` + `Combine` for the countdown. Requires `import Combine`.

### Undo / Reset Buttons in Time Trial

From **Medium difficulty onwards** (`currentDifficulty != .easy`, i.e. puzzle #5+), two action buttons appear below the grid:

| Button | Action | Enabled condition |
|--------|--------|-------------------|
| **Undo** (`arrow.uturn.backward`) | `gameState.undo()` — steps back one cell in the path | `isRunning && !path.isEmpty` |
| **Reset** (`arrow.counterclockwise`) | `gameState.reset()` — clears the entire path for the current puzzle | `isRunning && !path.isEmpty` |

**No extra time penalty**: the countdown timer continues while the player undoes/resets — that is the natural penalty. Buttons are hidden (`.opacity(0.4)`) when disabled and fade in with `.animation(.easeInOut(duration: 0.25))` when difficulty first crosses into Medium.

---

## 👥 Challenge a Friend

`ChallengeFriendView` lets players generate and share puzzle codes.

**Code generation:**
```swift
// 6-character base-36 code from seed + difficulty index
let diffIndex = Difficulty.allCases.firstIndex(of: selectedDifficulty) ?? 0
let combined = (seed << 4) | UInt64(diffIndex)
// Encode as 6 base-36 characters (digits 0-9, letters a-z)
```

**Copy to clipboard:**
```swift
UIPasteboard.general.string = generatedCode
// Shows toast: .toast("Đã sao chép mã!", isShowing: $codeCopied)
```

**Enter friend's code → decode seed + difficulty → launch `PuzzleGameView` with `.challenge(difficulty, seed)`.**

**Bug fixes applied (v4.2):**
- Input filter now accepts both letters AND digits: `{ $0.isLetter || $0.isNumber }` (was `\.isLetter`, silently dropped numeric characters)
- `decode()` now returns `.challenge(difficulty, seed)` instead of `.normal(difficulty)` — the decoded seed is now actually used for deterministic puzzle generation

---

## 🚨 Custom Alert System

Reusable popup component in `AppAlertView.swift`. Replaces `confirmationDialog` for full design control.

```swift
struct AppAlertView: View {
    let icon: String?        // SF Symbol name (optional) — shown in circle at top
    let iconColor: Color     // Circle + confirm button color (default .red for destructive)
    let title: String
    let message: String
    let confirmLabel: String
    let cancelLabel: String
    let onConfirm: () -> Void
    let onCancel: () -> Void
}
```

**Usage via `View.appAlert(...)` modifier:**
```swift
.appAlert(
    isPresented: $showAlert,
    icon: "trash.fill",
    iconColor: .red,
    title: lm.t("settings.reset_confirm_title"),
    message: lm.t("settings.reset_confirm_message"),
    confirmLabel: lm.t("settings.reset_confirm_action"),
    cancelLabel: lm.t("common.cancel"),
    onConfirm: { /* action */ }
)
```

**Animation**: Spring appear (scale 0.86 → 1.0 + fade), ease-out dismiss. Respects `accessibilityReduceMotion` — animation skipped when enabled.

**Overlay background**: `Color.black.opacity(0.45)` + `.ultraThinMaterial` blur — does NOT dismiss on backdrop tap for destructive actions.

**Localization**: All cancel labels use `lm.t("common.cancel")` — key exists in all 9 `.strings` files.

---

## 🍞 Toast Notification System

Reusable `ViewModifier` in `ToastModifier.swift`:

```swift
struct ToastModifier: ViewModifier {
    let message: String
    let systemImage: String    // default: "checkmark.circle.fill"
    let imageColor: Color      // default: .green
    @Binding var isShowing: Bool
    // Auto-dismisses after 2 seconds
}

extension View {
    func toast(_ message: String,
               systemImage: String = "checkmark.circle.fill",
               imageColor: Color = .green,
               isShowing: Binding<Bool>) -> some View
}
```

**Usage in any view:**
```swift
@State private var showToast = false

someView
    .toast("Copied!", isShowing: $showToast)

// To trigger:
showToast = true  // auto-dismisses after 2 seconds
```

Toast renders as a capsule with black background, white text + icon, sliding up from bottom with fade transition.

---

## 📈 Statistics View

`StatisticsView` now contains these sections (in order):

1. **Progression** — Level badge, XP progress bar, level name + next threshold
2. **Daily Activity** — `StreakCalendarView` (13-week GitHub-style heatmap)
3. **Daily Streak** — Current streak / Best streak / Total daily solves
4. **Best Times** — Per-difficulty personal bests
5. **Solve Counts** — Per-difficulty solve counts + no-undo counts
6. **Achievements** — 25-achievement grid with lock/unlock state

### StreakCalendarView

13 columns (weeks) × 7 rows (days). Cells colored with `themeManager.current.pathColor` when completed, `Color(uiColor: .systemFill)` otherwise. Reads `StreakManager.shared.hasCompleted(on:)` for each cell.

---

## ⏱️ Timer System

- **Does NOT start automatically** — timer only begins after user taps the **Start** button on the blur overlay
- Stops when `allNumbersConnected` becomes `true`
- **Zen mode**: Timer display replaced with leaf icon + "Zen" label. `addTimePenalty()` is skipped.
- **State variable**: `gameStarted: Bool` — controls both the blur overlay visibility and timer ticking

| Button | Overlay | Timer Behavior | Rationale |
|--------|---------|---------------|-----------|
| **Start** | Dismissed | Begins counting | User-controlled start |
| **Undo** | — | +2 seconds penalty (skipped in zen) | Discourages excessive undo |
| **Reset** | Shown again | Pauses (elapsed time kept) | Penalty stays; user must re-tap Start |
| **New** | Shown again | Reset to 0:00.00 | Fresh puzzle = fresh time |
| **Next Puzzle** | Shown again | Reset to 0:00.00 | Fresh puzzle after win |

**Timer functions:**
- `startGame()` — sets `gameStarted = true`, starts timer from `lastUpdateTime = Date()`
- `resetTimer()` — resets `elapsedTime = 0`, sets `gameStarted = false` (for New/Next Puzzle)
- `pauseTimer()` — keeps `elapsedTime`, sets `gameStarted = false` (for Reset)

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
- [ ] Weekly seed is consistent within the same ISO week
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
- [ ] **Zen mode**: timer not shown, undo penalty not applied

**3. Statistics & Progression:**
- [ ] `recordCompletion` returns `true` only when new best is set
- [ ] `totalSolveCount` sums across all difficulties
- [ ] Best time is not overwritten if time is worse
- [ ] XP formula: base + bonuses, all applied correctly
- [ ] `StreakManager.recordDailyCompletion()` is idempotent (same day = no double increment)

**4. Achievements:**
- [ ] Each achievement unlocks exactly once (idempotent)
- [ ] `recentlyUnlocked` is nil after `clearRecentlyUnlocked()`
- [ ] `check()` must be called AFTER all managers update their state

---

## 🚀 Performance Considerations

1. **Grid Rendering** — `GeometryReader` calculates cell size once; SwiftUI auto-caches views
2. **Path Drawing** — Canvas API redraws only when `path` changes
3. **Haptics** — All generators pre-prepared in `HapticManager.init()`
4. **Puzzle Generation** — O(N) Warnsdorff + O(K×15) placement = very fast on all grid sizes
5. **Seeded RNG** — Xorshift64 is extremely fast; no performance difference vs. system RNG
6. **`@Observable` singletons** — All managers use stored properties + `didSet` for UserDefaults; computed properties would break reactivity

---

## 🐛 Known Issues & Limitations

1. **No full undo history** — Undo steps back one checkpoint (number) at a time, not cell-by-cell
2. **No solution validator** — Assumes all generated puzzles are solvable (they are, by construction)
3. **No game persistence** — Closing the app mid-game loses current progress
4. **Daily challenge: one attempt only** — No way to retry a failed daily puzzle
5. **Game Center: requires network** — Leaderboard submission silently fails when offline (scores are not queued)
6. **Localization `.strings` files require manual Target Membership** — When adding new `.strings` files to the Xcode project, they must be checked under **Target Membership → FlowConnectPuzzle** in the File Inspector. Without this, `Bundle.main.path(forResource:ofType:)` returns `nil` and `LocalizationManager.t()` falls back to returning the raw key string instead of the translated value.

---

## 📝 Code Style Guidelines

### SwiftUI Best Practices

```swift
// ✅ GOOD: @Observable macro
@Observable class GameState { var grid: [[GridCell]] }

// ❌ BAD: Legacy @ObservableObject
class GameState: ObservableObject { @Published var grid: [[GridCell]] }
```

**Modern API requirements (iOS 17+/SwiftUI):**
- Use `.foregroundStyle()` — never `.foregroundColor()` (deprecated)
- Use `.clipShape(RoundedRectangle(cornerRadius: X))` — never `.cornerRadius(X)` (deprecated)
- Use `NavigationStack` — never `NavigationView` (deprecated)
- Use `.topBarTrailing` — never `.navigationBarTrailing` (deprecated)
- Use `Bindable(observableObject).property` for bindings — never `Binding(get:set:)` for simple cases
- Use `Task { try? await Task.sleep(for: .seconds(X)) }` — never `DispatchQueue.main.asyncAfter`

### @Observable + UserDefaults Pattern

```swift
// ✅ CORRECT: stored property + didSet
@Observable class SomeManager {
    var someValue: Int = 0 {
        didSet { UserDefaults.standard.set(someValue, forKey: "key") }
    }
}

// ❌ WRONG: computed property breaks @Observable tracking
@Observable class SomeManager {
    var someValue: Int {
        get { UserDefaults.standard.integer(forKey: "key") }
        set { UserDefaults.standard.set(newValue, forKey: "key") }
    }
}
```

### Naming Conventions

- **Properties**: camelCase (`gridSize`, `usedUndo`, `allNumbersConnected`)
- **Functions**: camelCase verbs (`addToPath`, `checkCompletion`, `recordCompletion`)
- **Types**: PascalCase (`GridPosition`, `GameTheme`, `Achievement`)
- **Singletons**: `.shared` static property on `@Observable` classes

### Critical Rules

- Win condition is `allNumbersConnected` — there is no `isComplete` property
- Never use hardcoded colors (`.blue`, `.green`) for game elements — read from `ThemeManager.shared.current`
- All haptic calls go through `HapticManager.shared`
- All sound calls go through `SoundManager.shared`
- **Completion call order is critical** — see "Completion Flow" section above
- `ThemeManager.current` MUST be a stored property with `didSet` — computed property breaks `@Observable`

---

## 🔗 File Dependencies Map

```
ContentView.swift
  ├─→ AppearanceMode.swift (AppearanceManager)
  ├─→ AppColorScheme.swift (LightAppColorScheme, DarkAppColorScheme)
  ├─→ GameMode.swift
  ├─→ DailyChallenge.swift
  ├─→ WeeklyChallenge.swift
  ├─→ StatisticsManager.swift
  ├─→ ProgressionManager.swift
  ├─→ ThemeManager (GameTheme.swift)
  ├─→ OnboardingView.swift
  ├─→ StatisticsView.swift
  ├─→ TimeTrialView.swift
  ├─→ ChallengeFriendView.swift
  └─→ PuzzleGameView.swift (mode: GameMode)
        ├─→ GameState.swift
        │     ├─→ GridCell.swift
        │     ├─→ PuzzleGenerator.swift (SeededRNG + Warnsdorff)
        │     │     └─→ Difficulty.swift
        │     └─→ HapticManager.swift
        ├─→ StatisticsManager.swift
        ├─→ StreakManager.swift
        ├─→ ProgressionManager.swift
        ├─→ AchievementManager.swift
        ├─→ SoundManager.swift
        ├─→ GameCenterManager.swift
        ├─→ ThemeManager (GameTheme.swift)
        ├─→ DailyChallenge.swift
        ├─→ WeeklyChallenge.swift
        └─→ AchievementBannerView.swift

StatisticsView.swift
  ├─→ ProgressionManager.swift
  ├─→ StreakManager.swift
  ├─→ StreakCalendarView.swift
  ├─→ StatisticsManager.swift
  ├─→ AchievementManager.swift
  └─→ ThemeManager (GameTheme.swift)

TimeTrialView.swift
  ├─→ GameState.swift
  ├─→ PuzzleGenerator.swift
  ├─→ ProgressionManager.swift
  ├─→ AchievementManager.swift
  ├─→ ThemeManager (GameTheme.swift)
  └─→ import Combine (for Timer.publish)

ChallengeFriendView.swift
  └─→ ToastModifier.swift
```

---

## 💡 AI Assistant Tips

### When asked about bugs:
1. **Check GameState.swift first** — source of most logic errors
2. **Use `allNumbersConnected`** — `isComplete` has been removed; `allNumbersConnected` is the only win flag
3. **Check `usedUndo` reset** — must be false after `newGame()` and `reset()`
4. **Check completion call order** — StreakManager → ProgressionManager → AchievementManager

### When asked to add features:
1. **Use `@Observable`** — never `@ObservableObject`
2. **Use stored property + `didSet`** — never computed property for `@Observable` persistence
3. **Use theme colors** — read `ThemeManager.shared.current.pathColor` etc., don't hardcode
4. **Thread haptics** — every user action needs feedback via `HapticManager.shared`
5. **Statistics integration** — new game modes must call `StatisticsManager.shared.recordCompletion()`
6. **XP integration** — call `ProgressionManager.shared.recordCompletion()` after stats
7. **Sound integration** — call `SoundManager.shared.playStep()` etc. for UX polish

### When working with Game Modes:
1. `PuzzleGameView` takes `mode: GameMode` — use computed shorthands `isDaily`, `isZen`, etc.
2. Zen mode: skip timer display, skip `addTimePenalty()`, set `isPersonalBest = false`
3. Seeded modes (daily/weekly/challenge): `mode.seed` provides the seed for `GameState.init(dailyDifficulty:seed:)`
4. Weekly challenge always uses `.expert` difficulty
5. `.challenge(difficulty, seed)` behaves like `.normal` but is seeded — `mode.isSeeded = true`, personal best tracked

### When working with Daily/Weekly Challenge:
1. Daily seed = `UInt64(year * 10000 + month * 100 + day)`
2. Weekly seed = `UInt64(year * 1000 + isoWeek)`
3. Completion is stored per-seed in UserDefaults
4. Daily/Weekly modes hide "New Puzzle" button

---

## 📚 Reference Documentation

### Key Algorithms
- **Warnsdorff's Algorithm**: [Wikipedia](https://en.wikipedia.org/wiki/Knight%27s_tour#Warnsdorff's_rule)
- **Xorshift RNG**: [Wikipedia](https://en.wikipedia.org/wiki/Xorshift)
- **Manhattan Distance**: Taxicab geometry metric
- **ISO Week Numbering**: [Wikipedia](https://en.wikipedia.org/wiki/ISO_week_date)

### SwiftUI APIs Used
- `@Observable` macro (iOS 17+)
- `GeometryReader`
- `Canvas` (path drawing)
- `DragGesture`
- `.onReceive(timer)` for animations and game timer
- `.sheet()` for Stats and Settings
- `.overlay(alignment:)` for achievement banner
- `ShareLink` (iOS 16+) for share sheets
- `ViewModifier` for `ToastModifier` and `AppAlertModifier`

### System Frameworks Used
- `UIKit` — `UIFeedbackGenerator`, `UIPasteboard`
- `AudioToolbox` — `AudioServicesPlaySystemSound`
- `GameKit` — `GKLocalPlayer`, `GKLeaderboard`
- `UserNotifications` — `UNUserNotificationCenter`
- `Combine` — `Timer.publish` (in `TimeTrialView`)

---

## ✅ Quick Checklist for AI Assistant

When working with this codebase, remember:

- [ ] Win condition is `allNumbersConnected` — `isComplete` no longer exists
- [ ] `usedUndo` is `true` after first Undo, reset on `newGame()` / `reset()`
- [ ] **Easy**: Allows drag-backtracking to previous cell
- [ ] **Medium/Hard/Very Hard/Expert**: No drag-backtracking — Undo button only
- [ ] Undo removes path back to (and including) last number checkpoint
- [ ] **Completion order**: StatisticsManager → StreakManager → ProgressionManager → GameCenterManager → AchievementManager
- [ ] Never hardcode game colors — always use `ThemeManager.shared.current`
- [ ] All haptics through `HapticManager.shared`
- [ ] All sounds through `SoundManager.shared`
- [ ] Grid coordinates: row (vertical) × col (horizontal)
- [ ] Adjacency: only 4-directional (no diagonal)
- [ ] Seeded generation: pass `seed: UInt64` to `PuzzleGenerator.generate(for:seed:)`
- [ ] Daily/Weekly mode hides "New Puzzle" button
- [ ] `gameStarted = false` on initial load, Reset, New, Next Puzzle — timer only ticks when `gameStarted = true`
- [ ] Undo penalty is **+2 seconds** (not 3) — skip in Zen mode
- [ ] `completionOverlay` background is `.ultraThinMaterial` — overlay order: completion first, then achievement banner (banner always on top)
- [ ] Custom alerts use `.appAlert(...)` modifier — NOT `confirmationDialog`; cancel label uses `lm.t("common.cancel")`
- [ ] `ThemeManager.current` MUST be a stored property — computed property breaks `@Observable` reactivity
- [ ] All `@Observable` managers use **stored property + `didSet`** for UserDefaults — NEVER computed property
- [ ] Zen mode: no timer display, no time penalties, no personal best tracking
- [ ] `TimeTrialView` requires `import Combine` for `Timer.publish`
- [ ] `PuzzleGameView` init signature: `init(mode: GameMode, onBack: @escaping () -> Void)`
- [ ] Appearance mode uses `AppearanceManager.shared` — `mode` is a **stored property** with `didSet` (NOT computed)
- [ ] `.preferredColorScheme()` must be applied to **both** the root `Group` in `ContentView` AND the `NavigationStack` inside the settings sheet — sheets don't inherit from parent
- [ ] `DarkAppColorScheme` values are exact Apple UIColor dark-mode values — do not replace with approximations
- [ ] `AppColorSchemeProtocol` is separate from `GameTheme` — protocol is for light/dark chrome colors; `GameTheme` is for in-game path/accent colors

---

**Last Updated**: 2026-05-02
**Version**: 4.4
**Changelog**:
- v4.4 (2026-05-02): Appearance Mode (Light / Dark / System) + Apple HIG dark colors
  - **AppColorScheme.swift** (new): `AppColorSchemeProtocol` defining backgrounds, text, UI element, and typography tokens. `LightAppColorScheme` and `DarkAppColorScheme` conform to protocol. Dark scheme uses exact Apple UIColor dark-mode resolved values (`#1C1C1E`, `#2C2C2E`, `#3A3A3C`, `#8E8E93`, `#48484A`, `#38383A`, `#FF453A`).
  - **AppearanceMode.swift** (new): `enum AppearanceMode` (`.light`/`.dark`/`.system`) + `@Observable class AppearanceManager` singleton. `mode` is a stored property with `didSet` persisting to UserDefaults (`"appearance_mode"` key). Exposes `preferredColorScheme: ColorScheme?` (nil = system).
  - **ContentView.swift**: Added `@State private var appearanceManager = AppearanceManager.shared`. Root `Group.body` gets `.preferredColorScheme(appearanceManager.preferredColorScheme)`. Settings sheet's `NavigationStack` gets the same modifier (sheets don't inherit from parent). Appearance section (first in Settings list) uses `ForEach(AppearanceMode.allCases)` with icon + label + checkmark rows.
  - **Launch Screen**: Replaced failing `UILaunchStoryboardName` / `LaunchScreen.storyboard` with `UILaunchScreen` dictionary in `Info.plist` referencing `LaunchBackground` named color asset (light: `#F2F2F7`, dark: `#1C1C1E`). Eliminates "com.apple.InterfaceBuilder error -1" parse failures.
  - **Localization**: Added `settings.appearance`, `settings.appearance_light`, `settings.appearance_dark`, `settings.appearance_system` to all 9 `.strings` files.
- v4.3 (2026-05-01): UX polish + reusable alert system
  - **AppAlertView.swift** (new): Reusable custom popup component. `AppAlertView` struct + `AppAlertModifier` (private) + `View.appAlert(...)` extension. Replaces native `confirmationDialog` for full design control. Spring/fade animation respects `accessibilityReduceMotion`. Overlay does NOT dismiss on backdrop tap.
  - **Reset All Game Data**: Settings now uses `.appAlert(...)` instead of `.confirmationDialog`. All 9 localization files updated with `common.cancel` key.
  - **completionOverlay**: Background changed from `Color.black.opacity(0.7)` to `.ultraThinMaterial` frosted glass. Text uses `.primary`/`.secondary` for adaptive light/dark mode. Inner pills use `.regularMaterial`. Overlay order fixed — achievement banner now renders after completion overlay so it always appears on top.
  - **Undo penalty**: Reduced from +3 seconds to +2 seconds. Accessibility label updated to match.
  - **Achievement icons**: Fixed two invalid SF Symbol names — `solve_100` (`100.circle.fill` → `checkmark.seal.fill`), `level_20` (`crown.circle.fill` → `trophy.fill`).
  - **Achievement table**: AGENT.md corrected to match actual 25 achievement IDs in `AchievementManager.swift`.
- v4.2 (2026-05-01): SwiftUI Pro review — API modernisation + bug fixes + `.challenge` game mode
  - **GameMode**: Added `.challenge(Difficulty, UInt64)` case for friend challenges; `isSeeded`/`seed`/`displayTitle` updated; `displayTitle` now reads from `LocalizationManager.shared` (all languages supported); added `"game.challenge"` and `"challenge.instructions"` keys to `en.strings`
  - **GameState**: Removed dead `isComplete: Bool` property (was never read, only written); simplified backtracking check from 4-way OR to `if difficulty != .easy`
  - **ChallengeFriendView bugs fixed**: (1) Input filter now accepts digits — was `\.isLetter`, silently dropping `0–9`; (2) `decode()` now returns `.challenge(difficulty, seed)` so the seeded puzzle actually loads
  - **Deprecated API replaced across all views**: `.foregroundColor()` → `.foregroundStyle()`, `.cornerRadius(X)` → `.clipShape(RoundedRectangle(cornerRadius: X))`, `NavigationView` → `NavigationStack`, `.navigationBarTrailing` → `.topBarTrailing`
  - **Concurrency**: All `DispatchQueue.main.asyncAfter` in SwiftUI views replaced with `Task { try? await Task.sleep(for:) }`
  - **Data flow**: `Binding(get:set:)` for `SoundManager.isEnabled` replaced with `Bindable(soundManager).isEnabled`
  - **Accessibility**: Added `.accessibilityLabel` to icon-only buttons (Statistics, Settings, Close) across `ContentView` and `TimeTrialView`
  - **Performance**: `sortedNumberPositions` pre-computed as a view-level computed property in `PuzzleGameView` — avoids re-sorting on every 60fps render
  - **Localization**: Hardcoded English instruction string in `ChallengeFriendView` replaced with `lm.t("challenge.instructions")`
- v4.1 (2026-05-01): Time Trial UX fix + Localization bug documentation
  - **TimeTrialView**: Added Undo and Reset buttons that appear from Medium difficulty onwards (`currentDifficulty != .easy`). No extra time penalty — countdown is the natural cost. Buttons are disabled/dimmed when path is empty or game not running.
  - **Known Issue documented**: `.strings` files added to Xcode must be manually checked under Target Membership → FlowConnectPuzzle, otherwise `Bundle.main.path(forResource:ofType:)` returns `nil` and localization falls back to raw keys.
- v4.0 (2026-04-30): Daily engagement features — 4 tiers implemented
  - **New Models**: `GameMode` enum (replaces separate boolean flags), `WeeklyChallenge`
  - **New Services**: `StreakManager`, `NotificationManager`, `ProgressionManager`, `SoundManager`, `GameCenterManager`
  - **New Views**: `StreakCalendarView` (heatmap), `TimeTrialView` (3-min countdown), `ChallengeFriendView` (code sharing), `ToastModifier` (reusable toast)
  - **PuzzleGameView refactor**: replaced `difficulty/isDaily/isWeekly` with `mode: GameMode`; added Zen mode support
  - **AchievementManager**: expanded from 10 → 25 achievements; added `isWeekly`/`isZen` params + `checkTimeTrial(score:)` method
  - **StatisticsView**: added Progression section (XP bar), Daily Activity (StreakCalendarView), Daily Streak counters
  - **ContentView**: added Weekly Challenge card, Time Trial button, Zen Mode picker, sound toggle, Challenge a Friend button
  - **FlowConnectPuzzleApp**: added `.task {}` for notification permission + Game Center auth on launch
  - **Critical fix**: completion call order must be StatisticsManager → StreakManager → ProgressionManager → AchievementManager
- v3.1 (2026-04-26): Start overlay + ThemeManager fix
  - Added **Start Overlay** in `PuzzleGameView` — `.ultraThinMaterial` blur covers grid until user taps Start
  - Timer now starts ONLY when user taps Start (not on view appear)
  - Reset shows overlay again, pausing timer while keeping elapsed time (penalty preserved)
  - New/Next Puzzle shows overlay and resets timer to 0
  - Added `startGame()`, `pauseTimer()` functions; `resetTimer()` no longer auto-starts
  - Fixed **ThemeManager** — `current` converted from computed property to stored property + `didSet` to fix `@Observable` reactivity
  - Added 4 named `#Preview` variants for `PuzzleGameView`
- v3.0 (2026-04-26): Major feature expansion
  - Added Statistics, Achievement, Theme, Daily Challenge, Onboarding systems
- v2.1 (2026-04-19): Updated timer penalty system
- v2.0 (2026-04-19): Added Very Hard (8×8) and Expert (9×9) difficulty levels
- v1.1 (2026-04-19): Added millisecond precision timer
- v1.0 (2026-04-19): Initial documentation

**Maintained by**: AI Assistant + Development Team
