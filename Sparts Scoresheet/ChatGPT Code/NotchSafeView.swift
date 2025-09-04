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

    let content: (_ safeRect: CGRect) -> Content

    init(heightPercent: CGFloat = 100,
         paddingPercentNotchSide: CGFloat = 0,
         paddingPercentSideOppositeNotch: CGFloat = 0,
         @ViewBuilder content: @escaping (_ safeRect: CGRect) -> Content) {
        self.heightPercent = heightPercent
        self.paddingPercentNotchSide = paddingPercentNotchSide
        self.paddingPercentSideOppositeNotch = paddingPercentSideOppositeNotch
        self.content = content
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
                // slightly off-black so simulator bounds are visible
                Color(red: 0.72, green: 0.52, blue: 0.72)
                    .ignoresSafeArea()

                // Base panel matching the safe rect (background + border)
                Rectangle()
                    .fill(Theme.leftHeaderBg)
                    .overlay(Rectangle().stroke(Theme.gridLine, lineWidth: 1))
                    .frame(width: safeRect.width, height: safeRect.height)
                    .position(x: safeRect.midX, y: safeRect.midY)

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


#Preview {
    NotchSafeView() { barRect in
        HStack(spacing: 12) {
            Image(systemName: "square.grid.2x2")
            Text("Sparts Scoresheet")
                .font(.headline)
            Spacer(minLength: 0)
            Image(systemName: "gearshape")
        }
        .padding(.horizontal, 12)
        .frame(maxHeight: .infinity, alignment: .center)
    }
    .previewInterfaceOrientation(.landscapeLeft)
}
