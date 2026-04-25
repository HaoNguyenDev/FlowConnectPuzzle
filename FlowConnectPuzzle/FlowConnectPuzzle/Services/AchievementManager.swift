//
//  AchievementManager.swift
//  FlowConnectPuzzle
//

import Foundation

struct Achievement: Identifiable, Equatable {
    let id: String
    let title: String
    let description: String
    let iconName: String
}

@Observable
class AchievementManager {
    static let shared = AchievementManager()

    var recentlyUnlocked: Achievement?

    let all: [Achievement] = [
        Achievement(id: "first_solve",    title: "First Step",     description: "Solve your first puzzle",             iconName: "star.fill"),
        Achievement(id: "speed_easy",     title: "Speed Demon",    description: "Solve Easy in under 60 seconds",      iconName: "bolt.fill"),
        Achievement(id: "speed_medium",   title: "Lightning",      description: "Solve Medium in under 2 minutes",     iconName: "bolt.horizontal.fill"),
        Achievement(id: "speed_hard",     title: "Blazing",        description: "Solve Hard in under 5 minutes",       iconName: "flame.fill"),
        Achievement(id: "purist",         title: "Purist",         description: "Solve any puzzle without using Undo", iconName: "hand.raised.fill"),
        Achievement(id: "iron_will",      title: "Iron Will",      description: "Solve Hard or above without Undo",    iconName: "shield.fill"),
        Achievement(id: "collector",      title: "Collector",      description: "Solve 10 puzzles total",              iconName: "10.circle.fill"),
        Achievement(id: "veteran",        title: "Veteran",        description: "Solve 50 puzzles total",              iconName: "medal.fill"),
        Achievement(id: "expert_solver",  title: "Expert",         description: "Complete Expert difficulty",          iconName: "crown.fill"),
        Achievement(id: "daily_champion", title: "Daily Champion", description: "Complete the Daily Challenge",        iconName: "calendar.badge.checkmark"),
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

    /// Call after recording completion in StatisticsManager.
    func check(difficulty: Difficulty, time: TimeInterval, usedUndo: Bool, isDaily: Bool) {
        let stats = StatisticsManager.shared

        if stats.totalSolveCount == 1 { unlock(id: "first_solve") }

        if difficulty == .easy   && time < 60  { unlock(id: "speed_easy") }
        if difficulty == .medium && time < 120 { unlock(id: "speed_medium") }
        if difficulty == .hard   && time < 300 { unlock(id: "speed_hard") }

        if !usedUndo { unlock(id: "purist") }
        let hardOrAbove = difficulty == .hard || difficulty == .veryHard || difficulty == .expert
        if hardOrAbove && !usedUndo { unlock(id: "iron_will") }

        if stats.totalSolveCount >= 10 { unlock(id: "collector") }
        if stats.totalSolveCount >= 50 { unlock(id: "veteran") }
        if difficulty == .expert        { unlock(id: "expert_solver") }
        if isDaily                      { unlock(id: "daily_champion") }
    }

    func clearRecentlyUnlocked() {
        recentlyUnlocked = nil
    }
}
