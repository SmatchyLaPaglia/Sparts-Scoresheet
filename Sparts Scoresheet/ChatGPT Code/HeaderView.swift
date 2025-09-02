//
//  NotchBoundHeaderOnlyView.swift
//  Sparts Scoresheet
//

import SwiftUI

struct NotchBoundHeaderOnlyView: View {
    @StateObject private var orientationManager = OrientationManager()
    @State private var safeAreaInsets: EdgeInsets = .init()

    // 0 = stretch exactly from notch line to opposite physical edge
    private let horizontalTablePaddingPercent: CGFloat = 0

    // Left / Right table proportions (match Codea)
    private let leftTableWidthPercent: CGFloat = 36
    private let gapTablesPercent:      CGFloat = 0
    private let rightCols:             CGFloat = 7

    // Left table internal fractions
    private let nameFrac:   CGFloat = 0.44
    private let narrowFrac: CGFloat = 0.12   // SPADES uses 3× this
    private let heartsFrac: CGFloat = 0.12   // HEARTS uses 3× this

    // Header height clamp (Codea: 28…64)
    private let headerHMin: CGFloat = 28
    private let headerHMax: CGFloat = 64

    var body: some View {
        GeometryReader { geometry in
            // --- Use the same notch span math as NotchBoundBoxView ---
            let (leftNotchPos, rightNotchPos) = NotchDetection.detectBothNotchPositions(
                safeAreaInsets: safeAreaInsets,
                screenWidth: geometry.size.width
            )
            let (leftEdgePos, rightEdgePos) = NotchDetection.detectBothPhysicalEdges(
                screenWidth: geometry.size.width
            )

            let isLandscapeRight = (orientationManager.currentLandscapeDirection == .landscapeRight)
            // Notch on RIGHT => span LEFT edge -> RIGHT notch
            // Notch on LEFT  => span LEFT notch -> RIGHT edge
            let startX: CGFloat = isLandscapeRight ? leftEdgePos   : leftNotchPos
            let endX:   CGFloat = isLandscapeRight ? rightNotchPos : rightEdgePos
            let spanW            = max(0, endX - startX)

            // Header geometry
            let headerH = max(headerHMin, min(headerHMax, geometry.size.height / 7.0))
            let padX    = spanW * (horizontalTablePaddingPercent / 100)
            let baseX   = startX + padX
            let totalW  = max(0, spanW - 2*padX)
            let yTop    = (geometry.size.height - headerH) / 2.0  // center vertically

            // Width math (with the “bump” of 1 right col into name)
            let leftW0  = totalW * (leftTableWidthPercent / 100)
            let gapW    = totalW * (gapTablesPercent / 100)
            let rightW0 = max(0, totalW - leftW0 - gapW)

            let wScore0 = rightW0 / rightCols
            let bumpW   = wScore0

            let wName   = leftW0 * nameFrac   + bumpW
            let wNarrow = leftW0 * narrowFrac
            let wHearts = leftW0 * heartsFrac

            let rightW  = max(0, rightW0 - bumpW)
            let wScore  = rightW / rightCols

            // Precompute X positions (no mutation in ViewBuilder)
            let hx0 = baseX                       // TEAMS
            let hx1 = hx0 + wName                 // SPADES group (3× narrow)
            let hx2 = hx1 + wNarrow * 3           // HEARTS group (3× hearts)
            let hx3 = hx2 + wHearts * 3           // potential gap
            let rightStartX = hx3 + gapW

            let handX  = rightStartX
            let totalX = handX  + wScore * 3
            let grandX = totalX + wScore * 3

            ZStack {
                // dev bg so you can see the clamp (remove later)
                Color.black.ignoresSafeArea()

                // Thin guide showing the exact lateral box we’re allowed to use
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.yellow.opacity(0.35), lineWidth: 1)
                    .frame(width: totalW, height: headerH)
                    .position(x: baseX + totalW/2, y: yTop + headerH/2)

                // ===== Header cells — EXACT Codea order =====
                Group {
                    cell(hx0, yTop, wName,      headerH, Theme.leftHeaderBg,
                         "TEAMS",         Theme.leftHeaderText, headerH)

                    cell(hx1, yTop, wNarrow*3,  headerH, Theme.leftHeaderBg,
                         "SPADES",        Theme.leftHeaderText, headerH)

                    cell(hx2, yTop, wHearts*3,  headerH, Theme.leftHeaderBg,
                         "HEARTS",        Theme.leftHeaderText, headerH)

                    if gapW > 0 {
                        cell(hx3, yTop, gapW, headerH, Theme.leftHeaderBg,
                             nil, .clear, headerH)
                    }

                    cell(handX,  yTop, wScore*3, headerH, Theme.leftHeaderBg,
                         "HAND\nSCORES",  Theme.leftHeaderText, headerH, lines: 2)

                    cell(totalX, yTop, wScore*3, headerH, Theme.leftHeaderBg,
                         "TOTAL\nSCORES", Theme.leftHeaderText, headerH, lines: 2)

                    cell(grandX, yTop, wScore*1, headerH, Theme.leftHeaderBg,
                         "GRAND\nTOTAL",  Theme.leftHeaderText, headerH, lines: 2)
                }
            }
            .onAppear { safeAreaInsets = geometry.safeAreaInsets }
            .onChange(of: geometry.size) { _ in
                safeAreaInsets = geometry.safeAreaInsets
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Codea-style cell primitive
    @ViewBuilder
    private func cell(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat,
                      _ bg: Color, _ title: String?, _ fg: Color, _ refH: CGFloat,
                      lines: Int = 1) -> some View {
        ZStack {
            bg
            if let t = title, !t.isEmpty {
                Text(t)
                    .font(.system(size: max(10, refH * 0.34), weight: .bold))
                    .minimumScaleFactor(0.6)
                    .lineLimit(lines)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(fg)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, 6)
            }
        }
        .overlay(Rectangle().stroke(Theme.gridLine, lineWidth: 1))
        .frame(width: w, height: h)
        .position(x: x + w/2, y: y + h/2)
    }
}

// Preview
#Preview("Header (clamped to notch span)") {
    NotchBoundHeaderOnlyView()
        .previewInterfaceOrientation(.landscapeLeft)
}
