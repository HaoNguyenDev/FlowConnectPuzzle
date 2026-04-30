//
//  TimeTrialView.swift
//  FlowConnectPuzzle
//

import SwiftUI
import Combine

struct TimeTrialView: View {
    let onBack: () -> Void

    @State private var gameState = GameState(difficulty: .easy)
    @State private var themeManager = ThemeManager.shared
    @State private var achievementManager = AchievementManager.shared
    @State private var lm = LocalizationManager.shared

    // Timer
    @State private var timeRemaining: TimeInterval = 180  // 3 minutes
    @State private var isRunning = false
    @State private var isFinished = false

    // Scoring
    @State private var score = 0
    @State private var puzzlesSolved = 0
    @State private var currentDifficulty: Difficulty = .easy

    // Path animation
    @State private var ledPhase: Double = 0
    @State private var breathPhase = false

    private let countdownTimer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()
    private let ledTimer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()

    // Difficulty escalates every 5 puzzles
    private func nextDifficulty(after puzzles: Int) -> Difficulty {
        switch puzzles {
        case 0..<5:   return .easy
        case 5..<10:  return .medium
        case 10..<15: return .hard
        case 15..<20: return .veryHard
        default:      return .expert
        }
    }

    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()

                // Header
                HStack {
                    Button(action: onBack) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                            .padding(12)
                            .background(Color(uiColor: .systemBackground))
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.08), radius: 4)
                    }

                    Spacer()

                    // Score
                    VStack(spacing: 2) {
                        Text("\(score)")
                            .font(.system(size: 28, weight: .bold).monospacedDigit())
                            .foregroundColor(themeManager.current.pathColor)
                        Text(lm.t("timetrial.score"))
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    // Puzzles solved
                    VStack(spacing: 2) {
                        Text("\(puzzlesSolved)")
                            .font(.system(size: 28, weight: .bold).monospacedDigit())
                        Text(lm.t("timetrial.solved"))
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 20)

                // Countdown bar
                VStack(spacing: 6) {
                    HStack {
                        Image(systemName: "timer")
                            .foregroundColor(timeRemaining < 30 ? .red : .secondary)
                        Text(formattedTimeRemaining)
                            .font(.system(size: 22, weight: .semibold).monospacedDigit())
                            .foregroundColor(timeRemaining < 30 ? .red : .primary)
                        Spacer()
                        Text(lm.difficultyName(currentDifficulty))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 20)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color(uiColor: .systemFill))
                            Capsule()
                                .fill(timeRemaining < 30
                                    ? Color.red
                                    : themeManager.current.pathColor)
                                .frame(width: geo.size.width * (timeRemaining / 180.0))
                                .animation(.linear(duration: 0.01), value: timeRemaining)
                        }
                    }
                    .frame(height: 6)
                    .padding(.horizontal, 20)
                }

                // Puzzle grid
                puzzleGrid
                    .padding(.horizontal, 16)

                // Undo / Reset — shown from Medium difficulty onwards
                if currentDifficulty != .easy {
                    HStack(spacing: 16) {
                        actionButton(icon: "arrow.uturn.backward", label: "Undo") {
                            gameState.undo()
                        }
                        .disabled(!isRunning || gameState.path.isEmpty)
                        .opacity(!isRunning || gameState.path.isEmpty ? 0.4 : 1)

                        actionButton(icon: "arrow.counterclockwise", label: "Reset") {
                            gameState.reset()
                        }
                        .disabled(!isRunning || gameState.path.isEmpty)
                        .opacity(!isRunning || gameState.path.isEmpty ? 0.4 : 1)
                    }
                    .animation(.easeInOut(duration: 0.25), value: currentDifficulty)
                }

                Spacer()
            }

            // Start overlay
            if !isRunning && !isFinished {
                startOverlay
            }

            // Finish overlay
            if isFinished {
                finishOverlay
            }
        }
        .onReceive(countdownTimer) { _ in
            guard isRunning && !isFinished else { return }
            timeRemaining = max(0, timeRemaining - 0.01)
            if timeRemaining == 0 {
                isFinished = true
                isRunning = false
                AchievementManager.shared.checkTimeTrial(score: score)
            }
        }
        .onReceive(ledTimer) { _ in
            ledPhase = (ledPhase + 1.5).truncatingRemainder(dividingBy: 360)
        }
        .onChange(of: gameState.allNumbersConnected) { _, solved in
            if solved {
                let pts = ProgressionManager.baseXP(for: currentDifficulty)
                score += pts
                puzzlesSolved += 1
                currentDifficulty = nextDifficulty(after: puzzlesSolved)
                gameState = GameState(difficulty: currentDifficulty)
            }
        }
    }

    // MARK: - Formatted Time

    private var formattedTimeRemaining: String {
        let total = Int(timeRemaining)
        let m = total / 60
        let s = total % 60
        return String(format: "%d:%02d", m, s)
    }

    // MARK: - Puzzle Grid

    private var puzzleGrid: some View {
        GeometryReader { geometry in
            let totalSize = geometry.size.width
            let cellSize = totalSize / CGFloat(gameState.gridSize)

            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(uiColor: .systemBackground))
                    .shadow(color: .black.opacity(0.08), radius: 8)

                VStack(spacing: 0) {
                    ForEach(0..<gameState.gridSize, id: \.self) { row in
                        HStack(spacing: 0) {
                            ForEach(0..<gameState.gridSize, id: \.self) { col in
                                let cell = gameState.grid[row][col]
                                Rectangle()
                                    .fill(cellColor(cell))
                                    .border(Color.gray.opacity(0.15), width: 0.5)
                                    .frame(width: cellSize, height: cellSize)
                            }
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))

                Canvas { ctx, _ in drawPath(in: ctx, cellSize: cellSize) }
                    .allowsHitTesting(false)

                numberBadges(cellSize: cellSize).allowsHitTesting(false)
            }
            .frame(width: totalSize, height: totalSize)
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { v in
                    guard isRunning else { return }
                    let col = Int(v.location.x / cellSize)
                    let row = Int(v.location.y / cellSize)
                    guard row >= 0, row < gameState.gridSize, col >= 0, col < gameState.gridSize else { return }
                    _ = gameState.addToPath(GridPosition(row: row, col: col))
                }
            )
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func cellColor(_ cell: GridCell) -> Color {
        if gameState.allNumbersConnected && cell.isInPath {
            return themeManager.current.completedColor.opacity(0.12)
        } else if cell.isHighlighted {
            return themeManager.current.cellHighlightColor
        } else if cell.isInPath {
            return themeManager.current.pathColor.opacity(0.1)
        }
        return Color(uiColor: .systemBackground)
    }

    private func drawPath(in context: GraphicsContext, cellSize: CGFloat) {
        let positions = gameState.path
        guard positions.count > 1 else { return }
        var path = Path()
        for (i, pos) in positions.enumerated() {
            let pt = CGPoint(x: (CGFloat(pos.col) + 0.5) * cellSize, y: (CGFloat(pos.row) + 0.5) * cellSize)
            if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
        }
        let color: Color = gameState.allNumbersConnected
            ? themeManager.current.completedColor
            : themeManager.current.pathColor.opacity(0.55)
        context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: cellSize * 0.25, lineCap: .round, lineJoin: .round))
    }

    private func numberBadges(cellSize: CGFloat) -> some View {
        ForEach(Array(gameState.numberPositions.sorted(by: { $0.key < $1.key })), id: \.key) { number, position in
            Circle()
                .fill(Color.black)
                .frame(width: cellSize * 0.65, height: cellSize * 0.65)
                .overlay(Text("\(number)").font(.system(size: cellSize * 0.35, weight: .bold)).foregroundColor(.white))
                .position(x: (CGFloat(position.col) + 0.5) * cellSize, y: (CGFloat(position.row) + 0.5) * cellSize)
        }
    }

    // MARK: - Start Overlay

    private var startOverlay: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
            VStack(spacing: 24) {
                Image(systemName: "timer")
                    .font(.system(size: 48))
                    .foregroundColor(themeManager.current.pathColor)
                VStack(spacing: 8) {
                    Text(lm.t("timetrial.title"))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    Text(lm.t("timetrial.subtitle"))
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                Button(action: { isRunning = true }) {
                    HStack(spacing: 10) {
                        Image(systemName: "play.fill")
                        Text(lm.t("timetrial.start"))
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 48)
                    .padding(.vertical, 14)
                    .background(themeManager.current.pathColor)
                    .cornerRadius(28)
                }
            }
        }
    }

    // MARK: - Finish Overlay

    private var finishOverlay: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            VStack(spacing: 20) {
                Text(lm.t("timetrial.times_up"))
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)

                VStack(spacing: 12) {
                    scoreRow(label: lm.t("timetrial.puzzles_solved"), value: "\(puzzlesSolved)")
                    scoreRow(label: lm.t("timetrial.total_score"),    value: String(format: lm.t("timetrial.pts"), score))
                    scoreRow(label: lm.t("timetrial.best_difficulty"), value: lm.difficultyName(currentDifficulty))
                }
                .padding(20)
                .background(Color.white.opacity(0.15))
                .cornerRadius(16)

                ShareLink(item: String(format: lm.t("timetrial.share"), puzzlesSolved, score)) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                        Text(lm.t("timetrial.share_result"))
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 9)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(12)
                }

                Button(action: onBack) {
                    Text(lm.t("timetrial.back_to_menu"))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(themeManager.current.pathColor)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .cornerRadius(24)
                }
            }
        }
    }

    private func scoreRow(label: String, value: String) -> some View {
        HStack {
            Text(label).foregroundColor(.white.opacity(0.8))
            Spacer()
            Text(value).fontWeight(.semibold).foregroundColor(.white)
        }
    }

    private func actionButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                Text(label)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(.primary)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color(uiColor: .systemBackground))
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.08), radius: 4)
        }
    }
}

#Preview {
    TimeTrialView(onBack: {})
}
