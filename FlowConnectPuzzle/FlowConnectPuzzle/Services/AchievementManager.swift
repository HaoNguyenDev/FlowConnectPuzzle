//
//  AchievementManager.swift
//  FlowConnectPuzzle
//

import Foundation

struct Achievement: Identifiable, Equatable {
    let id: String
    let iconName: String
}

@Observable
class AchievementManager {
    static let shared = AchievementManager()

    var recentlyUnlocked: Achievement?

    let all: [Achievement] = [
        Achievement(id: "first_solve",      iconName: "star.fill"),
        Achievement(id: "solve_10",         iconName: "10.circle.fill"),
        Achievement(id: "solve_50",         iconName: "medal.fill"),
        Achievement(id: "solve_100",        iconName: "checkmark.seal.fill"),
        Achievement(id: "solve_500",        iconName: "rosette"),
        Achievement(id: "easy_master",      iconName: "leaf.fill"),
        Achievement(id: "medium_master",    iconName: "flame"),
        Achievement(id: "hard_master",      iconName: "bolt.fill"),
        Achievement(id: "very_hard_master", iconName: "hurricane"),
        Achievement(id: "expert_master",    iconName: "crown.fill"),
        Achievement(id: "speed_demon",      iconName: "bolt.fill"),
        Achievement(id: "lightning",        iconName: "bolt.horizontal.fill"),
        Achievement(id: "streak_3",         iconName: "flame"),
        Achievement(id: "streak_7",         iconName: "calendar.badge.clock"),
        Achievement(id: "streak_30",        iconName: "calendar.circle.fill"),
        Achievement(id: "streak_100",       iconName: "flame.fill"),
        Achievement(id: "daily_7",          iconName: "calendar.badge.checkmark"),
        Achievement(id: "daily_30",         iconName: "calendar.badge.checkmark"),
        Achievement(id: "timetrial_bronze", iconName: "timer"),
        Achievement(id: "timetrial_silver", iconName: "rosette"),
        Achievement(id: "timetrial_gold",   iconName: "star.circle.fill"),
        Achievement(id: "level_5",          iconName: "graduationcap.fill"),
        Achievement(id: "level_10",         iconName: "trophy.circle.fill"),
        Achievement(id: "level_20",         iconName: "trophy.fill"),
        Achievement(id: "perfectionist",    iconName: "hand.raised.fill"),
    ]

    private let defaults = UserDefaults.standard
    private let storageKey = "achievements_unlocked"

    private var unlockedIDs: Set<String> {
        get { Set(defaults.stringArray(forKey: storageKey) ?? []) }
        set { defaults.set(Array(newValue), forKey: storageKey) }
    }

    func isUnlocked(_ achievement: Achievement) -> Bool {
        unlockedIDs.contains(achievement.id)
    }

    var unlocked: [Achievement] {
        all.filter { isUnlocked($0) }
    }

    private func unlock(id: String) {
        var ids = unlockedIDs
        guard !ids.contains(id) else { return }
        ids.insert(id)
        unlockedIDs = ids
        recentlyUnlocked = all.first { $0.id == id }
    }

    /// Call after StatisticsManager, StreakManager, and ProgressionManager have all been updated.
    func check(
        difficulty: Difficulty,
        time: TimeInterval,
        usedUndo: Bool,
        isDaily: Bool,
        isWeekly: Bool = false,
        isZen: Bool = false
    ) {
        let stats = StatisticsManager.shared

        // Total solve milestones
        if stats.totalSolveCount >= 1   { unlock(id: "first_solve") }
        if stats.totalSolveCount >= 10  { unlock(id: "solve_10") }
        if stats.totalSolveCount >= 50  { unlock(id: "solve_50") }
        if stats.totalSolveCount >= 100 { unlock(id: "solve_100") }
        if stats.totalSolveCount >= 500 { unlock(id: "solve_500") }

        // Per-difficulty mastery
        if stats.solveCount(for: .easy)     >= 20 { unlock(id: "easy_master") }
        if stats.solveCount(for: .medium)   >= 15 { unlock(id: "medium_master") }
        if stats.solveCount(for: .hard)     >= 10 { unlock(id: "hard_master") }
        if stats.solveCount(for: .veryHard) >= 5  { unlock(id: "very_hard_master") }
        if difficulty == .expert                   { unlock(id: "expert_master") }

        // Speed achievements
        if difficulty == .easy   && time < 10 { unlock(id: "speed_demon") }
        if difficulty == .medium && time < 20 { unlock(id: "lightning") }

        // Hard+ without undo
        let hardOrAbove = difficulty == .hard || difficulty == .veryHard || difficulty == .expert
        if hardOrAbove && !usedUndo { unlock(id: "perfectionist") }

        // Daily streak milestones
        if isDaily {
            let streak = StreakManager.shared
            if streak.currentStreak >= 3   { unlock(id: "streak_3") }
            if streak.currentStreak >= 7   { unlock(id: "streak_7") }
            if streak.currentStreak >= 30  { unlock(id: "streak_30") }
            if streak.currentStreak >= 100 { unlock(id: "streak_100") }
            if streak.totalDailySolves >= 7  { unlock(id: "daily_7") }
            if streak.totalDailySolves >= 30 { unlock(id: "daily_30") }
        }

        // Level milestones (level is 0-indexed: 4 = Level 5, 9 = Level 10, 19 = Level 20)
        let level = ProgressionManager.shared.level
        if level >= 4  { unlock(id: "level_5") }
        if level >= 9  { unlock(id: "level_10") }
        if level >= 19 { unlock(id: "level_20") }
    }

    /// Call from TimeTrialView when session ends.
    func checkTimeTrial(score: Int) {
        if score >= 100 { unlock(id: "timetrial_bronze") }
        if score >= 300 { unlock(id: "timetrial_silver") }
        if score >= 500 { unlock(id: "timetrial_gold") }
    }

    func reset() {
        unlockedIDs = []
        recentlyUnlocked = nil
    }

    func clearRecentlyUnlocked() {
        recentlyUnlocked = nil
    }
}
