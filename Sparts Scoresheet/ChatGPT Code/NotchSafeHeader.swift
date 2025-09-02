//
//  NotchSafeHeader.swift
//  Sparts Scoresheet
//

import SwiftUI

struct NotchSafeHeader: View {
    @StateObject private var orientationManager = OrientationManager()
    @State private var safeAreaInsets: EdgeInsets = .init()

    // Independent knobs for each side
    private let leftPaddingPercent:  CGFloat = 1
    private let rightPaddingPercent: CGFloat = 2.5

    var body: some View {
        GeometryReader { geometry in

            // --- Compute notch edges using DeepSeek helpers ---
            let (leftNotchPos, rightNotchPos) = NotchDetection.detectBothNotchPositions(
                safeAreaInsets: safeAreaInsets,
                screenWidth: geometry.size.width
            )
            let (leftEdgePos, rightEdgePos) = NotchDetection.detectBothPhysicalEdges(
                screenWidth: geometry.size.width
            )

            let isLandscapeRight = (orientationManager.currentLandscapeDirection == .landscapeRight)
            let spanStart: CGFloat = isLandscapeRight ? leftEdgePos   : leftNotchPos
            let spanEnd:   CGFloat = isLandscapeRight ? rightNotchPos : rightEdgePos
            let spanWidth = max(0, spanEnd - spanStart)

            // Apply individual left/right paddings
            let leftPad  = spanWidth * (leftPaddingPercent  / 100)
            let rightPad = spanWidth * (rightPaddingPercent / 100)
            let startX = spanStart + leftPad
            let endX   = spanEnd   - rightPad
            let boxWidth = max(0, endX - startX)

            ZStack {
                // Slightly lighter background so simulator edges are visible
                Color(red: 0.35, green: 0.25, blue: 0.25)
                    .ignoresSafeArea()

                // === Header bar INSIDE the notch-bounded box ===
                Rectangle()
                    .fill(Theme.leftHeaderBg)
                    .overlay(Rectangle().stroke(Theme.gridLine, lineWidth: 1))
                    .frame(width: boxWidth, height: 44)          // header thickness
                    .position(x: startX + boxWidth / 2,
                              y: geometry.size.height / 2)       // centered vertically
            }
            .onAppear { safeAreaInsets = geometry.safeAreaInsets }
            .onChange(of: geometry.size) { _ in
                safeAreaInsets = geometry.safeAreaInsets
            }
        }
        .ignoresSafeArea()
    }
}

// Quick preview
#Preview {
    NotchSafeHeader()
        .previewInterfaceOrientation(.landscapeLeft)
}
