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
    /// Friend challenge — seeded puzzle shared via a challenge code.
    case challenge(Difficulty, UInt64)

    var difficulty: Difficulty {
        switch self {
        case .normal(let d):       return d
        case .daily:               return DailyChallenge.todayDifficulty
        case .weekly:              return WeeklyChallenge.difficulty
        case .zen(let d):          return d
        case .timeTrial:           return .easy
        case .challenge(let d, _): return d
        }
    }

    var isSeeded: Bool {
        switch self {
        case .daily, .weekly:   return true
        case .challenge(_, _):  return true
        default:                return false
        }
    }

    var seed: UInt64? {
        switch self {
        case .daily:               return DailyChallenge.todaySeed
        case .weekly:              return WeeklyChallenge.thisWeekSeed
        case .challenge(_, let s): return s
        default:                   return nil
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
        let lm = LocalizationManager.shared
        switch self {
        case .normal(let d):       return lm.difficultyName(d)
        case .daily:               return lm.t("game.daily_challenge")
        case .weekly:              return lm.t("game.weekly_challenge")
        case .zen(let d):          return "\(lm.difficultyName(d)) — \(lm.t("game.zen"))"
        case .timeTrial:           return lm.t("timetrial.title")
        case .challenge(let d, _): return "\(lm.difficultyName(d)) — \(lm.t("game.challenge"))"
        }
    }
}
