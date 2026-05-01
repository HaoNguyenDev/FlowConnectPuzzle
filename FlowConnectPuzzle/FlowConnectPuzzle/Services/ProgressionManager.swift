//
//  ProgressionManager.swift
//  FlowConnectPuzzle
//

import Foundation

@Observable
class ProgressionManager {
    static let shared = ProgressionManager()

    static let levelNames: [String] = [
        "Novice", "Apprentice", "Solver", "Thinker", "Strategist",
        "Master", "Grandmaster", "Legend", "Titan", "Champion"
    ]
    // XP required to reach each level
    static let levelThresholds: [Int] = [0, 100, 250, 500, 1000, 2000, 4000, 7500, 12500, 20000]

    var totalXP: Int {
        didSet { UserDefaults.standard.set(totalXP, forKey: "progression_xp") }
    }

    private init() {
        totalXP = UserDefaults.standard.integer(forKey: "progression_xp")
    }

    var level: Int {
        var current = 0
        for (i, threshold) in ProgressionManager.levelThresholds.enumerated() {
            if totalXP >= threshold { current = i }
        }
        return min(current, ProgressionManager.levelThresholds.count - 1)
    }

    var levelName: String { ProgressionManager.levelNames[level] }

    var xpForCurrentLevel: Int { ProgressionManager.levelThresholds[level] }

    var xpForNextLevel: Int? {
        let next = level + 1
        guard next < ProgressionManager.levelThresholds.count else { return nil }
        return ProgressionManager.levelThresholds[next]
    }

    // 0.0–1.0 progress within the current level band
    var progressInCurrentLevel: Double {
        guard let nextXP = xpForNextLevel else { return 1.0 }
        let range = Double(nextXP - xpForCurrentLevel)
        guard range > 0 else { return 1.0 }
        return min(Double(totalXP - xpForCurrentLevel) / range, 1.0)
    }

    func reset() { totalXP = 0 }

    func recordCompletion(
        difficulty: Difficulty,
        isPersonalBest: Bool,
        usedUndo: Bool,
        isDaily: Bool,
        isWeekly: Bool = false
    ) {
        var xp = ProgressionManager.baseXP(for: difficulty)
        if isPersonalBest { xp += 25 }
        if !usedUndo      { xp += 10 }
        if isDaily        { xp += 50 }
        if isWeekly       { xp += 200 }
        totalXP += xp
    }

    static func baseXP(for difficulty: Difficulty) -> Int {
        switch difficulty {
        case .easy:     return 10
        case .medium:   return 20
        case .hard:     return 40
        case .veryHard: return 60
        case .expert:   return 100
        }
    }
}
