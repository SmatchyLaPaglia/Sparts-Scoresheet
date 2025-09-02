//
//  ScoreSheet.swift
//  Sparts Scoresheet
//
//  Created by Jesse Macbook Clark on 9/1/25.
//

import SwiftUI

struct ScoreTable: View {
    let teams: [Team]
    @State private var metrics = Metrics()
    
    // Mock data for preview - these would come from your actual data models
    @State private var t1_p1_bid = 0
    @State private var t1_p1_took = 0
    @State private var t1_p2_bid = 0
    @State private var t1_p2_took = 0
    @State private var t1_hearts = 0
    @State private var t2_p1_bid = 0
    @State private var t2_p1_took = 0
    @State private var t2_p2_bid = 0
    @State private var t2_p2_took = 0
    @State private var t2_hearts = 0
    @State private var t1_qs = false
    @State private var t1_moon = false
    @State private var t2_qs = false
    @State private var t2_moon = false
    
    struct Metrics {
        var innerX: CGFloat = 0
        var innerY: CGFloat = 0
        var leftW: CGFloat = 0
        var gapW: CGFloat = 0
        var rightW: CGFloat = 0
        var tablesH: CGFloat = 0
        var wName: CGFloat = 0
        var wNarrow: CGFloat = 0
        var wHearts: CGFloat = 0
        var wScore: CGFloat = 0
        var leftHeaderH: CGFloat = 0
        var leftRowH: CGFloat = 0
        var rightRowH: CGFloat = 0
        var headY: CGFloat = 0
        var yAfterHeadGap: CGFloat = 0
        var t1_row1: CGFloat = 0
        var t1_row2: CGFloat = 0
        var t2_row1: CGFloat = 0
        var t2_row2: CGFloat = 0
        var numberFontSize: CGFloat = 0
    }
    
    struct Theme {
        static let gridLine = Color(red: 32/255, green: 32/255, blue: 32/255)
        static let cellBg = Color.white
        static let leftHeaderBg = Color(red: 55/255, green: 55/255, blue: 55/255)
        static let leftHeaderText = Color(red: 255/255, green: 140/255, blue: 0/255)
        static let nameStripeLight = Color(red: 238/255, green: 238/255, blue: 238/255)
        static let nameStripeDark = Color(red: 220/255, green: 235/255, blue: 225/255)
        static let textOnLight = Color.black
        static let textSecondary = Color(red: 180/255, green: 180/255, blue: 180/255)
        static let rightMiniHeaderBg = Color(red: 55/255, green: 55/255, blue: 55/255)
        static let rightMiniHeaderTxt = Color(red: 255/255, green: 140/255, blue: 0/255)
        static let rightSpadesScoreBg = Color(red: 0/255, green: 132/255, blue: 141/255)
        static let rightHeartsScoreBg = Color(red: 0/255, green: 146/255, blue: 145/255)
        static let rightHandScoreBg = Color(red: 0/255, green: 116/255, blue: 128/255)
        static let rightAllBagsBg = Color(red: 0/255, green: 100/255, blue: 190/255)
        static let rightSpadesTotalBg = Color(red: 0/255, green: 110/255, blue: 190/255)
        static let rightHeartsTotalBg = Color(red: 0/255, green: 80/255, blue: 190/255)
        static let rightGameTotalBg = Color(red: 160/255, green: 40/255, blue: 120/255)
        static let rightNumberTxt = Color.white
    }
    
    var body: some View {
        GeometryReader { geometry in
            let safeArea = geometry.safeAreaInsets
            let safeWidth = geometry.size.width - safeArea.leading - safeArea.trailing
            let safeHeight = geometry.size.height - safeArea.top - safeArea.bottom
            
            ZStack {
                // Main content
                VStack(spacing: 0) {
                    // Header row
                    headerRow
                    
                    // Team 1 rows
                    team1Row1
                    team1Row2
                    
                    // Team 2 rows
                    team2Row1
                    team2Row2
                }
                .background(Theme.cellBg)
                .border(Theme.gridLine, width: 1)
            }
            .onAppear {
                updateMetrics(for: geometry.size)
            }
            .onChange(of: geometry.size) { newSize in
                updateMetrics(for: newSize)
            }
        }
    }
    
    private var headerRow: some View {
        HStack(spacing: 0) {
            // TEAMS column
            cell(width: metrics.wName, height: metrics.leftHeaderH,
                 bg: Theme.leftHeaderBg, text: "TEAMS", textColor: Theme.leftHeaderText)
            
            // SPADES columns
            ForEach(0..<3, id: \.self) { _ in
                cell(width: metrics.wNarrow, height: metrics.leftHeaderH,
                     bg: Theme.leftHeaderBg, text: "SPADES", textColor: Theme.leftHeaderText)
            }
            
            // HEARTS columns
            ForEach(0..<3, id: \.self) { _ in
                cell(width: metrics.wHearts, height: metrics.leftHeaderH,
                     bg: Theme.leftHeaderBg, text: "HEARTS", textColor: Theme.leftHeaderText)
            }
            
            // Gap
            if metrics.gapW > 0 {
                cell(width: metrics.gapW, height: metrics.leftHeaderH, bg: Theme.leftHeaderBg)
            }
            
            // Right side columns
            Group {
                cell(width: metrics.wScore * 3, height: metrics.leftHeaderH,
                     bg: Theme.leftHeaderBg, text: "HAND\nSCORES", textColor: Theme.leftHeaderText)
                
                cell(width: metrics.wScore * 3, height: metrics.leftHeaderH,
                     bg: Theme.leftHeaderBg, text: "TOTAL\nSCORES", textColor: Theme.leftHeaderText)
                
                cell(width: metrics.wScore, height: metrics.leftHeaderH,
                     bg: Theme.leftHeaderBg, text: "GRAND\nTOTAL", textColor: Theme.leftHeaderText)
            }
        }
    }
    
    private var team1Row1: some View {
        HStack(spacing: 0) {
            // Player name
            cell(width: metrics.wName, height: metrics.leftRowH,
                 bg: Theme.nameStripeLight, text: teams[0].players[0].name, textColor: Theme.textOnLight)
            
            // Bid/Took chips
            cell(width: metrics.wNarrow * 2, height: metrics.leftRowH,
                 bg: Theme.leftHeaderBg, text: "bid/took", textColor: Theme.textSecondary)
            
            // Hearts chips
            Group {
                cell(width: metrics.wHearts, height: metrics.leftRowH,
                     bg: Theme.leftHeaderBg, text: "hearts", textColor: Theme.textSecondary)
                cell(width: metrics.wHearts, height: metrics.leftRowH,
                     bg: Theme.leftHeaderBg, text: "queen", textColor: Theme.textSecondary)
                cell(width: metrics.wHearts, height: metrics.leftRowH,
                     bg: Theme.leftHeaderBg, text: "moon", textColor: Theme.textSecondary)
            }
            
            // Gap
            if metrics.gapW > 0 {
                cell(width: metrics.gapW, height: metrics.leftRowH, bg: Theme.cellBg)
            }
            
            // Right side values (would be populated with actual data)
            rightSideValues
        }
    }
    
    private var team1Row2: some View {
        HStack(spacing: 0) {
            // Player name
            cell(width: metrics.wName, height: metrics.leftRowH,
                 bg: Theme.nameStripeDark, text: teams[0].players[1].name, textColor: Theme.textOnLight)
            
            // Interactive cells - these would be your actual IncrementingCell and CheckboxCell views
            Group {
                // Bid
                cell(width: metrics.wNarrow, height: metrics.leftRowH, bg: Theme.cellBg, text: "\(t1_p2_bid)")
                // Took
                cell(width: metrics.wNarrow, height: metrics.leftRowH, bg: Theme.cellBg, text: "\(t1_p2_took)")
                // Hearts
                cell(width: metrics.wHearts, height: metrics.leftRowH, bg: Theme.cellBg, text: "\(t1_hearts)")
                // QS checkbox
                cell(width: metrics.wHearts, height: metrics.leftRowH, bg: Theme.cellBg, text: t1_qs ? "✓" : "")
                // Moon checkbox
                cell(width: metrics.wHearts, height: metrics.leftRowH, bg: Theme.cellBg, text: t1_moon ? "✓" : "")
            }
            
            // Gap
            if metrics.gapW > 0 {
                cell(width: metrics.gapW, height: metrics.leftRowH, bg: Theme.cellBg)
            }
            
            // Right side values
            rightSideValues
        }
    }
    
    private var team2Row1: some View {
        HStack(spacing: 0) {
            // Player name
            cell(width: metrics.wName, height: metrics.leftRowH,
                 bg: Theme.nameStripeLight, text: teams[1].players[0].name, textColor: Theme.textOnLight)
            
            // Bid/Took chips
            cell(width: metrics.wNarrow * 2, height: metrics.leftRowH,
                 bg: Theme.leftHeaderBg, text: "bid/took", textColor: Theme.textSecondary)
            
            // Hearts chips
            Group {
                cell(width: metrics.wHearts, height: metrics.leftRowH,
                     bg: Theme.leftHeaderBg, text: "hearts", textColor: Theme.textSecondary)
                cell(width: metrics.wHearts, height: metrics.leftRowH,
                     bg: Theme.leftHeaderBg, text: "queen", textColor: Theme.textSecondary)
                cell(width: metrics.wHearts, height: metrics.leftRowH,
                     bg: Theme.leftHeaderBg, text: "moon", textColor: Theme.textSecondary)
            }
            
            // Gap
            if metrics.gapW > 0 {
                cell(width: metrics.gapW, height: metrics.leftRowH, bg: Theme.cellBg)
            }
            
            // Right side values
            rightSideValues
        }
    }
    
    private var team2Row2: some View {
        HStack(spacing: 0) {
            // Player name
            cell(width: metrics.wName, height: metrics.leftRowH,
                 bg: Theme.nameStripeDark, text: teams[1].players[1].name, textColor: Theme.textOnLight)
            
            // Interactive cells
            Group {
                // Bid
                cell(width: metrics.wNarrow, height: metrics.leftRowH, bg: Theme.cellBg, text: "\(t2_p2_bid)")
                // Took
                cell(width: metrics.wNarrow, height: metrics.leftRowH, bg: Theme.cellBg, text: "\(t2_p2_took)")
                // Hearts
                cell(width: metrics.wHearts, height: metrics.leftRowH, bg: Theme.cellBg, text: "\(t2_hearts)")
                // QS checkbox
                cell(width: metrics.wHearts, height: metrics.leftRowH, bg: Theme.cellBg, text: t2_qs ? "✓" : "")
                // Moon checkbox
                cell(width: metrics.wHearts, height: metrics.leftRowH, bg: Theme.cellBg, text: t2_moon ? "✓" : "")
            }
            
            // Gap
            if metrics.gapW > 0 {
                cell(width: metrics.gapW, height: metrics.leftRowH, bg: Theme.cellBg)
            }
            
            // Right side values
            rightSideValues
        }
    }
    
    private var rightSideValues: some View {
        Group {
            // Hand Scores
            Group {
                cell(width: metrics.wScore, height: metrics.rightRowH, bg: Theme.rightSpadesScoreBg, text: "--", textColor: Theme.rightNumberTxt)
                cell(width: metrics.wScore, height: metrics.rightRowH, bg: Theme.rightHeartsScoreBg, text: "--", textColor: Theme.rightNumberTxt)
                cell(width: metrics.wScore, height: metrics.rightRowH, bg: Theme.rightHandScoreBg, text: "--", textColor: Theme.rightNumberTxt)
            }
            
            // Total Scores
            Group {
                cell(width: metrics.wScore, height: metrics.rightRowH, bg: Theme.rightSpadesTotalBg, text: "--", textColor: Theme.rightNumberTxt)
                cell(width: metrics.wScore, height: metrics.rightRowH, bg: Theme.rightHeartsTotalBg, text: "--", textColor: Theme.rightNumberTxt)
                cell(width: metrics.wScore, height: metrics.rightRowH, bg: Theme.rightAllBagsBg, text: "--", textColor: Theme.rightNumberTxt)
            }
            
            // Grand Total
            cell(width: metrics.wScore, height: metrics.rightRowH, bg: Theme.rightGameTotalBg, text: "--", textColor: Theme.rightNumberTxt)
        }
    }
    
    private func cell(width: CGFloat, height: CGFloat, bg: Color = Theme.cellBg, text: String = "", textColor: Color = Theme.textOnLight) -> some View {
        Text(text)
            .frame(width: width, height: height)
            .background(bg)
            .foregroundColor(textColor)
            .font(.system(size: metrics.numberFontSize, weight: .bold))
            .multilineTextAlignment(.center)
            .border(Theme.gridLine, width: 1)
    }
    
    private func updateMetrics(for size: CGSize) {
        // Simplified layout calculations based on the Lua code
        let safeW = size.width
        let safeH = size.height
        
        // These percentages would come from your layout configuration
        let overallWidthPercent: CGFloat = 90
        let overallHeightPercent: CGFloat = 80
        let leftTableWidthPercent: CGFloat = 60
        let gapTablesPercent: CGFloat = 5
        let tablesHeightPercent: CGFloat = 70
        
        let overallW = safeW * overallWidthPercent / 100
        let overallH = safeH * overallHeightPercent / 100
        let pad: CGFloat = 8
        let innerW = overallW - pad * 2
        let leftW = innerW * leftTableWidthPercent / 100
        let gapW = innerW * gapTablesPercent / 100
        let rightW = max(0, innerW - leftW - gapW)
        let tablesH = overallH * tablesHeightPercent / 100
        
        var newMetrics = Metrics()
        newMetrics.leftHeaderH = max(28, min(64, tablesH / 5))
        newMetrics.leftRowH = newMetrics.leftHeaderH
        newMetrics.rightRowH = newMetrics.leftRowH
        
        // Column widths (simplified)
        newMetrics.wName = leftW * 0.4
        newMetrics.wNarrow = leftW * 0.15
        newMetrics.wHearts = leftW * 0.15
        newMetrics.wScore = rightW / 7
        
        newMetrics.innerX = pad
        newMetrics.innerY = pad
        newMetrics.leftW = leftW
        newMetrics.gapW = gapW
        newMetrics.rightW = rightW
        newMetrics.tablesH = tablesH
        newMetrics.numberFontSize = newMetrics.leftRowH * 0.5
        
        metrics = newMetrics
    }
}

// Preview with sample data
struct ScoreTable_Previews: PreviewProvider {
    static var previews: some View {
        ScoreTable(teams: [
            Team(players: [
                Player(name: "Player 1", bid: 3, took: 2),
                Player(name: "Player 2", bid: 4, took: 3)
            ], hearts: 5, queenSpades: true, moonShot: false),
            Team(players: [
                Player(name: "Player 3", bid: 2, took: 4),
                Player(name: "Player 4", bid: 3, took: 2)
            ], hearts: 3, queenSpades: false, moonShot: true)
        ])
        .frame(width: 800, height: 600)
        .previewLayout(.sizeThatFits)
    }
}
