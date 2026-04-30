//
//  WeeklyChallenge.swift
//  FlowConnectPuzzle
//

import Foundation

enum WeeklyChallenge {
    /// Unique seed for the current ISO week (YYYYwWW as an integer).
    static var thisWeekSeed: UInt64 {
        let c = Calendar(identifier: .iso8601)
        let d = Date()
        let year = c.component(.yearForWeekOfYear, from: d)
        let week = c.component(.weekOfYear, from: d)
        return UInt64(year * 1000 + week)
    }

    /// Weekly challenge is always Expert difficulty.
    static var difficulty: Difficulty { .expert }

    static var isCompletedThisWeek: Bool {
        get { UserDefaults.standard.bool(forKey: "weekly_done_\(thisWeekSeed)") }
        set { UserDefaults.standard.set(newValue, forKey: "weekly_done_\(thisWeekSeed)") }
    }

    /// Human-readable date range for the current week (Mon – Sun).
    static var formattedDateRange: String {
        var calendar = Calendar.current
        calendar.firstWeekday = 2  // Monday
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: Date()) else { return "" }
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        let monday = weekInterval.start
        let sunday = calendar.date(byAdding: .day, value: 6, to: monday) ?? weekInterval.end
        return "\(fmt.string(from: monday)) – \(fmt.string(from: sunday))"
    }
}
