//
//  OnboardingView.swift
//  FlowConnectPuzzle
//

import SwiftUI

struct OnboardingView: View {
    @State private var step = 0
    let onFinish: () -> Void

    private let steps: [(icon: String, title: String, body: String)] = [
        (
            "1.circle.fill",
            "Connect the Numbers",
            "Start from 1 and draw a continuous path to connect all numbers in order: 1 → 2 → 3 → …"
        ),
        (
            "arrow.up.and.down.and.arrow.left.and.right",
            "Draw Your Path",
            "Drag your finger through adjacent cells. You can only move up, down, left, or right — no diagonals!"
        ),
        (
            "checkmark.seal.fill",
            "Fill the Grid",
            "Your path must visit every cell on the grid. Connect all numbers in sequence to win!"
        ),
        (
            "lightbulb.max.fill",
            "Use Your Tools",
            "Hint glows the next number. Undo steps back (costs +3 s). Reset replays the same puzzle. New generates a fresh one."
        ),
    ]

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
                .foregroundColor(.secondary)
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
                    Button("Skip") { onFinish() }
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)

                    Button {
                        withAnimation { step += 1 }
                    } label: {
                        Text("Next")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.blue)
                            .cornerRadius(14)
                    }
                } else {
                    Button {
                        onFinish()
                    } label: {
                        Text("Let's Play!")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.blue)
                            .cornerRadius(14)
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
