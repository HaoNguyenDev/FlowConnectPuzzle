//
//  DailyChallenge.swift
//  FlowConnectPuzzle
//

import Foundation

enum DailyChallenge {
    /// Unique seed for today, based on calendar date (YYYYMMDD).
    static var todaySeed: UInt64 {
        let c = Calendar.current
        let d = Date()
        let year  = c.component(.year,  from: d)
        let month = c.component(.month, from: d)
        let day   = c.component(.day,   from: d)
        return UInt64(year * 10000 + month * 100 + day)
    }

    /// Rotates through all difficulty levels based on the day of year.
    static var todayDifficulty: Difficulty {
        let c = Calendar.current
        let dayOfYear = c.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let levels: [Difficulty] = [.easy, .medium, .hard, .veryHard, .expert]
        return levels[dayOfYear % levels.count]
    }

    static var isCompletedToday: Bool {
        get { UserDefaults.standard.bool(forKey: "daily_done_\(todaySeed)") }
        set { UserDefaults.standard.set(newValue, forKey: "daily_done_\(todaySeed)") }
    }

    static var formattedDate: String {
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        fmt.timeStyle = .none
        return fmt.string(from: Date())
    }
}
