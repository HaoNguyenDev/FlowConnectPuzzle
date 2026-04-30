//
//  StatisticsView.swift
//  FlowConnectPuzzle
//

import SwiftUI

struct StatisticsView: View {
    @State private var stats = StatisticsManager.shared
    @State private var achievements = AchievementManager.shared
    @State private var streak = StreakManager.shared
    @State private var progression = ProgressionManager.shared
    @State private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                // MARK: Progression
                Section("Progression") {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Level \(progression.level + 1) — \(progression.levelName)")
                                    .font(.system(size: 16, weight: .bold))
                                if let nextXP = progression.xpForNextLevel {
                                    Text("\(nextXP - progression.totalXP) XP to \(ProgressionManager.levelNames[progression.level + 1])")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("Maximum level reached! 🏆")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.yellow)
                                }
                            }
                            Spacer()
                            Text("\(progression.totalXP) XP")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(themeManager.current.pathColor)
                        }

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color(uiColor: .systemFill))
                                    .frame(height: 8)
                                Capsule()
                                    .fill(themeManager.current.pathColor)
                                    .frame(width: geo.size.width * progression.progressInCurrentLevel, height: 8)
                            }
                        }
                        .frame(height: 8)
                    }
                    .padding(.vertical, 4)
                }

                // MARK: Daily Activity Calendar
                Section("Daily Activity") {
                    StreakCalendarView()
                        .padding(.vertical, 4)
                }

                // MARK: Daily Streak
                Section("Daily Streak") {
                    HStack {
                        Label("Current Streak", systemImage: "flame.fill")
                            .foregroundColor(.orange)
                        Spacer()
                        Text(streak.currentStreak == 1 ? "1 day" : "\(streak.currentStreak) days")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Label("Best Streak", systemImage: "trophy.fill")
                            .foregroundColor(.yellow)
                        Spacer()
                        Text(streak.bestStreak == 1 ? "1 day" : "\(streak.bestStreak) days")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Label("Daily Challenges", systemImage: "calendar.badge.checkmark")
                            .foregroundColor(.blue)
                        Spacer()
                        Text("\(streak.totalDailySolves) solved")
                            .foregroundColor(.secondary)
                    }
                }

                // MARK: Best Times
                Section("Best Times") {
                    ForEach(Difficulty.allCases) { difficulty in
                        HStack {
                            Image(systemName: difficulty.iconName)
                                .foregroundColor(.blue)
                                .frame(width: 28)
                            Text(difficulty.displayName)
                            Spacer()
                            if let best = stats.bestTime(for: difficulty) {
                                Text(formatTime(best))
                                    .font(.system(size: 14, weight: .medium).monospacedDigit())
                                    .foregroundColor(.secondary)
                            } else {
                                Text("—")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                // MARK: Puzzles Solved
                Section("Puzzles Solved") {
                    ForEach(Difficulty.allCases) { difficulty in
                        HStack {
                            Image(systemName: difficulty.iconName)
                                .foregroundColor(.blue)
                                .frame(width: 28)
                            Text(difficulty.displayName)
                            Spacer()
                            Text("\(stats.solveCount(for: difficulty))")
                                .foregroundColor(.secondary)
                        }
                    }
                    HStack {
                        Text("Total")
                            .fontWeight(.semibold)
                        Spacer()
                        Text("\(stats.totalSolveCount)")
                            .fontWeight(.semibold)
                    }
                }

                // MARK: Achievements
                Section("Achievements (\(achievements.unlocked.count)/\(achievements.all.count))") {
                    ForEach(achievements.all) { achievement in
                        let unlocked = achievements.isUnlocked(achievement)
                        HStack(spacing: 12) {
                            Image(systemName: achievement.iconName)
                                .font(.system(size: 20))
                                .foregroundColor(unlocked ? .yellow : .gray.opacity(0.3))
                                .frame(width: 32)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(achievement.title)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(unlocked ? .primary : .secondary)
                                Text(achievement.description)
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }

                            if unlocked {
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                        .opacity(unlocked ? 1.0 : 0.5)
                    }
                }
            }
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let ms = Int(time * 1000)
        let m  = ms / 60000
        let s  = (ms % 60000) / 1000
        let cs = (ms % 1000) / 10
        return String(format: "%d:%02d.%02d", m, s, cs)
    }
}

#Preview {
    StatisticsView()
}
