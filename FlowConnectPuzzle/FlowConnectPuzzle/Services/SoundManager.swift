//
//  SoundManager.swift
//  FlowConnectPuzzle
//

import Foundation
import AudioToolbox

@Observable
class SoundManager {
    static let shared = SoundManager()

    var isEnabled: Bool {
        didSet { UserDefaults.standard.set(isEnabled, forKey: "sound_enabled") }
    }

    private init() {
        // Default to enabled
        let ud = UserDefaults.standard
        isEnabled = ud.object(forKey: "sound_enabled") == nil ? true : ud.bool(forKey: "sound_enabled")
    }

    func playTap() {
        guard isEnabled else { return }
        AudioServicesPlaySystemSound(1104)
    }

    func playStep() {
        guard isEnabled else { return }
        AudioServicesPlaySystemSound(1157)
    }

    func playComplete() {
        guard isEnabled else { return }
        // Positive completion chime
        AudioServicesPlaySystemSound(1033)
    }

    func playUndo() {
        guard isEnabled else { return }
        AudioServicesPlaySystemSound(1073)
    }

    func playError() {
        guard isEnabled else { return }
        AudioServicesPlaySystemSound(1073)
    }
}
