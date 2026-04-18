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
    private let ledTimer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()
    
    let difficulty: Difficulty
    let onBack: () -> Void
    
    init(difficulty: Difficulty, onBack: @escaping () -> Void) {
        self.difficulty = difficulty
        self.onBack = onBack
        _gameState = State(initialValue: GameState(difficulty: difficulty))
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Difficulty label
            Text(difficulty.displayName)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            
            puzzleGrid
                .padding(.horizontal, 16)
            
            // Action buttons
            HStack(spacing: 12) {
                // Back button
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color(uiColor: .systemBackground))
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                }
                
                // Reset (same puzzle)
                Button(action: { gameState.reset() }) {
                    Text("Reset")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(Color(uiColor: .systemBackground))
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                }
                
                // Hint
                Button(action: {
                    hintActive = true
                    startBreathing()
                }) {
                    Image(systemName: "lightbulb.max")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(hintActive ? .yellow : .primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color(uiColor: .systemBackground))
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                }
                .disabled(gameState.allNumbersConnected || gameState.path.isEmpty)
                .opacity(gameState.allNumbersConnected || gameState.path.isEmpty ? 0.4 : 1)
                
                // New puzzle (regenerate)
                Button(action: { gameState.newGame() }) {
                    Text("New")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(Color(uiColor: .systemBackground))
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
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
    }
    
    // MARK: - Puzzle Grid
    
    private var puzzleGrid: some View {
        GeometryReader { geometry in
            let totalSize = geometry.size.width
            let cellSize = totalSize / CGFloat(gameState.gridSize)
            
            ZStack {
                // Grid background with rounded corners
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(uiColor: .systemBackground))
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                
                // Grid cells
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
                
                // Path lines drawn on top of cells
                Canvas { context, size in
                    drawPath(in: context, cellSize: cellSize)
                }
                .allowsHitTesting(false)
                
                // Number badges drawn on top of everything
                numberBadgesOverlay(cellSize: cellSize)
                    .allowsHitTesting(false)
            }
            .frame(width: totalSize, height: totalSize)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        handleDrag(at: value.location, cellSize: cellSize)
                    }
                    .onEnded { _ in }
            )
        }
        .aspectRatio(1, contentMode: .fit)
        .onReceive(ledTimer) { _ in
            ledPhase = (ledPhase + 1.5).truncatingRemainder(dividingBy: 360)
        }
        .onAppear {
            startBreathing()
        }
        .onChange(of: gameState.currentNumber) { _, _ in
            hintActive = false
        }
    }
    
    // MARK: - Cell View
    
    private func cellView(row: Int, col: Int, cellSize: CGFloat) -> some View {
        let cell = gameState.grid[row][col]
        
        return Rectangle()
            .fill(cellBackground(for: cell))
            .border(Color.gray.opacity(0.2), width: 0.5)
            .frame(width: cellSize, height: cellSize)
    }
    
    private func cellBackground(for cell: GridCell) -> Color {
        if gameState.allNumbersConnected && cell.isInPath {
            return Color.green.opacity(0.1)
        } else if cell.isHighlighted {
            return Color(red: 0.85, green: 0.93, blue: 1.0) // Light blue for number 1
        } else if cell.isInPath {
            return Color.blue.opacity(0.1)
        } else {
            return Color(uiColor: .systemBackground)
        }
    }
    
    // MARK: - Path Drawing
    
    private func drawPath(in context: GraphicsContext, cellSize: CGFloat) {
        let pathPositions = gameState.path
        guard pathPositions.count > 1 else { return }
        
        var linePath = Path()
        for i in 0..<pathPositions.count {
            let pos = pathPositions[i]
            let point = CGPoint(
                x: (CGFloat(pos.col) + 0.5) * cellSize,
                y: (CGFloat(pos.row) + 0.5) * cellSize
            )
            if i == 0 {
                linePath.move(to: point)
            } else {
                linePath.addLine(to: point)
            }
        }
        
        let pathColor: Color = gameState.allNumbersConnected ? .green : .blue.opacity(0.5)
        
        context.stroke(
            linePath,
            with: .color(pathColor),
            style: StrokeStyle(
                lineWidth: cellSize * 0.15,
                lineCap: .round,
                lineJoin: .round
            )
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
    
    /// AngularGradient comet effect matching LedBorderButton style
    private var ledCometGradient: AngularGradient {
        let base = Color.cyan.opacity(0.15)
        return AngularGradient(
            stops: [
                .init(color: base,                    location: 0.00),
                .init(color: base,                    location: 0.65),
                .init(color: Color.cyan.opacity(0.5), location: 0.75),
                .init(color: .white,                  location: 0.82),
                .init(color: Color.cyan.opacity(0.5), location: 0.89),
                .init(color: base,                    location: 1.00),
            ],
            center: .center,
            startAngle: .degrees(ledPhase),
            endAngle: .degrees(ledPhase + 360)
        )
    }
    
    private func numberBadgesOverlay(cellSize: CGFloat) -> some View {
        ForEach(Array(gameState.numberPositions.sorted(by: { $0.key < $1.key })), id: \.key) { number, position in
            let showHint = number == nextTargetNumber && hintActive
            
            ZStack {
                if showHint {
                    // Breathing outer glow (blur layer)
                    Circle()
                        .fill(Color.cyan.opacity(breathPhase ? 0.6 : 0.1))
                        .frame(width: cellSize * 0.85, height: cellSize * 0.85)
                        .blur(radius: breathPhase ? 16 : 6)
                        .scaleEffect(breathPhase ? 1.3 : 0.95)
                    
                    // LED comet ring
                    Circle()
                        .stroke(ledCometGradient, lineWidth: 2.5)
                        .frame(width: cellSize * 0.8, height: cellSize * 0.8)
                }
                
                // Number badge
                Circle()
                    .fill(Color.black)
                    .frame(width: cellSize * 0.65, height: cellSize * 0.65)
                    .overlay(
                        Text("\(number)")
                            .font(.system(size: cellSize * 0.35, weight: .bold))
                            .foregroundColor(.white)
                    )
                    .shadow(
                        color: showHint ? Color.cyan.opacity(breathPhase ? 0.8 : 0.2) : .clear,
                        radius: showHint ? (breathPhase ? 12 : 4) : 0
                    )
            }
            .position(
                x: (CGFloat(position.col) + 0.5) * cellSize,
                y: (CGFloat(position.row) + 0.5) * cellSize
            )
            .animation(
                .easeInOut(duration: 1.4).repeatForever(autoreverses: true),
                value: breathPhase
            )
        }
    }
    
    private func startBreathing() {
        breathPhase = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            breathPhase = true
        }
    }
    
    // MARK: - Drag Handling
    
    private func handleDrag(at point: CGPoint, cellSize: CGFloat) {
        // Block drawing when all numbers are connected
        guard !gameState.allNumbersConnected else { return }
        
        let col = Int(point.x / cellSize)
        let row = Int(point.y / cellSize)
        
        guard row >= 0 && row < gameState.gridSize &&
              col >= 0 && col < gameState.gridSize else {
            return
        }
        
        let position = GridPosition(row: row, col: col)
        _ = gameState.addToPath(position)
    }
    
    // MARK: - Completion Overlay
    
    private var completionOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                Text("Puzzle Complete!")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                
                Button(action: { gameState.newGame() }) {
                    Text("Next Puzzle")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.blue)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .cornerRadius(24)
                }
            }
        }
    }
}

#Preview {
    PuzzleGameView(difficulty: .medium, onBack: {})
}
