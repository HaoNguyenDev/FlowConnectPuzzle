//
//  NotificationManager.swift
//  FlowConnectPuzzle
//

import Foundation
import UserNotifications

@Observable
class NotificationManager {
    static let shared = NotificationManager()

    var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: "notifications_enabled")
            if isEnabled {
                scheduleReminders()
            } else {
                cancelReminders()
            }
        }
    }

    private init() {
        isEnabled = UserDefaults.standard.bool(forKey: "notifications_enabled")
    }

    /// Request system notification permission. Sets isEnabled to true if granted.
    func requestPermission() async {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run {
                if granted && !isEnabled {
                    isEnabled = true   // didSet will call scheduleReminders()
                } else if !granted {
                    isEnabled = false
                }
            }
        } catch {
            await MainActor.run { isEnabled = false }
        }
    }

    func scheduleReminders() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["daily_morning", "daily_evening"])

        // 8:00 AM — fresh puzzle reminder
        let morningContent = UNMutableNotificationContent()
        morningContent.title = "Daily Challenge Ready! 🧩"
        morningContent.body = "A new puzzle awaits. Keep your streak alive today!"
        morningContent.sound = .default
        var morningComps = DateComponents()
        morningComps.hour = 8; morningComps.minute = 0
        center.add(UNNotificationRequest(
            identifier: "daily_morning",
            content: morningContent,
            trigger: UNCalendarNotificationTrigger(dateMatching: morningComps, repeats: true)
        ))

        // 8:00 PM — streak protection reminder
        let eveningContent = UNMutableNotificationContent()
        eveningContent.title = "Don't break your streak! 🔥"
        eveningContent.body = "You haven't solved today's challenge yet. A few minutes is all it takes."
        eveningContent.sound = .default
        var eveningComps = DateComponents()
        eveningComps.hour = 20; eveningComps.minute = 0
        center.add(UNNotificationRequest(
            identifier: "daily_evening",
            content: eveningContent,
            trigger: UNCalendarNotificationTrigger(dateMatching: eveningComps, repeats: true)
        ))
    }

    func cancelReminders() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["daily_morning", "daily_evening"])
    }
}
