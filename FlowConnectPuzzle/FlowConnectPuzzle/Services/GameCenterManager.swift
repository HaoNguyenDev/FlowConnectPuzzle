//
//  GameCenterManager.swift
//  FlowConnectPuzzle
//

import Foundation
import GameKit

/// Leaderboard IDs — must match entries in App Store Connect.
enum Leaderboard {
    static let bestTimeEasy     = "com.flowconnect.best_time_easy"
    static let bestTimeMedium   = "com.flowconnect.best_time_medium"
    static let bestTimeHard     = "com.flowconnect.best_time_hard"
    static let bestTimeVeryHard = "com.flowconnect.best_time_veryhard"
    static let bestTimeExpert   = "com.flowconnect.best_time_expert"
    static let totalXP          = "com.flowconnect.total_xp"

    static func id(for difficulty: Difficulty) -> String {
        switch difficulty {
        case .easy:     return bestTimeEasy
        case .medium:   return bestTimeMedium
        case .hard:     return bestTimeHard
        case .veryHard: return bestTimeVeryHard
        case .expert:   return bestTimeExpert
        }
    }
}

@Observable
class GameCenterManager {
    static let shared = GameCenterManager()

    var isAuthenticated = false

    private init() {}

    /// Call from FlowConnectPuzzleApp or ContentView.onAppear to authenticate.
    func authenticate() {
        GKLocalPlayer.local.authenticateHandler = { [weak self] _, error in
            DispatchQueue.main.async {
                self?.isAuthenticated = GKLocalPlayer.local.isAuthenticated
                if self?.isAuthenticated == true {
                    self?.submitPendingScores()
                }
            }
        }
    }

    /// Submit best time (in milliseconds) for a given difficulty.
    func submitBestTime(_ time: TimeInterval, for difficulty: Difficulty) {
        guard isAuthenticated else { return }
        let ms = Int(time * 1000)
        GKLeaderboard.submitScore(ms, context: 0, player: GKLocalPlayer.local, leaderboardIDs: [Leaderboard.id(for: difficulty)]) { _ in }
    }

    /// Submit total XP to the global XP leaderboard.
    func submitXP(_ xp: Int) {
        guard isAuthenticated else { return }
        GKLeaderboard.submitScore(xp, context: 0, player: GKLocalPlayer.local, leaderboardIDs: [Leaderboard.totalXP]) { _ in }
    }

    private func submitPendingScores() {
        let stats = StatisticsManager.shared
        for difficulty in Difficulty.allCases {
            if let best = stats.bestTime(for: difficulty) {
                submitBestTime(best, for: difficulty)
            }
        }
        submitXP(ProgressionManager.shared.totalXP)
    }
}
