//
//  NotchSafeView.swift
//  Sparts Scoresheet
//

import SwiftUI

struct NotchSafeView<Content: View>: View {
    @StateObject private var orientationManager = OrientationManager()
    @State private var safeAreaInsets: EdgeInsets = .init()

    private let paddingPercentNotchSide:         CGFloat
    private let paddingPercentSideOppositeNotch: CGFloat
    private let heightPercent: CGFloat

    // Whether to draw the built-in base panel (only when no custom content provided)
    private let shouldDrawBasePanel: Bool

    let content: (_ safeRect: CGRect) -> Content

    // MARK: Primary init — custom content provided → do NOT draw base panel
    init(
        heightPercent: CGFloat = 100,
        paddingPercentNotchSide: CGFloat = 0,
        paddingPercentSideOppositeNotch: CGFloat = 0,
        @ViewBuilder content: @escaping (_ safeRect: CGRect) -> Content
    ) {
        self.heightPercent = heightPercent
        self.paddingPercentNotchSide = paddingPercentNotchSide
        self.paddingPercentSideOppositeNotch = paddingPercentSideOppositeNotch
        self.content = content
        self.shouldDrawBasePanel = false
    }

    // MARK: Convenience init — no content provided → draw base panel
    init(
        heightPercent: CGFloat = 100,
        paddingPercentNotchSide: CGFloat = 0,
        paddingPercentSideOppositeNotch: CGFloat = 0
    ) where Content == EmptyView {
        self.heightPercent = heightPercent
        self.paddingPercentNotchSide = paddingPercentNotchSide
        self.paddingPercentSideOppositeNotch = paddingPercentSideOppositeNotch
        self.content = { _ in EmptyView() }
        self.shouldDrawBasePanel = true
    }

    var body: some View {
        GeometryReader { geometry in
            // --- Compute notch + edge span (DON'T TOUCH THIS) ---
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
            let spanWidth         = max(0, spanEnd - spanStart)

            let notchPad    = spanWidth * (paddingPercentNotchSide / 100)
            let oppositePad = spanWidth * (paddingPercentSideOppositeNotch / 100)

            let startX: CGFloat = isLandscapeRight ? (spanStart + oppositePad) : (spanStart + notchPad)
            let endX:   CGFloat = isLandscapeRight ? (spanEnd   - notchPad)    : (spanEnd   - oppositePad)
            let width          = max(0, endX - startX)

            let height   = max(0, geometry.size.height * (heightPercent / 100))
            let centerY  = geometry.size.height / 2
            let safeRect = CGRect(x: startX,
                                  y: centerY - height/2,
                                  width: width,
                                  height: height)

            ZStack {
                // Only draw the purple backdrop when we're drawing the built-in base panel
                if shouldDrawBasePanel {
                    Color(red: 0.72, green: 0.52, blue: 0.72)
                        .ignoresSafeArea()
                }

                // Draw our base panel ONLY when no custom content was provided
                if shouldDrawBasePanel {
                    Rectangle()
                        .fill(Theme.nameStripeLight)
                        .overlay(Rectangle().stroke(Theme.leftHeaderBg, lineWidth: 1))
                        .frame(width: safeRect.width, height: safeRect.height)
                        .position(x: safeRect.midX, y: safeRect.midY)
                }

                // Caller-provided content, pinned to the same rect
                content(safeRect)
                    .frame(width: safeRect.width, height: safeRect.height)
                    .position(x: safeRect.midX, y: safeRect.midY)
            }
            .onAppear { safeAreaInsets = geometry.safeAreaInsets }
            .onChange(of: geometry.size) { _ in safeAreaInsets = geometry.safeAreaInsets }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Previews

#Preview("With base panel", traits: .landscapeLeft) {
    // Uses the convenience init → draws its own panel
    NotchSafeView(heightPercent: 100, paddingPercentNotchSide: 0, paddingPercentSideOppositeNotch: 0)
}

#Preview("With custom content", traits: .landscapeLeft) {
    // Uses the primary init (with content) → suppresses base panel
    NotchSafeView(heightPercent: 70, paddingPercentNotchSide: 3, paddingPercentSideOppositeNotch: 3) { safeRect in
        RoundedRectangle(cornerRadius: 8).stroke(.yellow, lineWidth: 2)
    }
}
