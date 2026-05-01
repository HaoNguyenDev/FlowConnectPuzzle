//
//  StreakManager.swift
//  FlowConnectPuzzle
//

import Foundation

@Observable
class StreakManager {
    static let shared = StreakManager()

    var currentStreak: Int {
        didSet { UserDefaults.standard.set(currentStreak, forKey: "streak_current") }
    }
    var bestStreak: Int {
        didSet { UserDefaults.standard.set(bestStreak, forKey: "streak_best") }
    }
    var totalDailySolves: Int {
        didSet { UserDefaults.standard.set(totalDailySolves, forKey: "streak_total_daily") }
    }
    // Stored as Array in UserDefaults since Set is not directly supported
    var completionDates: Set<String> {
        didSet { UserDefaults.standard.set(Array(completionDates), forKey: "streak_dates") }
    }

    private static let dateFormatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt
    }()

    private init() {
        let ud = UserDefaults.standard
        currentStreak    = ud.integer(forKey: "streak_current")
        bestStreak       = ud.integer(forKey: "streak_best")
        totalDailySolves = ud.integer(forKey: "streak_total_daily")
        completionDates  = Set(ud.stringArray(forKey: "streak_dates") ?? [])
    }

    func reset() {
        currentStreak = 0
        bestStreak = 0
        totalDailySolves = 0
        completionDates = []
    }

    func dateKey(for date: Date = Date()) -> String {
        StreakManager.dateFormatter.string(from: date)
    }

    func hasCompleted(on date: Date) -> Bool {
        completionDates.contains(dateKey(for: date))
    }

    /// Record today's daily completion. Safe to call multiple times — idempotent per day.
    func recordDailyCompletion() {
        let today = dateKey()
        guard !completionDates.contains(today) else { return }

        completionDates.insert(today)
        totalDailySolves += 1

        // Increment streak if yesterday was also completed, otherwise reset to 1
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        if completionDates.contains(dateKey(for: yesterday)) {
            currentStreak += 1
        } else {
            currentStreak = 1
        }

        if currentStreak > bestStreak {
            bestStreak = currentStreak
        }
    }
}
