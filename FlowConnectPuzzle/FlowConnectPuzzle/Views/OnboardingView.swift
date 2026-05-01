//
//  OnboardingView.swift
//  FlowConnectPuzzle
//

import SwiftUI

struct OnboardingView: View {
    @State private var step = 0
    @State private var lm = LocalizationManager.shared
    let onFinish: () -> Void

    private var steps: [(icon: String, title: String, body: String)] {
        [
            (
                "1.circle.fill",
                lm.t("onboarding.step1_title"),
                lm.t("onboarding.step1_body")
            ),
            (
                "arrow.up.and.down.and.arrow.left.and.right",
                lm.t("onboarding.step2_title"),
                lm.t("onboarding.step2_body")
            ),
            (
                "checkmark.seal.fill",
                lm.t("onboarding.step3_title"),
                lm.t("onboarding.step3_body")
            ),
            (
                "lightbulb.max.fill",
                lm.t("onboarding.step4_title"),
                lm.t("onboarding.step4_body")
            ),
        ]
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Image(systemName: steps[step].icon)
                .font(.system(size: 80))
                .foregroundStyle(.blue)
                .padding(.bottom, 32)
                .id(step)
                .transition(.scale.combined(with: .opacity))
                .animation(.spring(duration: 0.4), value: step)

            Text(steps[step].title)
                .font(.system(size: 26, weight: .bold))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.bottom, 16)
                .id("title_\(step)")
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.3), value: step)

            Text(steps[step].body)
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 40)
                .id("body_\(step)")
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.3), value: step)

            Spacer()

            // Step indicator dots
            HStack(spacing: 8) {
                ForEach(0..<steps.count, id: \.self) { i in
                    Circle()
                        .fill(i == step ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut, value: step)
                }
            }
            .padding(.bottom, 32)

            // Navigation buttons
            HStack(spacing: 16) {
                if step < steps.count - 1 {
                    Button(lm.t("onboarding.skip")) { onFinish() }
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)

                    Button {
                        withAnimation { step += 1 }
                    } label: {
                        Text(lm.t("onboarding.next"))
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                } else {
                    Button {
                        onFinish()
                    } label: {
                        Text(lm.t("onboarding.get_started"))
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
    }
}

#Preview {
    OnboardingView(onFinish: {})
}
