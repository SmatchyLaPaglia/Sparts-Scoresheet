import Foundation
import SwiftUI
import Combine
import CoreMotion
import UIKit


// MARK: - Header Cell Component
struct HeaderCell: View {
    let text: String
    let width: CGFloat
    let height: CGFloat
    
    var body: some View {
        Text(text)
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(Theme.leftHeaderText)
            .multilineTextAlignment(.center)
            .frame(width: width, height: height)
            .background(Theme.leftHeaderBg)
            .overlay(
                Rectangle()
                    .stroke(Theme.gridLine, lineWidth: 1)
            )
    }
}

// MARK: - Main View
struct NotchBoundRectangleView: View {
    @StateObject private var orientationManager = OrientationManager()
    @State private var safeAreaInsets: EdgeInsets = .init()
    @State var horizontalPaddingPercent: Double = 3.0
    
    var body: some View {
        GeometryReader { geometry in
            let (leftNotchPos, rightNotchPos) = NotchDetection.detectBothNotchPositions(
                safeAreaInsets: safeAreaInsets,
                screenWidth: geometry.size.width
            )
            let (leftEdgePos, rightEdgePos) = NotchDetection.detectBothPhysicalEdges(
                screenWidth: geometry.size.width
            )
            
            let isLandscapeRight = (orientationManager.currentLandscapeDirection == .landscapeRight)
            let startX: CGFloat = isLandscapeRight ? leftEdgePos : leftNotchPos
            let endX: CGFloat = isLandscapeRight ? rightNotchPos : rightEdgePos
            let boxWidth = max(0, endX - startX)
            
            // Apply horizontal padding
            let paddingAmount = boxWidth * (horizontalPaddingPercent / 100.0)
            let contentWidth = boxWidth - (paddingAmount * 2)
            let contentStartX = startX + paddingAmount
            
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                // Bounding box (for reference)
                Rectangle()
                    .stroke(Color.yellow, lineWidth: 1)
                    .background(Color.yellow.opacity(0.05))
                    .frame(width: boxWidth, height: geometry.size.height)
                    .position(x: startX + boxWidth / 2, y: geometry.size.height / 2)
                
                // Header row inside the box
                VStack {
                    HStack(spacing: 0) {
                        HeaderCell(text: "TEAMS", width: contentWidth * 0.22, height: 50)
                        HeaderCell(text: "SPADES", width: contentWidth * 0.13, height: 50)
                        HeaderCell(text: "HEARTS", width: contentWidth * 0.16, height: 50)
                        HeaderCell(text: "HAND\nSCORES", width: contentWidth * 0.16, height: 50)
                        HeaderCell(text: "TOTAL\nSCORES", width: contentWidth * 0.16, height: 50)
                        HeaderCell(text: "GRAND\nTOTAL", width: contentWidth * 0.17, height: 50)
                    }
                    .frame(width: contentWidth)
                    .position(x: contentStartX + contentWidth / 2, y: geometry.size.height / 2)
                    
                    Spacer()
                }
            }
            .onAppear { safeAreaInsets = geometry.safeAreaInsets }
            .onChange(of: geometry.size) { _ in
                safeAreaInsets = geometry.safeAreaInsets
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Preview
struct NotchBoundRectangleView_Previews: PreviewProvider {
    static var previews: some View {
        NotchBoundRectangleView()
            .previewInterfaceOrientation(.landscapeLeft)
    }
}
