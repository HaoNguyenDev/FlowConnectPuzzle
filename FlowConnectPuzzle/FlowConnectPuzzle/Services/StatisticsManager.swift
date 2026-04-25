//
//  StatisticsManager.swift
//  FlowConnectPuzzle
//

import Foundation

@Observable
class StatisticsManager {
    static let shared = StatisticsManager()

    private let defaults = UserDefaults.standard

    private func key(_ base: String, _ difficulty: Difficulty) -> String {
        "\(base)_\(difficulty.rawValue)"
    }

    func bestTime(for difficulty: Difficulty) -> TimeInterval? {
        let v = defaults.double(forKey: key("bestTime", difficulty))
        return v > 0 ? v : nil
    }

    func solveCount(for difficulty: Difficulty) -> Int {
        defaults.integer(forKey: key("solveCount", difficulty))
    }

    func noUndoCount(for difficulty: Difficulty) -> Int {
        defaults.integer(forKey: key("noUndoCount", difficulty))
    }

    var totalSolveCount: Int {
        Difficulty.allCases.reduce(0) { $0 + solveCount(for: $1) }
    }

    /// Records a completed puzzle. Returns true if a new personal best was set.
    @discardableResult
    func recordCompletion(difficulty: Difficulty, time: TimeInterval, usedUndo: Bool) -> Bool {
        defaults.set(solveCount(for: difficulty) + 1, forKey: key("solveCount", difficulty))
        if !usedUndo {
            defaults.set(noUndoCount(for: difficulty) + 1, forKey: key("noUndoCount", difficulty))
        }
        let current = bestTime(for: difficulty)
        if current == nil || time < current! {
            defaults.set(time, forKey: key("bestTime", difficulty))
            return true
        }
        return false
    }
}
