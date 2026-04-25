//
//  StatisticsView.swift
//  FlowConnectPuzzle
//

import SwiftUI

struct StatisticsView: View {
    @State private var stats = StatisticsManager.shared
    @State private var achievements = AchievementManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
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
