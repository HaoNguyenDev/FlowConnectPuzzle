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
    @State private var lm = LocalizationManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                // MARK: Progression
                Section(lm.t("stats.progression")) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(String(format: lm.t("stats.level"), progression.level + 1, progression.levelName))
                                    .font(.system(size: 16, weight: .bold))
                                if let nextXP = progression.xpForNextLevel {
                                    Text(String(format: lm.t("stats.xp_to_next"), nextXP - progression.totalXP, ProgressionManager.levelNames[progression.level + 1]))
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                } else {
                                    Text(lm.t("stats.max_level"))
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
                Section(lm.t("stats.calendar_header")) {
                    StreakCalendarView()
                        .padding(.vertical, 4)
                }

                // MARK: Daily Streak
                Section(lm.t("stats.streak")) {
                    HStack {
                        Label(lm.t("stats.current_streak"), systemImage: "flame.fill")
                            .foregroundColor(.orange)
                        Spacer()
                        Text(lm.daysText(streak.currentStreak))
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Label(lm.t("stats.best_streak"), systemImage: "trophy.fill")
                            .foregroundColor(.yellow)
                        Spacer()
                        Text(lm.daysText(streak.bestStreak))
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Label(lm.t("game.daily_challenge"), systemImage: "calendar.badge.checkmark")
                            .foregroundColor(.blue)
                        Spacer()
                        Text("\(streak.totalDailySolves) \(lm.t("timetrial.solved").lowercased())")
                            .foregroundColor(.secondary)
                    }
                }

                // MARK: Best Times
                Section(lm.t("stats.best_times")) {
                    ForEach(Difficulty.allCases) { difficulty in
                        HStack {
                            Image(systemName: difficulty.iconName)
                                .foregroundColor(.blue)
                                .frame(width: 28)
                            Text(lm.difficultyName(difficulty))
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
                Section(lm.t("stats.puzzles_solved")) {
                    ForEach(Difficulty.allCases) { difficulty in
                        HStack {
                            Image(systemName: difficulty.iconName)
                                .foregroundColor(.blue)
                                .frame(width: 28)
                            Text(lm.difficultyName(difficulty))
                            Spacer()
                            Text("\(stats.solveCount(for: difficulty))")
                                .foregroundColor(.secondary)
                        }
                    }
                    HStack {
                        Text(lm.t("stats.total"))
                            .fontWeight(.semibold)
                        Spacer()
                        Text("\(stats.totalSolveCount)")
                            .fontWeight(.semibold)
                    }
                }

                // MARK: Achievements
                Section("\(lm.t("stats.achievements")) (\(achievements.unlocked.count)/\(achievements.all.count))") {
                    ForEach(achievements.all) { achievement in
                        let unlocked = achievements.isUnlocked(achievement)
                        HStack(spacing: 12) {
                            Image(systemName: achievement.iconName)
                                .font(.system(size: 20))
                                .foregroundColor(unlocked ? .yellow : .gray.opacity(0.3))
                                .frame(width: 32)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(lm.achievementTitle(achievement.id))
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(unlocked ? .primary : .secondary)
                                Text(lm.achievementDesc(achievement.id))
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
            .navigationTitle(lm.t("stats.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(lm.t("settings.done")) { dismiss() }
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
