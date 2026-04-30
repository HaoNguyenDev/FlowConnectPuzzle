//
//  GameMode.swift
//  FlowConnectPuzzle
//

import Foundation

/// Describes how a puzzle session should behave.
enum GameMode: Equatable {
    /// Standard timed puzzle.
    case normal(Difficulty)
    /// Today's seeded daily challenge.
    case daily
    /// This week's seeded Expert challenge.
    case weekly
    /// Relaxed mode — no timer displayed, no undo penalty.
    case zen(Difficulty)
    /// 3-minute sprint — solve as many puzzles as possible.
    case timeTrial

    var difficulty: Difficulty {
        switch self {
        case .normal(let d): return d
        case .daily:         return DailyChallenge.todayDifficulty
        case .weekly:        return WeeklyChallenge.difficulty
        case .zen(let d):    return d
        case .timeTrial:     return .easy
        }
    }

    var isSeeded: Bool {
        switch self {
        case .daily, .weekly: return true
        default:              return false
        }
    }

    var seed: UInt64? {
        switch self {
        case .daily:  return DailyChallenge.todaySeed
        case .weekly: return WeeklyChallenge.thisWeekSeed
        default:      return nil
        }
    }

    var isZen: Bool {
        if case .zen = self { return true }
        return false
    }

    var isTimeTrial: Bool {
        self == .timeTrial
    }

    var displayTitle: String {
        switch self {
        case .normal(let d): return d.displayName
        case .daily:         return "Daily Challenge"
        case .weekly:        return "Weekly Challenge"
        case .zen(let d):    return "\(d.displayName) — Zen"
        case .timeTrial:     return "Time Trial"
        }
    }
}
