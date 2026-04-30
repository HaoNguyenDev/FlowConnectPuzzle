//
//  ToastModifier.swift
//  FlowConnectPuzzle
//

import SwiftUI

// MARK: - Toast ViewModifier

struct ToastModifier: ViewModifier {
    let message: String
    let systemImage: String
    let imageColor: Color
    @Binding var isShowing: Bool

    func body(content: Content) -> some View {
        ZStack(alignment: .bottom) {
            content
            if isShowing {
                HStack(spacing: 10) {
                    Image(systemName: systemImage)
                        .foregroundColor(imageColor)
                    Text(message)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.black.opacity(0.82))
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                .padding(.bottom, 40)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(999)
            }
        }
    }
}

// MARK: - View Extension

extension View {
    /// Shows a toast message at the bottom of the view.
    ///
    /// - Parameters:
    ///   - message: Text to display.
    ///   - systemImage: SF Symbol name (default: checkmark.circle.fill).
    ///   - imageColor: Icon tint color (default: .green).
    ///   - isShowing: Binding that controls visibility.
    ///     Set to `true` to show; the caller is responsible for resetting it.
    func toast(
        _ message: String,
        systemImage: String = "checkmark.circle.fill",
        imageColor: Color = .green,
        isShowing: Binding<Bool>
    ) -> some View {
        modifier(ToastModifier(
            message: message,
            systemImage: systemImage,
            imageColor: imageColor,
            isShowing: isShowing
        ))
    }
}
