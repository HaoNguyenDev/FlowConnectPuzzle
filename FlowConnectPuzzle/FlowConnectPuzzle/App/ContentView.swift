//
//  ContentView.swift
//  FlowConnectPuzzle
//
//  Created by Steven Tran on 18/4/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedDifficulty: Difficulty?
    
    var body: some View {
        if let difficulty = selectedDifficulty {
            PuzzleGameView(difficulty: difficulty, onBack: {
                selectedDifficulty = nil
            })
        } else {
            difficultySelectionView
        }
    }
    
    // MARK: - Difficulty Selection
    
    private var difficultySelectionView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Text("Flow Connect")
                .font(.system(size: 36, weight: .bold))
            
            Text("Select Difficulty")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.secondary)
            
            VStack(spacing: 16) {
                ForEach(Difficulty.allCases) { difficulty in
                    Button {
                        selectedDifficulty = difficulty
                    } label: {
                        HStack {
                            Image(systemName: difficulty.iconName)
                                .font(.title2)
                                .frame(width: 40)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(difficulty.displayName)
                                    .font(.system(size: 20, weight: .semibold))
                                Text(difficulty.description)
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .foregroundColor(.primary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(Color(uiColor: .systemBackground))
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
            Spacer()
        }
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
