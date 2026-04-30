import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case english           = "en"
    case vietnamese        = "vi"
    case spanish           = "es"
    case french            = "fr"
    case german            = "de"
    case japanese          = "ja"
    case chineseSimplified = "zh-Hans"
    case portuguese        = "pt"
    case korean            = "ko"

    var id: String { rawValue }

    /// Filename used for the .strings resource (hyphens replaced with underscores).
    var stringsFileName: String {
        rawValue.replacingOccurrences(of: "-", with: "_")
    }

    var displayName: String {
        switch self {
        case .english:           return "English"
        case .vietnamese:        return "Tiếng Việt"
        case .spanish:           return "Español"
        case .french:            return "Français"
        case .german:            return "Deutsch"
        case .japanese:          return "日本語"
        case .chineseSimplified: return "简体中文"
        case .portuguese:        return "Português"
        case .korean:            return "한국어"
        }
    }

    var flagEmoji: String {
        switch self {
        case .english:           return "🇺🇸"
        case .vietnamese:        return "🇻🇳"
        case .spanish:           return "🇪🇸"
        case .french:            return "🇫🇷"
        case .german:            return "🇩🇪"
        case .japanese:          return "🇯🇵"
        case .chineseSimplified: return "🇨🇳"
        case .portuguese:        return "🇧🇷"
        case .korean:            return "🇰🇷"
        }
    }
}

/// Loads translations from .strings files at runtime and triggers SwiftUI re-renders on language change.
/// Each language has a corresponding file in Localizations/ (e.g. en.strings, vi.strings).
/// Missing keys fall back to English automatically.
@Observable
class LocalizationManager {
    static let shared = LocalizationManager()

    var language: AppLanguage {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: "selected_language")
            loadStrings(for: language)
        }
    }

    private var strings: [String: String] = [:]
    private var englishStrings: [String: String] = [:]

    private init() {
        if let saved = UserDefaults.standard.string(forKey: "selected_language"),
           let lang = AppLanguage(rawValue: saved) {
            language = lang
        } else {
            let code = Locale.current.language.languageCode?.identifier ?? "en"
            language = AppLanguage.allCases.first { $0.rawValue == code } ?? .english
        }
        englishStrings = Self.load(AppLanguage.english.stringsFileName)
        loadStrings(for: language)
    }

    private func loadStrings(for lang: AppLanguage) {
        let loaded = Self.load(lang.stringsFileName)
        strings = lang == .english ? loaded : englishStrings.merging(loaded) { _, new in new }
    }

    private static func load(_ fileName: String) -> [String: String] {
        guard let path = Bundle.main.path(forResource: fileName, ofType: "strings"),
              let dict = NSDictionary(contentsOfFile: path) as? [String: String]
        else { return [:] }
        return dict
    }

    // MARK: - Lookup

    func t(_ key: String) -> String {
        strings[key] ?? englishStrings[key] ?? key
    }

    func difficultyName(_ difficulty: Difficulty) -> String {
        t("difficulty.\(difficulty.rawValue)")
    }

    func achievementTitle(_ id: String) -> String {
        t("achievement.\(id).title")
    }

    func achievementDesc(_ id: String) -> String {
        t("achievement.\(id).desc")
    }

    func streakText(_ count: Int) -> String {
        count == 1 ? t("stats.streak_singular") : String(format: t("stats.streak_plural"), count)
    }

    func daysText(_ count: Int) -> String {
        count == 1 ? t("stats.day_singular") : String(format: t("stats.days_plural"), count)
    }
}
