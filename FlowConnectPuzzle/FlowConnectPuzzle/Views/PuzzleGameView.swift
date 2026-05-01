//
//  PuzzleGameView.swift
//  FlowConnectPuzzle
//
//  Created by Hao Nguyen on 17/04/2026.
//

import SwiftUI
import Combine

struct PuzzleGameView: View {
    @State private var gameState: GameState
    @State private var ledPhase: Double = 0
    @State private var breathPhase: Bool = false
    @State private var hintActive: Bool = false
    @State private var elapsedTime: TimeInterval = 0
    @State private var timerActive: Bool = false
    @State private var lastUpdateTime: Date?
    @State private var isPersonalBest: Bool = false
    @State private var achievementManager = AchievementManager.shared
    @State private var themeManager = ThemeManager.shared
    @State private var streakManager = StreakManager.shared
    @State private var soundManager = SoundManager.shared
    @State private var showAchievementBanner: Bool = false
    /// Controls blur overlay — game only starts (and timer only ticks) after user taps Start.
    @State private var gameStarted: Bool = false
    @State private var lm = LocalizationManager.shared

    private let ledTimer  = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()
    private let gameTimer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()

    let mode: GameMode
    let onBack: () -> Void

    // Convenience shorthands so existing call-sites within the view need no changes
    private var difficulty: Difficulty { mode.difficulty }
    private var isDaily:   Bool { mode == .daily }
    private var isWeekly:  Bool { mode == .weekly }
    private var isZen:     Bool { mode.isZen }

    init(mode: GameMode, onBack: @escaping () -> Void) {
        self.mode = mode
        self.onBack = onBack
        if let seed = mode.seed {
            _gameState = State(initialValue: GameState(
                dailyDifficulty: mode.difficulty,
                seed: seed
            ))
        } else {
            _gameState = State(initialValue: GameState(difficulty: mode.difficulty))
        }
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Header: Back button - Difficulty - Timer
            HStack(spacing: 16) {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color(uiColor: .systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                }

                HStack(spacing: 6) {
                    if isDaily {
                        Image(systemName: "calendar")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(themeManager.current.pathColor)
                    } else if isWeekly {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.purple)
                    }
                    Text(isWeekly ? lm.t("game.weekly_challenge") : (isDaily ? lm.t("game.daily_challenge") : lm.difficultyName(difficulty)))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Timer display — hidden in zen mode
                if isZen {
                    HStack(spacing: 4) {
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.green.opacity(0.7))
                        Text(lm.t("game.zen"))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                            .font(.system(size: 14, weight: .medium))
                        Text(formattedTime)
                            .font(.system(size: 14, weight: .medium))
                            .monospacedDigit()
                    }
                    .foregroundStyle(.secondary)
                    .opacity(gameStarted ? 1.0 : 0.4)
                }
            }
            .padding(.horizontal, 16)

            puzzleGrid
                .padding(.horizontal, 16)

            // Action buttons
            HStack(spacing: 12) {
                // Undo
                Button(action: {
                    gameState.undo()
                    addTimePenalty()
                }) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color(uiColor: .systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                }
                .disabled(!gameStarted || gameState.path.isEmpty)
                .opacity(!gameStarted || gameState.path.isEmpty ? 0.4 : 1)
                .accessibilityLabel("Undo (adds 2 second penalty)")

                // Reset — shows start overlay again (timer pauses, keeps elapsed time as penalty)
                Button(action: {
                    gameState.reset()
                    pauseTimer()
                }) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color(uiColor: .systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                }
                .accessibilityLabel("Reset puzzle")

                // Hint
                Button(action: {
                    hintActive = true
                    startBreathing()
                }) {
                    Image(systemName: "lightbulb.max")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(hintActive ? .yellow : .primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color(uiColor: .systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                }
                .disabled(!gameStarted || gameState.allNumbersConnected || gameState.path.isEmpty)
                .opacity(!gameStarted || gameState.allNumbersConnected || gameState.path.isEmpty ? 0.4 : 1)
                .accessibilityLabel("Hint")

                // New puzzle (hidden during daily or weekly)
                if !isDaily && !isWeekly {
                    Button(action: {
                        gameState.newGame()
                        resetTimer()
                    }) {
                        Image(systemName: "plus.square")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color(uiColor: .systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                    }
                    .accessibilityLabel("New puzzle")
                }
            }

            Spacer()
        }
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
        .overlay {
            if gameState.allNumbersConnected {
                completionOverlay
            }
        }
        .overlay(alignment: .top) {
            if showAchievementBanner, let achievement = achievementManager.recentlyUnlocked {
                AchievementBannerView(achievement: achievement) {
                    withAnimation { showAchievementBanner = false }
                    achievementManager.clearRecentlyUnlocked()
                }
                .padding(.top, 16)
            }
        }
    }

    // MARK: - Puzzle Grid

    private var puzzleGrid: some View {
        GeometryReader { geometry in
            let totalSize = geometry.size.width
            let cellSize  = totalSize / CGFloat(gameState.gridSize)

            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(uiColor: .systemBackground))
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)

                VStack(spacing: 0) {
                    ForEach(0..<gameState.gridSize, id: \.self) { row in
                        HStack(spacing: 0) {
                            ForEach(0..<gameState.gridSize, id: \.self) { col in
                                cellView(row: row, col: col, cellSize: cellSize)
                            }
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))

                Canvas { context, _ in
                    drawPath(in: context, cellSize: cellSize)
                }
                .allowsHitTesting(false)

                numberBadgesOverlay(cellSize: cellSize)
                    .allowsHitTesting(false)

                // Start overlay — blur + Start button, shown before game begins
                if !gameStarted {
                    startOverlay(totalSize: totalSize)
                }
            }
            .frame(width: totalSize, height: totalSize)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in handleDrag(at: value.location, cellSize: cellSize) }
                    .onEnded { _ in }
            )
        }
        .aspectRatio(1, contentMode: .fit)
        .onReceive(ledTimer) { _ in
            ledPhase = (ledPhase + 1.5).truncatingRemainder(dividingBy: 360)
        }
        .onReceive(gameTimer) { currentTime in
            // Timer only ticks when game has been started AND is still active
            if timerActive && gameStarted && !gameState.allNumbersConnected {
                if let lastTime = lastUpdateTime {
                    elapsedTime += currentTime.timeIntervalSince(lastTime)
                }
                lastUpdateTime = currentTime
            } else if !gameStarted {
                // Reset anchor so there's no time jump when Start is pressed
                lastUpdateTime = nil
            }
        }
        .onAppear {
            startBreathing()
            elapsedTime = 0
            timerActive = false
            lastUpdateTime = nil
            gameStarted = false
        }
        .onChange(of: gameState.currentNumber) { _, _ in hintActive = false }
        .onChange(of: gameState.allNumbersConnected) { _, newValue in
            if newValue {
                timerActive = false
                lastUpdateTime = nil
                handleCompletion()
            }
        }
        .onChange(of: achievementManager.recentlyUnlocked) { _, newValue in
            if newValue != nil {
                withAnimation(.spring()) { showAchievementBanner = true }
                Task {
                    try? await Task.sleep(for: .seconds(4))
                    withAnimation { showAchievementBanner = false }
                    achievementManager.clearRecentlyUnlocked()
                }
            }
        }
    }

    // MARK: - Start Overlay

    private func startOverlay(totalSize: CGFloat) -> some View {
        let theme = themeManager.current
        return ZStack {
            // Frosted glass blur covers the entire grid
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)

            VStack(spacing: 20) {
                // Difficulty icon
                ZStack {
                    Circle()
                        .fill(theme.pathColor.opacity(0.15))
                        .frame(width: 72, height: 72)
                    Image(systemName: isWeekly ? "crown.fill" : (isDaily ? "calendar" : difficulty.iconName))
                        .font(.system(size: 32))
                        .foregroundStyle(isWeekly ? .purple : theme.pathColor)
                }

                VStack(spacing: 6) {
                    Text(isWeekly ? lm.t("game.weekly_challenge") : (isDaily ? lm.t("game.daily_challenge") : lm.difficultyName(difficulty)))
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.primary)
                    Text(difficulty.description)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                    if elapsedTime > 0 {
                        // Shown on re-start after Reset — displays accumulated penalty time
                        Text(String(format: lm.t("game.time_so_far"), formattedTime))
                            .font(.system(size: 12, weight: .medium).monospacedDigit())
                            .foregroundStyle(theme.pathColor)
                            .padding(.top, 2)
                    }
                }

                // Start button
                Button(action: startGame) {
                    HStack(spacing: 10) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 16))
                        Text(elapsedTime > 0 ? lm.t("game.resume") : lm.t("game.start"))
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 14)
                    .background(theme.pathColor)
                    .clipShape(RoundedRectangle(cornerRadius: 28))
                    .shadow(color: theme.pathColor.opacity(0.4), radius: 10, x: 0, y: 4)
                }
            }
        }
        .frame(width: totalSize, height: totalSize)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .transition(.opacity.combined(with: .scale(scale: 0.97)))
    }

    // MARK: - Completion Handling

    private func handleCompletion() {
        soundManager.playComplete()

        // Zen completions don't update personal best (no time pressure)
        let recorded = StatisticsManager.shared.recordCompletion(
            difficulty: difficulty,
            time: elapsedTime,
            usedUndo: gameState.usedUndo
        )
        isPersonalBest = recorded && !isZen

        if isWeekly {
            WeeklyChallenge.isCompletedThisWeek = true
        }
        if isDaily {
            StreakManager.shared.recordDailyCompletion()
            DailyChallenge.isCompletedToday = true
        }

        // Record XP — must run after StatisticsManager so isPersonalBest is known
        ProgressionManager.shared.recordCompletion(
            difficulty: difficulty,
            isPersonalBest: isPersonalBest,
            usedUndo: gameState.usedUndo,
            isDaily: isDaily,
            isWeekly: isWeekly
        )

        // Submit to Game Center if a personal best was set
        if isPersonalBest {
            GameCenterManager.shared.submitBestTime(elapsedTime, for: difficulty)
        }
        GameCenterManager.shared.submitXP(ProgressionManager.shared.totalXP)

        // Must run after StreakManager + ProgressionManager so all counts are updated
        AchievementManager.shared.check(
            difficulty: difficulty,
            time: elapsedTime,
            usedUndo: gameState.usedUndo,
            isDaily: isDaily,
            isWeekly: isWeekly,
            isZen: isZen
        )
    }

    // MARK: - Timer Management

    private var formattedTime: String {
        let ms = Int(elapsedTime * 1000)
        let m  = ms / 60000
        let s  = (ms % 60000) / 1000
        let cs = (ms % 1000) / 10
        return String(format: "%d:%02d.%02d", m, s, cs)
    }

    /// Start game and begin counting time.
    private func startGame() {
        withAnimation(.easeOut(duration: 0.3)) {
            gameStarted = true
        }
        timerActive = true
        lastUpdateTime = Date()
    }

    /// Reset elapsed time to zero and show start overlay (for New Puzzle).
    private func resetTimer() {
        elapsedTime = 0
        timerActive = false
        lastUpdateTime = nil
        withAnimation(.easeOut(duration: 0.2)) {
            gameStarted = false
        }
    }

    /// Pause timer and show start overlay, keeping elapsed time (for Reset — penalty stays).
    private func pauseTimer() {
        timerActive = false
        lastUpdateTime = nil
        withAnimation(.easeOut(duration: 0.2)) {
            gameStarted = false
        }
    }

    private func addTimePenalty() {
        guard !isZen else { return }  // Zen mode has no undo penalty
        elapsedTime += 2.0
    }

    // MARK: - Cell View

    private func cellView(row: Int, col: Int, cellSize: CGFloat) -> some View {
        let cell  = gameState.grid[row][col]
        let theme = themeManager.current

        return Rectangle()
            .fill(cellBackground(for: cell, theme: theme))
            .border(Color.gray.opacity(0.15), width: 0.5)
            .frame(width: cellSize, height: cellSize)
            .accessibilityLabel(cellAccessibilityLabel(row: row, col: col, cell: cell))
    }

    private func cellBackground(for cell: GridCell, theme: GameTheme) -> Color {
        if gameState.allNumbersConnected && cell.isInPath {
            return theme.completedColor.opacity(0.12)
        } else if cell.isHighlighted {
            return theme.cellHighlightColor
        } else if cell.isInPath {
            return theme.pathColor.opacity(0.1)
        } else {
            return Color(uiColor: .systemBackground)
        }
    }

    private func cellAccessibilityLabel(row: Int, col: Int, cell: GridCell) -> String {
        if let number = cell.number {
            return "Number \(number)\(cell.isInPath ? ", connected" : "")"
        } else if cell.isInPath {
            return "Path at row \(row + 1), column \(col + 1)"
        } else {
            return "Empty cell at row \(row + 1), column \(col + 1)"
        }
    }

    // MARK: - Path Drawing

    private func drawPath(in context: GraphicsContext, cellSize: CGFloat) {
        let positions = gameState.path
        guard positions.count > 1 else { return }

        var linePath = Path()
        for i in 0..<positions.count {
            let pos = positions[i]
            let point = CGPoint(
                x: (CGFloat(pos.col) + 0.5) * cellSize,
                y: (CGFloat(pos.row) + 0.5) * cellSize
            )
            if i == 0 { linePath.move(to: point) }
            else       { linePath.addLine(to: point) }
        }

        let pathColor: Color = gameState.allNumbersConnected
            ? themeManager.current.completedColor
            : themeManager.current.pathColor.opacity(0.55)

        context.stroke(
            linePath,
            with: .color(pathColor),
            style: StrokeStyle(lineWidth: cellSize * 0.25, lineCap: .round, lineJoin: .round)
        )
    }

    // MARK: - Number Badges

    private var nextTargetNumber: Int? {
        let next = gameState.currentNumber + 1
        guard !gameState.path.isEmpty, !gameState.allNumbersConnected, next <= gameState.maxNumber else {
            return nil
        }
        return next
    }

    private var ledCometGradient: AngularGradient {
        let accent = themeManager.current.accentColor
        let base   = accent.opacity(0.15)
        return AngularGradient(
            stops: [
                .init(color: base,                location: 0.00),
                .init(color: base,                location: 0.65),
                .init(color: accent.opacity(0.5), location: 0.75),
                .init(color: .white,              location: 0.82),
                .init(color: accent.opacity(0.5), location: 0.89),
                .init(color: base,                location: 1.00),
            ],
            center: .center,
            startAngle: .degrees(ledPhase),
            endAngle:   .degrees(ledPhase + 360)
        )
    }

    private var sortedNumberPositions: [(key: Int, value: GridPosition)] {
        gameState.numberPositions.sorted(by: { $0.key < $1.key })
    }

    private func numberBadgesOverlay(cellSize: CGFloat) -> some View {
        ForEach(sortedNumberPositions, id: \.key) { number, position in
            let showHint = number == nextTargetNumber && hintActive
            let accent   = themeManager.current.accentColor

            ZStack {
                if showHint {
                    Circle()
                        .fill(accent.opacity(breathPhase ? 0.6 : 0.1))
                        .frame(width: cellSize * 0.85, height: cellSize * 0.85)
                        .blur(radius: breathPhase ? 16 : 6)
                        .scaleEffect(breathPhase ? 1.3 : 0.95)

                    Circle()
                        .stroke(ledCometGradient, lineWidth: 2.5)
                        .frame(width: cellSize * 0.8, height: cellSize * 0.8)
                }

                Circle()
                    .fill(Color.black)
                    .frame(width: cellSize * 0.65, height: cellSize * 0.65)
                    .overlay(
                        Text("\(number)")
                            .font(.system(size: cellSize * 0.35, weight: .bold))
                            .foregroundStyle(.white)
                    )
                    .shadow(
                        color: showHint ? accent.opacity(breathPhase ? 0.8 : 0.2) : .clear,
                        radius: showHint ? (breathPhase ? 12 : 4) : 0
                    )
            }
            .position(
                x: (CGFloat(position.col) + 0.5) * cellSize,
                y: (CGFloat(position.row) + 0.5) * cellSize
            )
            .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: breathPhase)
        }
    }

    private func startBreathing() {
        breathPhase = false
        Task {
            try? await Task.sleep(for: .milliseconds(50))
            breathPhase = true
        }
    }

    // MARK: - Drag Handling

    private func handleDrag(at point: CGPoint, cellSize: CGFloat) {
        guard gameStarted, !gameState.allNumbersConnected else { return }
        let col = Int(point.x / cellSize)
        let row = Int(point.y / cellSize)
        guard row >= 0, row < gameState.gridSize, col >= 0, col < gameState.gridSize else { return }
        let added = gameState.addToPath(GridPosition(row: row, col: col))
        if added { soundManager.playStep() }
    }

    // MARK: - Completion Overlay

    private var shareResultText: String {
        if isWeekly {
            return lm.t("share.weekly")
        } else if isDaily {
            let streak = streakManager.currentStreak
            let streakPart = streak > 1 ? " 🔥 \(streak)-day streak!" : ""
            return "🧩 \(String(format: lm.t("game.solved_in"), formattedTime))\(streakPart) Play Flow Connect Puzzle!"
        } else {
            return String(format: lm.t("share.solved_puzzle"), lm.difficultyName(difficulty), formattedTime)
        }
    }

    private var completionOverlay: some View {
        let theme = themeManager.current

        return ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                HStack(spacing: 8) {
                    if isWeekly {
                        Image(systemName: "crown.fill")
                            .foregroundStyle(.yellow)
                    } else if isDaily {
                        Image(systemName: "calendar.badge.checkmark")
                            .foregroundStyle(.yellow)
                    }
                    Text(isWeekly ? lm.t("game.weekly_complete") : (isDaily ? lm.t("game.daily_complete") : lm.t("game.puzzle_complete")))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.primary)
                }

                HStack(spacing: 8) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.secondary)
                    Text(formattedTime)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.primary)
                        .monospacedDigit()
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                if isPersonalBest {
                    HStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                        Text(lm.t("game.new_personal_best"))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.yellow)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.yellow.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Share result
                ShareLink(item: shareResultText) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 14))
                        Text(lm.t("game.share_result"))
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 9)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                if isDaily || isWeekly {
                    Button(action: onBack) {
                        Text(lm.t("game.back_to_menu"))
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 12)
                            .background(theme.pathColor)
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                            .shadow(color: theme.pathColor.opacity(0.35), radius: 8, x: 0, y: 4)
                    }
                } else {
                    Button(action: {
                        gameState.newGame()
                        resetTimer()
                        isPersonalBest = false
                    }) {
                        Text(lm.t("game.next_puzzle"))
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 12)
                            .background(theme.pathColor)
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                            .shadow(color: theme.pathColor.opacity(0.35), radius: 8, x: 0, y: 4)
                    }
                }
            }
            .padding(32)
        }
    }
}

// MARK: - Previews

/// Helper that auto-starts the game after a short delay so the in-progress
/// state is visible in the canvas without needing to tap Start manually.
private struct AutoStartPreview: View {
    let mode: GameMode
    let colorScheme: ColorScheme?

    init(_ mode: GameMode, colorScheme: ColorScheme? = nil) {
        self.mode = mode
        self.colorScheme = colorScheme
    }

    var body: some View {
        PuzzleGameView(mode: mode, onBack: {})
            .preferredColorScheme(colorScheme)
    }
}

#Preview("Start Screen — Medium") {
    AutoStartPreview(.normal(.medium))
}

#Preview("Start Screen — Easy, Dark") {
    AutoStartPreview(.normal(.easy), colorScheme: .dark)
}

#Preview("Start Screen — Expert") {
    AutoStartPreview(.normal(.expert))
}

#Preview("Daily Challenge") {
    AutoStartPreview(.daily)
}

#Preview("Zen Mode") {
    AutoStartPreview(.zen(.medium))
}

