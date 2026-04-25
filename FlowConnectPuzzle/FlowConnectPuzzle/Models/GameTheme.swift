//
//  GameTheme.swift
//  FlowConnectPuzzle
//

import SwiftUI

struct GameTheme: Identifiable, Equatable {
    let id: String
    let name: String
    let pathColor: Color
    let cellHighlightColor: Color
    let completedColor: Color
    let accentColor: Color

    static let ocean = GameTheme(
        id: "ocean", name: "Ocean",
        pathColor: .blue,
        cellHighlightColor: Color(red: 0.85, green: 0.93, blue: 1.0),
        completedColor: .green,
        accentColor: .cyan
    )

    static let sunset = GameTheme(
        id: "sunset", name: "Sunset",
        pathColor: .orange,
        cellHighlightColor: Color(red: 1.0, green: 0.93, blue: 0.85),
        completedColor: Color(red: 0.9, green: 0.3, blue: 0.1),
        accentColor: .yellow
    )

    static let forest = GameTheme(
        id: "forest", name: "Forest",
        pathColor: .green,
        cellHighlightColor: Color(red: 0.87, green: 0.97, blue: 0.87),
        completedColor: .mint,
        accentColor: Color(red: 0.2, green: 0.7, blue: 0.3)
    )

    static let cosmos = GameTheme(
        id: "cosmos", name: "Cosmos",
        pathColor: .purple,
        cellHighlightColor: Color(red: 0.93, green: 0.87, blue: 1.0),
        completedColor: .pink,
        accentColor: .indigo
    )

    static let all: [GameTheme] = [.ocean, .sunset, .forest, .cosmos]
}

@Observable
class ThemeManager {
    static let shared = ThemeManager()

    // Stored property so @Observable can track changes and trigger SwiftUI re-renders.
    var current: GameTheme {
        didSet {
            UserDefaults.standard.set(current.id, forKey: "selected_theme_id")
        }
    }

    private init() {
        let savedId = UserDefaults.standard.string(forKey: "selected_theme_id") ?? "ocean"
        current = GameTheme.all.first { $0.id == savedId } ?? .ocean
    }
}
