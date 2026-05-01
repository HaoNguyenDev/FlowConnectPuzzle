//
//  AppearanceMode.swift
//  FlowConnectPuzzle
//

import SwiftUI

enum AppearanceMode: String, CaseIterable, Identifiable {
    case light
    case dark
    case system

    var id: String { rawValue }

    /// Maps to SwiftUI's ColorScheme; nil means "follow the system".
    var preferredColorScheme: ColorScheme? {
        switch self {
        case .light:  return .light
        case .dark:   return .dark
        case .system: return nil
        }
    }

    var iconName: String {
        switch self {
        case .light:  return "sun.max.fill"
        case .dark:   return "moon.fill"
        case .system: return "circle.lefthalf.filled"
        }
    }

    var localizationKey: String {
        switch self {
        case .light:  return "settings.appearance_light"
        case .dark:   return "settings.appearance_dark"
        case .system: return "settings.appearance_system"
        }
    }
}

@Observable
class AppearanceManager {
    static let shared = AppearanceManager()

    // Stored property so @Observable tracks changes and triggers SwiftUI re-renders.
    var mode: AppearanceMode {
        didSet {
            UserDefaults.standard.set(mode.rawValue, forKey: "appearance_mode")
        }
    }

    /// Pass directly to `.preferredColorScheme()` on the root view.
    var preferredColorScheme: ColorScheme? { mode.preferredColorScheme }

    /// Explicit light palette — use when you need non-semantic colors in custom drawing.
    let lightScheme: any AppColorSchemeProtocol = LightAppColorScheme()
    /// Explicit dark palette — use when you need non-semantic colors in custom drawing.
    let darkScheme: any AppColorSchemeProtocol = DarkAppColorScheme()

    private init() {
        let saved = UserDefaults.standard.string(forKey: "appearance_mode") ?? "system"
        mode = AppearanceMode(rawValue: saved) ?? .system
    }
}
