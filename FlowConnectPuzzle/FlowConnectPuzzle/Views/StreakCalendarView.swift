//
//  StreakCalendarView.swift
//  FlowConnectPuzzle
//

import SwiftUI

/// GitHub-style heatmap showing daily challenge completions over the last 13 weeks.
struct StreakCalendarView: View {
    @State private var streak = StreakManager.shared
    @State private var themeManager = ThemeManager.shared

    private let weeksToShow = 13

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Daily Activity — Last 3 Months")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)

            HStack(alignment: .top, spacing: 3) {
                ForEach(0..<weeksToShow, id: \.self) { weekIndex in
                    VStack(spacing: 3) {
                        ForEach(0..<7, id: \.self) { dayIndex in
                            // weekIndex 0 = oldest week, weeksToShow-1 = current week
                            // dayIndex 0 = top of column (oldest day in that week)
                            let daysAgo = (weeksToShow - 1 - weekIndex) * 7 + (6 - dayIndex)
                            let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())
                            let today = Calendar.current.startOfDay(for: Date())
                            let isFuture = date.map { Calendar.current.startOfDay(for: $0) > today } ?? true
                            let completed = date.map { streak.hasCompleted(on: $0) } ?? false

                            RoundedRectangle(cornerRadius: 2)
                                .fill(
                                    isFuture
                                        ? Color.clear
                                        : (completed
                                            ? themeManager.current.pathColor
                                            : Color(uiColor: .systemFill))
                                )
                                .frame(width: 16, height: 16)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)

            // Legend
            HStack(spacing: 6) {
                Spacer()
                Text("Less")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                ForEach([0.0, 0.3, 0.6, 1.0], id: \.self) { opacity in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(opacity == 0.0
                            ? Color(uiColor: .systemFill)
                            : themeManager.current.pathColor.opacity(opacity))
                        .frame(width: 10, height: 10)
                }
                Text("More")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    StreakCalendarView()
        .padding()
}
