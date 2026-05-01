//
//  ChallengeFriendView.swift
//  FlowConnectPuzzle
//

import SwiftUI

/// Allows the user to share a puzzle seed with friends as a 6-character code.
struct ChallengeFriendView: View {
    @State private var inputCode = ""
    @State private var generatedCode = ""
    @State private var selectedDifficulty: Difficulty = .medium
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var codeCopied = false
    @State private var themeManager = ThemeManager.shared
    @State private var lm = LocalizationManager.shared
    @Environment(\.dismiss) private var dismiss

    let onStartChallenge: (GameMode) -> Void

    var body: some View {
        NavigationStack {
            List {
                // Share a puzzle
                Section(lm.t("challenge.title")) {
                    Picker(lm.t("challenge.difficulty_label"), selection: $selectedDifficulty) {
                        ForEach(Difficulty.allCases) { d in
                            Text(lm.difficultyName(d)).tag(d)
                        }
                    }

                    Button(action: generateCode) {
                        Label(lm.t("challenge.your_code"), systemImage: "square.and.arrow.up")
                    }
                    .foregroundStyle(themeManager.current.pathColor)

                    if !generatedCode.isEmpty {
                        HStack {
                            Text(lm.t("challenge.your_code"))
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(generatedCode)
                                .font(.system(size: 22, weight: .bold).monospaced())
                                .foregroundStyle(themeManager.current.pathColor)
                            Button {
                                UIPasteboard.general.string = generatedCode
                                withAnimation(.spring(duration: 0.35)) {
                                    codeCopied = true
                                }
                                Task {
                                    try? await Task.sleep(for: .seconds(2))
                                    withAnimation(.easeOut(duration: 0.25)) {
                                        codeCopied = false
                                    }
                                }
                            } label: {
                                Image(systemName: codeCopied ? "checkmark.circle.fill" : "doc.on.doc")
                                    .font(.system(size: 18))
                                    .foregroundStyle(codeCopied ? .green : themeManager.current.pathColor)
                            }
                            .buttonStyle(.plain)
                            .animation(.easeInOut(duration: 0.2), value: codeCopied)
                        }

                        ShareLink(
                            item: "Try this Flow Connect puzzle! Use code \(generatedCode) to play the same puzzle. 🧩",
                            subject: Text("Flow Connect Challenge")
                        ) {
                            Label(lm.t("challenge.share_code"), systemImage: "square.and.arrow.up")
                        }
                        .foregroundStyle(.blue)
                    }
                }

                // Accept a challenge
                Section(lm.t("challenge.accept_title")) {
                    HStack {
                        TextField(lm.t("challenge.enter_code"), text: $inputCode)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .onChange(of: inputCode) { _, v in
                                inputCode = String(v.uppercased().filter { $0.isLetter || $0.isNumber }.prefix(6))
                            }

                        if inputCode.count == 6 {
                            Button(lm.t("timetrial.start")) {
                                if let mode = decode(code: inputCode) {
                                    dismiss()
                                    onStartChallenge(mode)
                                } else {
                                    alertMessage = lm.t("challenge.invalid_message")
                                    showAlert = true
                                }
                            }
                            .fontWeight(.semibold)
                            .foregroundStyle(themeManager.current.pathColor)
                        }
                    }
                }

                Section {
                    Text(lm.t("challenge.instructions"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(lm.t("challenge.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(lm.t("challenge.done")) { dismiss() }
                }
            }
            .alert(lm.t("challenge.invalid_title"), isPresented: $showAlert) {
                Button(lm.t("challenge.ok"), role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
        }
        .toast(lm.t("challenge.copied"), isShowing: $codeCopied)
    }

    // MARK: - Code Generation

    /// Encodes a seed + difficulty into a 6-character alphanumeric code.
    private func generateCode() {
        let seed = generateChallengeSeed()
        let diffIndex = Difficulty.allCases.firstIndex(of: selectedDifficulty) ?? 0
        let packed = (seed & 0x0FFFFF) | (UInt64(diffIndex) << 20)
        generatedCode = encode(value: packed)
    }

    private func generateChallengeSeed() -> UInt64 {
        // Date-based seed so codes are unique each day but reproducible
        let c = Calendar.current
        let d = Date()
        let y = c.component(.year,  from: d)
        let m = c.component(.month, from: d)
        let day = c.component(.day, from: d)
        // Add a random 8-bit salt for variety
        let salt = UInt64.random(in: 0..<256)
        return UInt64(y * 10000 + m * 100 + day) * 256 + salt
    }

    /// Encodes a UInt64 to a 6-char base-36 string.
    private func encode(value: UInt64) -> String {
        let chars = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
        var v = value
        var result = ""
        for _ in 0..<6 {
            result = String(chars[Int(v % 36)]) + result
            v /= 36
        }
        return result
    }

    /// Decodes a 6-char code back to a GameMode, or nil if invalid.
    private func decode(code: String) -> GameMode? {
        guard code.count == 6 else { return nil }
        let chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        var value: UInt64 = 0
        for ch in code {
            guard let idx = chars.firstIndex(of: ch) else { return nil }
            value = value * 36 + UInt64(chars.distance(from: chars.startIndex, to: idx))
        }
        let diffIndex = Int((value >> 20) & 0x0F)
        let seed = value & 0x0FFFFF
        guard diffIndex < Difficulty.allCases.count else { return nil }
        let difficulty = Difficulty.allCases[diffIndex]
        return .challenge(difficulty, seed)
    }
}

#Preview {
    ChallengeFriendView(onStartChallenge: { _ in })
}
