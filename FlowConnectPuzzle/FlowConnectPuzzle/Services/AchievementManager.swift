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
        Achievement(id: "streak_3",        title: "On Fire",          description: "Complete a 3-day daily streak",          iconName: "flame"),
        Achievement(id: "streak_7",        title: "Week Warrior",     description: "Complete a 7-day daily streak",          iconName: "calendar.badge.clock"),
        Achievement(id: "streak_14",       title: "Fortnight Fire",   description: "Complete a 14-day daily streak",         iconName: "flame.fill"),
        Achievement(id: "streak_30",       title: "Monthly Master",   description: "Complete a 30-day daily streak",         iconName: "calendar.circle.fill"),
        Achievement(id: "weekly_champion", title: "Weekly Champion",  description: "Complete a Weekly Challenge",            iconName: "crown.fill"),
        Achievement(id: "speed_veryhard",  title: "Blitz",            description: "Solve Very Hard in under 8 minutes",     iconName: "bolt.circle.fill"),
        Achievement(id: "solver_100",      title: "Century",          description: "Solve 100 puzzles total",                iconName: "100.circle.fill"),
        Achievement(id: "solver_200",      title: "Bicentennial",     description: "Solve 200 puzzles total",                iconName: "200.circle"),
        Achievement(id: "zen_master",      title: "Zen Master",       description: "Complete Zen mode on Expert difficulty", iconName: "leaf.circle.fill"),
        Achievement(id: "time_trial_debut",title: "Sprint Start",     description: "Finish your first Time Trial",           iconName: "timer"),
        Achievement(id: "time_trial_100",  title: "Century Sprint",   description: "Score 100+ pts in a Time Trial",         iconName: "rosette"),
        Achievement(id: "time_trial_500",  title: "High Scorer",      description: "Score 500+ pts in a Time Trial",         iconName: "star.circle.fill"),
        Achievement(id: "level_5",         title: "Master",           description: "Reach Level 5 (Master)",                iconName: "graduationcap.fill"),
        Achievement(id: "level_10",        title: "Champion",         description: "Reach Level 10 (Champion)",             iconName: "trophy.circle.fill"),
        Achievement(id: "dedicated",       title: "Dedicated",        description: "Complete 30 daily challenges total",     iconName: "calendar.badge.checkmark"),
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

        if stats.totalSolveCount == 1   { unlock(id: "first_solve") }
        if stats.totalSolveCount >= 10  { unlock(id: "collector") }
        if stats.totalSolveCount >= 50  { unlock(id: "veteran") }
        if stats.totalSolveCount >= 100 { unlock(id: "solver_100") }
        if stats.totalSolveCount >= 200 { unlock(id: "solver_200") }

        if difficulty == .easy     && time < 60  { unlock(id: "speed_easy") }
        if difficulty == .medium   && time < 120 { unlock(id: "speed_medium") }
        if difficulty == .hard     && time < 300 { unlock(id: "speed_hard") }
        if difficulty == .veryHard && time < 480 { unlock(id: "speed_veryhard") }

        if !usedUndo { unlock(id: "purist") }
        let hardOrAbove = difficulty == .hard || difficulty == .veryHard || difficulty == .expert
        if hardOrAbove && !usedUndo { unlock(id: "iron_will") }

        if difficulty == .expert { unlock(id: "expert_solver") }
        if isZen && difficulty == .expert { unlock(id: "zen_master") }

        if isWeekly { unlock(id: "weekly_champion") }

        if isDaily {
            unlock(id: "daily_champion")
            let streak = StreakManager.shared
            if streak.currentStreak >= 3  { unlock(id: "streak_3") }
            if streak.currentStreak >= 7  { unlock(id: "streak_7") }
            if streak.currentStreak >= 14 { unlock(id: "streak_14") }
            if streak.currentStreak >= 30 { unlock(id: "streak_30") }
            if streak.totalDailySolves >= 30 { unlock(id: "dedicated") }
        }

        let level = ProgressionManager.shared.level
        if level >= 4 { unlock(id: "level_5") }   // level is 0-indexed: 4 = "Level 5"
        if level >= 9 { unlock(id: "level_10") }
    }

    /// Call from TimeTrialView when session ends.
    func checkTimeTrial(score: Int) {
        unlock(id: "time_trial_debut")
        if score >= 100 { unlock(id: "time_trial_100") }
        if score >= 500 { unlock(id: "time_trial_500") }
    }

    func clearRecentlyUnlocked() {
        recentlyUnlocked = nil
    }
}
