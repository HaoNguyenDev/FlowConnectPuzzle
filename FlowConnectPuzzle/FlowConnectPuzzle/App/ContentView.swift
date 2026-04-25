//
//  ContentView.swift
//  FlowConnectPuzzle
//
//  Created by Steven Tran on 18/4/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedDifficulty: Difficulty?
    @State private var isDailyGame = false
    @State private var showStats = false
    @State private var showSettings = false
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "onboarding_done")
    @State private var stats = StatisticsManager.shared
    @State private var themeManager = ThemeManager.shared

    var body: some View {
        Group {
            if showOnboarding {
                OnboardingView {
                    UserDefaults.standard.set(true, forKey: "onboarding_done")
                    showOnboarding = false
                }
            } else if let difficulty = selectedDifficulty {
                PuzzleGameView(
                    difficulty: difficulty,
                    isDaily: isDailyGame,
                    onBack: {
                        selectedDifficulty = nil
                        isDailyGame = false
                    }
                )
            } else {
                difficultySelectionView
            }
        }
    }

    // MARK: - Difficulty Selection

    private var difficultySelectionView: some View {
        VStack(spacing: 0) {
            // Top bar
            HStack {
                Text("Flow Connect")
                    .font(.system(size: 28, weight: .bold))
                Spacer()
                HStack(spacing: 8) {
                    Button {
                        showStats = true
                    } label: {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.primary)
                            .padding(10)
                            .background(Color(uiColor: .systemBackground))
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.07), radius: 4, x: 0, y: 2)
                    }
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.primary)
                            .padding(10)
                            .background(Color(uiColor: .systemBackground))
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.07), radius: 4, x: 0, y: 2)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 8)

            ScrollView {
                VStack(spacing: 24) {
                    // Daily Challenge card
                    dailyChallengeCard
                        .padding(.horizontal, 24)
                        .padding(.top, 8)

                    // Difficulty list
                    VStack(spacing: 0) {
                        Text("Select Difficulty")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 8)

                        VStack(spacing: 12) {
                            ForEach(Difficulty.allCases) { difficulty in
                                difficultyRow(difficulty)
                            }
                        }
                        .padding(.horizontal, 24)
                    }

                    Spacer(minLength: 32)
                }
            }
        }
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
        .sheet(isPresented: $showStats) { StatisticsView() }
        .sheet(isPresented: $showSettings) { settingsSheet }
    }

    // MARK: - Daily Challenge Card

    private var dailyChallengeCard: some View {
        let completed = DailyChallenge.isCompletedToday
        return Button {
            if !completed {
                isDailyGame = true
                selectedDifficulty = DailyChallenge.todayDifficulty
            }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(completed ? Color.green.opacity(0.15) : Color.blue.opacity(0.12))
                        .frame(width: 52, height: 52)
                    Image(systemName: completed ? "checkmark.circle.fill" : "calendar")
                        .font(.system(size: 24))
                        .foregroundColor(completed ? .green : .blue)
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text("Daily Challenge")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.primary)
                        if completed {
                            Text("Done")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2)
                                .background(Color.green)
                                .cornerRadius(6)
                        }
                    }
                    Text(DailyChallenge.formattedDate)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    Text(DailyChallenge.todayDifficulty.description)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                Spacer()

                if !completed {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)
            .background(Color(uiColor: .systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
        .disabled(completed)
    }

    // MARK: - Difficulty Row

    private func difficultyRow(_ difficulty: Difficulty) -> some View {
        Button {
            isDailyGame = false
            selectedDifficulty = difficulty
        } label: {
            HStack(spacing: 14) {
                Image(systemName: difficulty.iconName)
                    .font(.title2)
                    .foregroundColor(themeManager.current.pathColor)
                    .frame(width: 36)

                VStack(alignment: .leading, spacing: 3) {
                    Text(difficulty.displayName)
                        .font(.system(size: 17, weight: .semibold))
                    Text(difficulty.description)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Personal best time
                if let best = stats.bestTime(for: difficulty) {
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("Best")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                        Text(formatTime(best))
                            .font(.system(size: 13, weight: .semibold).monospacedDigit())
                            .foregroundColor(themeManager.current.pathColor)
                    }
                    .padding(.trailing, 4)
                }

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.system(size: 14))
            }
            .foregroundColor(.primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color(uiColor: .systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Settings Sheet

    private var settingsSheet: some View {
        NavigationView {
            List {
                Section("Theme") {
                    ForEach(GameTheme.all) { theme in
                        Button {
                            themeManager.current = theme
                        } label: {
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(theme.pathColor)
                                    .frame(width: 22, height: 22)
                                Text(theme.name)
                                    .foregroundColor(.primary)
                                Spacer()
                                if themeManager.current == theme {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                        .fontWeight(.semibold)
                                }
                            }
                        }
                    }
                }

                Section("Tutorial") {
                    Button("Show Onboarding Again") {
                        showSettings = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showOnboarding = true
                        }
                    }
                    .foregroundColor(.blue)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { showSettings = false }
                }
            }
        }
    }

    // MARK: - Helpers

    private func formatTime(_ time: TimeInterval) -> String {
        let ms = Int(time * 1000)
        let m  = ms / 60000
        let s  = (ms % 60000) / 1000
        let cs = (ms % 1000) / 10
        return String(format: "%d:%02d.%02d", m, s, cs)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
