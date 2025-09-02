import Foundation
import SwiftUI
import Combine
import CoreMotion
import UIKit

// MARK: - Layout Metrics
struct LayoutMetrics {
    let innerX: CGFloat
    let innerY: CGFloat
    let innerW: CGFloat
    let innerH: CGFloat
    let leftW: CGFloat
    let gapW: CGFloat
    let rightW: CGFloat
    let headerH: CGFloat
    let rowH: CGFloat
    
    let wName: CGFloat
    let wNarrow: CGFloat
    let wHearts: CGFloat
    let wScore: CGFloat
    
    init(geometry: GeometryProxy, safeAreaInsets: EdgeInsets, orientation: LandscapeDirection, horizontalPaddingPercent: Double) {
        // Calculate safe drawing area
        let (leftNotchPos, rightNotchPos) = NotchDetection.detectBothNotchPositions(
            safeAreaInsets: safeAreaInsets,
            screenWidth: geometry.size.width
        )
        let (leftEdgePos, rightEdgePos) = NotchDetection.detectBothPhysicalEdges(
            screenWidth: geometry.size.width
        )
        
        let isLandscapeRight = (orientation == .landscapeRight)
        let startX: CGFloat = isLandscapeRight ? leftEdgePos : leftNotchPos
        let endX: CGFloat = isLandscapeRight ? rightNotchPos : rightEdgePos
        let safeW = max(0, endX - startX)
        let safeH = geometry.size.height
        
        // Apply horizontal padding
        let horizontalPadding = safeW * (horizontalPaddingPercent / 100.0)
        self.innerW = safeW - (horizontalPadding * 2)
        self.innerX = startX + horizontalPadding
        self.innerY = 0
        self.innerH = safeH
        
        // Table layout (like Codea)
        let leftTableWidthPercent: CGFloat = 65.0
        let gapTablesPercent: CGFloat = 2.0
        
        self.leftW = innerW * leftTableWidthPercent / 100
        self.gapW = innerW * gapTablesPercent / 100
        self.rightW = max(0, innerW - leftW - gapW)
        
        self.headerH = 50
        self.rowH = 40
        
        // Left table column widths (like Codea LeftCols)
        let nameFrac: CGFloat = 0.35
        let narrowFrac: CGFloat = 0.12
        let heartsFrac: CGFloat = 0.15
        
        self.wName = leftW * nameFrac
        self.wNarrow = leftW * narrowFrac
        self.wHearts = leftW * heartsFrac
        
        // Right table score column width
        let rightCols: CGFloat = 7
        self.wScore = rightW / rightCols
    }
}


struct PlayerNameCell: View {
    let name: String
    let width: CGFloat
    let height: CGFloat
    
    var body: some View {
        Text(name)
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(Theme.textOnLight)
            .frame(width: width, height: height)
            .background(Theme.nameStripeLight)
            .overlay(
                Rectangle()
                    .stroke(Theme.gridLine, lineWidth: 1)
            )
    }
}

struct LabelCell: View {
    let text: String
    let width: CGFloat
    let height: CGFloat
    
    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(Theme.leftHeaderText)
            .frame(width: width, height: height)
            .background(Theme.leftHeaderBg)
            .overlay(
                Rectangle()
                    .stroke(Theme.gridLine, lineWidth: 1)
            )
    }
}

struct ValueCell: View {
    let text: String
    let width: CGFloat
    let height: CGFloat
    
    var body: some View {
        Text(text)
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(Theme.textDisabled)
            .frame(width: width, height: height)
            .background(Theme.cellBg)
            .overlay(
                Rectangle()
                    .stroke(Theme.gridLine, lineWidth: 1)
            )
    }
}

// MARK: - Main View
struct NotchBoundTableView: View {
    @StateObject private var orientationManager = OrientationManager()
    @State private var safeAreaInsets: EdgeInsets = .init()
    @State var horizontalPaddingPercent: Double = 3.0
    
    var body: some View {
        GeometryReader { geometry in
            let metrics = LayoutMetrics(
                geometry: geometry,
                safeAreaInsets: safeAreaInsets,
                orientation: orientationManager.currentLandscapeDirection,
                horizontalPaddingPercent: horizontalPaddingPercent
            )
            
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                ZStack {
                    Color.black
                        .ignoresSafeArea()
                    
                    // Draw table within the safe bounds
                    VStack(spacing: 0) {
                        // Header row
                        HStack(spacing: 0) {
                            HeaderCell(text: "TEAMS", width: metrics.wName, height: metrics.headerH)
                            HeaderCell(text: "SPADES", width: metrics.wNarrow * 3, height: metrics.headerH)
                            HeaderCell(text: "HEARTS", width: metrics.wHearts * 3, height: metrics.headerH)
                            HeaderCell(text: "HAND\nSCORES", width: metrics.wScore * 3, height: metrics.headerH)
                            HeaderCell(text: "TOTAL\nSCORES", width: metrics.wScore * 3, height: metrics.headerH)
                            HeaderCell(text: "GRAND\nTOTAL", width: metrics.wScore, height: metrics.headerH)
                        }
                        
                        // First player row (Lecia)
                        HStack(spacing: 0) {
                            // Name
                            PlayerNameCell(name: "Lecia", width: metrics.wName, height: metrics.rowH)
                            
                            // bid/took label
                            LabelCell(text: "bid/took", width: metrics.wNarrow, height: metrics.rowH)
                            
                            // bid value
                            ValueCell(text: "--", width: metrics.wNarrow, height: metrics.rowH)
                            
                            // took value
                            ValueCell(text: "--", width: metrics.wNarrow, height: metrics.rowH)
                            
                            // hearts label
                            LabelCell(text: "hearts", width: metrics.wHearts, height: metrics.rowH)
                            
                            // queen label
                            LabelCell(text: "queen", width: metrics.wHearts, height: metrics.rowH)
                            
                            // moon label
                            LabelCell(text: "moon", width: metrics.wHearts, height: metrics.rowH)
                            
                            // Right side mini headers
                            LabelCell(text: "SPADES", width: metrics.wScore, height: metrics.rowH)
                            LabelCell(text: "HEARTS", width: metrics.wScore, height: metrics.rowH)
                            LabelCell(text: "BAGS", width: metrics.wScore, height: metrics.rowH)
                            LabelCell(text: "SPADES", width: metrics.wScore, height: metrics.rowH)
                            LabelCell(text: "HEARTS", width: metrics.wScore, height: metrics.rowH)
                            LabelCell(text: "BAGS", width: metrics.wScore, height: metrics.rowH)
                            LabelCell(text: "GAME\nTOTAL", width: metrics.wScore, height: metrics.rowH)
                        }
                        
                        Spacer()
                    }
                    .frame(width: metrics.innerW, height: metrics.innerH, alignment: .top)
                    .position(x: metrics.innerX + metrics.innerW / 2, y: metrics.innerY + metrics.innerH / 2)
                }
                .onAppear { safeAreaInsets = geometry.safeAreaInsets }
 
            }
            .ignoresSafeArea()
        }
    }
    
    // MARK: - Preview
    struct NotchBoundTableView_Previews: PreviewProvider {
        static var previews: some View {
            NotchBoundTableView()
                .previewInterfaceOrientation(.landscapeLeft)
        }
    }
}
