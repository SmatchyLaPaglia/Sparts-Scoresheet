//
//  NotchBoundBoxView.swift
//  Sparts Scoresheet
//
//  Created by Jesse Macbook Clark on 9/1/25.
//


import SwiftUI

struct NotchBoundBoxView: View {
    @StateObject private var orientationManager = OrientationManager()
    @State private var safeAreaInsets: EdgeInsets = .init()

    var body: some View {
        GeometryReader { geometry in

            // Precompute start and end X **outside** of the ViewBuilder
            // --- Compute edges using DeepSeek helpers ---
            let (leftNotchPos, rightNotchPos) = NotchDetection.detectBothNotchPositions(
                safeAreaInsets: safeAreaInsets,
                screenWidth: geometry.size.width
            )
            let (leftEdgePos, rightEdgePos) = NotchDetection.detectBothPhysicalEdges(
                screenWidth: geometry.size.width
            )

            // Replace the if/else assignments with pure lets:
            let isLandscapeRight = (orientationManager.currentLandscapeDirection == .landscapeRight)
            // Notch on RIGHT: span LEFT physical edge -> RIGHT notch
            // Notch on LEFT:  span LEFT notch        -> RIGHT physical edge
            let startX: CGFloat = isLandscapeRight ? leftEdgePos   : leftNotchPos
            let endX:   CGFloat = isLandscapeRight ? rightNotchPos : rightEdgePos
            let boxWidth = max(0, endX - startX)

            ZStack {
                // Dark gray background so you can see edges
                Color(white: 0.18)
                    .ignoresSafeArea()

                // The yellow rectangle
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.yellow, lineWidth: 2)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.yellow.opacity(0.10))
                    )
                    .frame(width: boxWidth, height: geometry.size.height)
                    .position(x: startX + boxWidth / 2,
                              y: geometry.size.height / 2)
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
    NotchBoundBoxView()
}
