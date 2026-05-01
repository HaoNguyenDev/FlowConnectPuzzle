//
//  AchievementBannerView.swift
//  FlowConnectPuzzle
//

import SwiftUI

struct AchievementBannerView: View {
    let achievement: Achievement
    let onDismiss: () -> Void

    @State private var lm = LocalizationManager.shared

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: achievement.iconName)
                .font(.system(size: 26))
                .foregroundStyle(.yellow)

            VStack(alignment: .leading, spacing: 2) {
                Text(lm.t("achievement.unlocked"))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.7))
                Text(lm.achievementTitle(achievement.id))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                Text(lm.achievementDesc(achievement.id))
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(1)
            }

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.88))
                .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 4)
        )
        .padding(.horizontal, 16)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}
