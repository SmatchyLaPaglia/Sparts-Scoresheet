////
////  ScoreTableTextOverlay.swift
////  Sparts Scoresheet
////
////  Created by Jesse Macbook Clark on 9/5/25.
////
//
//
//import SwiftUI
//
//struct ScoreTableTextOverlay: View {
//    let teams: [Team]
//    @State private var layout: ScoreTableLayout?
//    
//    var body: some View {
//        GeometryReader { geometry in
//            ZStack {
//                if let layout = layout, layout.rows > 0 && layout.cols > 0 {
//                    // Header text
//                    headerText(layout: layout)
//                    
//                    // Player names
//                    playerNames(layout: layout)
//                    
//                    // Chip labels (bid/took, hearts, queen, moon)
//                    chipLabels(layout: layout)
//                    
//                    // Right side mini headers
//                    rightSideMiniHeaders(layout: layout)
//                }
//            }
//            .onPreferenceChange(ScoreTableLayoutKey.self) { newLayout in
//                layout = newLayout
//            }
//        }
//    }
//    
//    private func headerText(layout: ScoreTableLayout) -> some View {
//        Group {
//            if layout.rows >= 1 {
//                let headerRect = layout.rowRects[0]
//                
//                // TEAMS (columns 0-2)
//                textInCell(layout: layout, row: 0, c0: 0, c1: 3, text: "TEAMS", 
//                          fontSize: headerRect.height * 0.35, color: Theme.leftHeaderText)
//                
//                // SPADES (columns 3-5)
//                textInCell(layout: layout, row: 0, c0: 3, c1: 6, text: "SPADES", 
//                          fontSize: headerRect.height * 0.35, color: Theme.leftHeaderText)
//                
//                // HEARTS (columns 6-8)
//                textInCell(layout: layout, row: 0, c0: 6, c1: 9, text: "HEARTS", 
//                          fontSize: headerRect.height * 0.35, color: Theme.leftHeaderText)
//                
//                // HAND SCORES (columns 10-12)
//                textInCell(layout: layout, row: 0, c0: 10, c1: 13, text: "HAND\nSCORES", 
//                          fontSize: headerRect.height * 0.25, color: Theme.leftHeaderText)
//                
//                // TOTAL SCORES (columns 13-15)
//                textInCell(layout: layout, row: 0, c0: 13, c1: 16, text: "TOTAL\nSCORES", 
//                          fontSize: headerRect.height * 0.25, color: Theme.leftHeaderText)
//                
//                // GRAND TOTAL (column 16)
//                if layout.cols > 16 {
//                    textInCell(layout: layout, row: 0, c0: 16, c1: 17, text: "GRAND\nTOTAL", 
//                              fontSize: headerRect.height * 0.25, color: Theme.leftHeaderText)
//                }
//            }
//        }
//    }
//    
//    private func playerNames(layout: ScoreTableLayout) -> some View {
//        Group {
//            if layout.rows >= 5 && teams.count >= 2 {
//                // Team 1 Player 1 (row 2)
//                if teams[0].players.count > 0 {
//                    textInCell(layout: layout, row: 1, c0: 0, c1: 3, text: teams[0].players[0].name,
//                              fontSize: layout.rowRects[1].height * 0.35, color: Theme.textOnLight)
//                }
//                
//                // Team 1 Player 2 (row 3)
//                if teams[0].players.count > 1 {
//                    textInCell(layout: layout, row: 2, c0: 0, c1: 3, text: teams[0].players[1].name,
//                              fontSize: layout.rowRects[2].height * 0.35, color: Theme.textOnLight)
//                }
//                
//                // Team 2 Player 1 (row 4)
//                if teams[1].players.count > 0 {
//                    textInCell(layout: layout, row: 3, c0: 0, c1: 3, text: teams[1].players[0].name,
//                              fontSize: layout.rowRects[3].height * 0.35, color: Theme.textOnLight)
//                }
//                
//                // Team 2 Player 2 (row 5)
//                if teams[1].players.count > 1 {
//                    textInCell(layout: layout, row: 4, c0: 0, c1: 3, text: teams[1].players[1].name,
//                              fontSize: layout.rowRects[4].height * 0.35, color: Theme.textOnLight)
//                }
//            }
//        }
//    }
//    
//    private func chipLabels(layout: ScoreTableLayout) -> some View {
//        Group {
//            if layout.rows >= 5 {
//                let chipFontSize = layout.rowRects[1].height * 0.25
//                
//                // Team 1 bid/took chips (rows 2 & 3)
//                textInCell(layout: layout, row: 1, c0: 3, c1: 5, text: "bid/took",
//                          fontSize: chipFontSize, color: Theme.textSecondary)
//                textInCell(layout: layout, row: 2, c0: 3, c1: 5, text: "bid/took",
//                          fontSize: chipFontSize, color: Theme.textSecondary)
//                
//                // Team 2 bid/took chips (rows 4 & 5)
//                textInCell(layout: layout, row: 3, c0: 3, c1: 5, text: "bid/took",
//                          fontSize: chipFontSize, color: Theme.textSecondary)
//                textInCell(layout: layout, row: 4, c0: 3, c1: 5, text: "bid/took",
//                          fontSize: chipFontSize, color: Theme.textSecondary)
//                
//                // Hearts chips (all rows)
//                for row in [1, 2, 3, 4] {
//                    textInCell(layout: layout, row: row, c0: 6, c1: 7, text: "hearts",
//                              fontSize: chipFontSize, color: Theme.textSecondary)
//                    textInCell(layout: layout, row: row, c0: 7, c1: 8, text: "queen",
//                              fontSize: chipFontSize, color: Theme.textSecondary)
//                    textInCell(layout: layout, row: row, c0: 8, c1: 9, text: "moon",
//                              fontSize: chipFontSize, color: Theme.textSecondary)
//                }
//            }
//        }
//    }
//    
//    private func rightSideMiniHeaders(layout: ScoreTableLayout) -> some View {
//        Group {
//            if layout.rows >= 5 && layout.cols >= 17 {
//                let miniHeaderFontSize = layout.rowRects[1].height * 0.2
//                let labels = ["SPADES", "HEARTS", "BAGS", "SPADES", "HEARTS", "BAGS", "GAME\nTOTAL"]
//                
//                // Team 1 mini headers (row 2)
//                ForEach(0..<labels.count, id: \.self) { index in
//                    textInCell(layout: layout, row: 1, c0: 10 + index, c1: 11 + index, text: labels[index],
//                              fontSize: miniHeaderFontSize, color: Theme.rightMiniHeaderTxt)
//                }
//                
//                // Team 2 mini headers (row 4)
//                ForEach(0..<labels.count, id: \.self) { index in
//                    textInCell(layout: layout, row: 3, c0: 10 + index, c1: 11 + index, text: labels[index],
//                              fontSize: miniHeaderFontSize, color: Theme.rightMiniHeaderTxt)
//                }
//            }
//        }
//    }
//    
//    private func textInCell(layout: ScoreTableLayout, row: Int, c0: Int, c1: Int, text: String, fontSize: CGFloat, color: Color) -> some View {
//        Group {
//            if row < layout.rowRects.count && c1 <= layout.cols {
//                let rowRect = layout.rowRects[row]
//                let centerX = layout.centerX(row: row, c0: c0, c1: c1)
//                let centerY = layout.tableRect.minY + rowRect.midY
//                
//                Text(text)
//                    .font(.system(size: fontSize, weight: .bold))
//                    .foregroundColor(color)
//                    .multilineTextAlignment(.center)
//                    .position(x: centerX, y: centerY)
//            }
//        }
//    }
//}
//
//// Combined view that shows both the table and text overlay
//struct CompleteScoreTableView: View {
//    let teams: [Team]
//    
//    var body: some View {
//        ZStack {
//            // The notch-detecting table
//            NotchSafeScoreTable()
//            
//            // Text overlay using preference keys
//            ScoreTableTextOverlay(teams: teams)
//        }
//    }
//}
//
//// Preview
//struct CompleteScoreTableView_Previews: PreviewProvider {
//    static var previews: some View {
//        CompleteScoreTableView(teams: [
//            Team(players: [
//                Player(name: "Player 1", bid: 3, took: 2),
//                Player(name: "Player 2", bid: 4, took: 3)
//            ], hearts: 5, queenSpades: true, moonShot: false),
//            Team(players: [
//                Player(name: "Player 3", bid: 2, took: 4),
//                Player(name: "Player 4", bid: 3, took: 2)
//            ], hearts: 3, queenSpades: false, moonShot: true)
//        ])
//        .frame(width: 800, height: 600)
//        .previewLayout(.sizeThatFits)
//    }
//}
