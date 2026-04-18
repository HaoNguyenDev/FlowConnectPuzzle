//
//  HapticManager.swift
//  FlowConnectPuzzle
//
//  Created by Hao Nguyen on 17/04/2026.
//

import UIKit

/// Centralized haptic feedback for game interactions.
///
/// ```
/// ┌─────────────────────────────┬──────────────────┬──────────────────────────┬───────────────────────────────┐
/// │ Action                      │ Method           │ Haptic Style             │ Feel                          │
/// ├─────────────────────────────┼──────────────────┼──────────────────────────┼───────────────────────────────┤
/// │ Drag through empty cell     │ pathAdded()      │ Light impact             │ Subtle tick per cell          │
/// │ Reach next number (2, 3...) │ numberReached()  │ Medium impact            │ Clear confirmation bump       │
/// │ Invalid move (wrong seq.)   │ invalidMove()    │ Notification error       │ Shake / buzz warning          │
/// │ Backtrack over path         │ undo()           │ Selection changed        │ Soft click                    │
/// │ Reset game                  │ reset()          │ Medium impact            │ Medium bump                   │
/// │ Win (connect all 1→9)       │ completed()      │ Heavy → Success → Medium │ Triple celebration sequence   │
/// └─────────────────────────────┴──────────────────┴──────────────────────────┴───────────────────────────────┘
/// ```
class HapticManager {
    static let shared = HapticManager()
    
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let notificationGenerator = UINotificationFeedbackGenerator()
    private let selectionGenerator = UISelectionFeedbackGenerator()
    
    private init() {
        // Prepare generators
        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
        notificationGenerator.prepare()
        selectionGenerator.prepare()
    }
    
    func pathAdded() {
        impactLight.impactOccurred()
    }
    
    func numberReached() {
        impactMedium.impactOccurred()
    }
    
    func invalidMove() {
        notificationGenerator.notificationOccurred(.error)
    }
    
    func completed() {
        // Celebration haptic sequence
        impactHeavy.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [self] in
            notificationGenerator.notificationOccurred(.success)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [self] in
            impactMedium.impactOccurred()
        }
    }
    
    func reset() {
        impactMedium.impactOccurred()
    }
    
    func undo() {
        selectionGenerator.selectionChanged()
    }
}

