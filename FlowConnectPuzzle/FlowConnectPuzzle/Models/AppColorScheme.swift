//
//  AppColorScheme.swift
//  FlowConnectPuzzle
//

import SwiftUI

/// Defines the full color and typography palette for a given appearance (light or dark).
protocol AppColorSchemeProtocol {
    // MARK: - Backgrounds
    var pageBackground: Color { get }
    var groupedBackground: Color { get }
    var surface: Color { get }
    var elevatedSurface: Color { get }

    // MARK: - Text
    var primaryText: Color { get }
    var secondaryText: Color { get }
    var tertiaryText: Color { get }

    // MARK: - UI Elements
    var separator: Color { get }
    var destructive: Color { get }

    // MARK: - Typography
    var titleFont: Font { get }
    var headlineFont: Font { get }
    var bodyFont: Font { get }
    var subheadlineFont: Font { get }
    var captionFont: Font { get }
}

struct LightAppColorScheme: AppColorSchemeProtocol {
    let pageBackground    = Color(red: 0.949, green: 0.949, blue: 0.969) // #F2F2F7
    let groupedBackground = Color(red: 0.898, green: 0.898, blue: 0.918) // #E5E5EA
    let surface           = Color.white
    let elevatedSurface   = Color(white: 0.97)
    let primaryText       = Color(white: 0.0)
    let secondaryText     = Color(white: 0.42)
    let tertiaryText      = Color(white: 0.56)
    let separator         = Color(white: 0.78)
    let destructive       = Color.red

    let titleFont         = Font.system(size: 28, weight: .bold)
    let headlineFont      = Font.system(size: 17, weight: .semibold)
    let bodyFont          = Font.system(size: 16, weight: .regular)
    let subheadlineFont   = Font.system(size: 13, weight: .regular)
    let captionFont       = Font.system(size: 11, weight: .regular)
}

struct DarkAppColorScheme: AppColorSchemeProtocol {
    // Backgrounds — UIColor system background hierarchy (dark)
    let pageBackground    = Color(red: 0.110, green: 0.110, blue: 0.118) // systemGroupedBackground          #1C1C1E
    let groupedBackground = Color(red: 0.173, green: 0.173, blue: 0.180) // secondarySystemGroupedBackground  #2C2C2E
    let surface           = Color(red: 0.173, green: 0.173, blue: 0.180) // secondarySystemBackground         #2C2C2E
    let elevatedSurface   = Color(red: 0.227, green: 0.227, blue: 0.235) // tertiarySystemBackground          #3A3A3C

    // Text — UIColor label hierarchy (dark)
    let primaryText       = Color.white                                    // label
    let secondaryText     = Color(red: 0.557, green: 0.557, blue: 0.576) // secondaryLabel   #8E8E93
    let tertiaryText      = Color(red: 0.282, green: 0.282, blue: 0.290) // tertiaryLabel    #48484A

    // UI
    let separator         = Color(red: 0.220, green: 0.220, blue: 0.227) // opaqueSeparator  #38383A
    let destructive       = Color(red: 1.000, green: 0.271, blue: 0.227) // systemRed        #FF453A

    let titleFont         = Font.system(size: 28, weight: .bold)
    let headlineFont      = Font.system(size: 17, weight: .semibold)
    let bodyFont          = Font.system(size: 16, weight: .regular)
    let subheadlineFont   = Font.system(size: 13, weight: .regular)
    let captionFont       = Font.system(size: 11, weight: .regular)
}
