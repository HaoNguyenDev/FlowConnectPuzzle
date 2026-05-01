//
//  AppAlertView.swift
//  FlowConnectPuzzle
//

import SwiftUI

struct AppAlertView: View {
    let icon: String?
    let iconColor: Color
    let title: String
    let message: String
    let confirmLabel: String
    let cancelLabel: String
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            if let icon {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.12))
                        .frame(width: 64, height: 64)
                    Image(systemName: icon)
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(iconColor)
                }
            }

            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .multilineTextAlignment(.center)
                Text(message)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 12) {
                Button(cancelLabel, action: onCancel)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(Color(uiColor: .systemFill))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(.primary)
                    .font(.system(size: 15, weight: .medium))

                Button(confirmLabel, action: onConfirm)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(iconColor)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(.white)
                    .font(.system(size: 15, weight: .semibold))
            }
        }
        .padding(24)
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.2), radius: 24, x: 0, y: 10)
        .padding(.horizontal, 32)
    }
}

private struct AppAlertModifier: ViewModifier {
    @Binding var isPresented: Bool
    let icon: String?
    let iconColor: Color
    let title: String
    let message: String
    let confirmLabel: String
    let cancelLabel: String
    let onConfirm: () -> Void

    @State private var isVisible = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .overlay {
                if isPresented {
                    ZStack {
                        Color.black
                            .opacity(isVisible ? 0.45 : 0)
                            .ignoresSafeArea()

                        AppAlertView(
                            icon: icon,
                            iconColor: iconColor,
                            title: title,
                            message: message,
                            confirmLabel: confirmLabel,
                            cancelLabel: cancelLabel,
                            onConfirm: {
                                onConfirm()
                                hide()
                            },
                            onCancel: { hide() }
                        )
                        .scaleEffect(isVisible ? 1 : (reduceMotion ? 1 : 0.86))
                        .opacity(isVisible ? 1 : 0)
                    }
                    .onAppear {
                        withAnimation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.8)) {
                            isVisible = true
                        }
                    }
                }
            }
    }

    private func hide() {
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.18)) {
            isVisible = false
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(180))
            isPresented = false
        }
    }
}

extension View {
    func appAlert(
        isPresented: Binding<Bool>,
        icon: String? = nil,
        iconColor: Color = .red,
        title: String,
        message: String,
        confirmLabel: String,
        cancelLabel: String,
        onConfirm: @escaping () -> Void
    ) -> some View {
        modifier(AppAlertModifier(
            isPresented: isPresented,
            icon: icon,
            iconColor: iconColor,
            title: title,
            message: message,
            confirmLabel: confirmLabel,
            cancelLabel: cancelLabel,
            onConfirm: onConfirm
        ))
    }
}
