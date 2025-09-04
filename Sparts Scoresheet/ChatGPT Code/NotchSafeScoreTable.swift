//
//  NotchSafeScoreTable.swift
//  Sparts Scoresheet
//

import SwiftUI

struct NotchSafeScoreTable: View {
    // Table size inside the notch-safe span
    var heightPercent: CGFloat = 80
    // Grid shape
    var columns: Int = 16
    var rows: Int = 5

    // Rounded row ends (left & right corners per row)
    var rowCornerRadius: CGFloat = 14

    // Gaps that show the phone background between rows (1-based indices)
    var gapAfterRows: [Int] = [1, 3]
    // Gap size relative to screen height
    var rowSeparatorSizeAsPercentOfScreenHeight: CGFloat = 2

    var body: some View {
        NotchSafeView(
            heightPercent: heightPercent,
            paddingPercentNotchSide: 2,
            paddingPercentSideOppositeNotch: 1
        ) { rect in

            // --- Metrics (no control-flow at view level) ---
            let safeCols  = max(columns, 1)
            let safeRows  = max(rows, 1)

            // Gap height is based on *screen* height, not table height
            let screenH   = UIScreen.main.bounds.height
            let gapH      = screenH * (rowSeparatorSizeAsPercentOfScreenHeight / 100)

            // Build row rects (top→bottom) with requested gaps between rows
            let rowRects  = NotchSafeScoreTable.buildRowRects(
                tableSize: rect.size,
                rows: safeRows,
                gapAfterRows: gapAfterRows,
                gapH: gapH
            )

            ZStack {
                // One stack per row so we can clip fills + lines to rounded ends
                ForEach(0..<rowRects.count, id: \.self) { idx in
                    let r = rowRects[idx]
                    let rowNumber = idx + 1
                    let colW = r.width / CGFloat(safeCols)

                    ZStack {
                        // === BACKGROUND FILLS (rounded via clip on container) ===
                        if rowNumber == 1 {
                            // Header is a single band
                            RoundedRectangle(cornerRadius: 0) // local shape, no extra rounding
                                .fill(Theme.leftHeaderBg)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            // Body cell backgrounds in local coords [0..r.width]
                            // 1) Name stripe (merged 1–3), alternating light/dark
                            let nameColor = (rowNumber % 2 == 0) ? Theme.nameStripeDark : Theme.nameStripeLight
                            Rectangle()
                                .fill(nameColor)
                                .frame(width: colW * 3, height: r.height)
                                .position(x: colW * 1.5, y: r.height / 2)

                            // 2) bid/took (col 4)
                            Rectangle()
                                .fill(Theme.leftHeaderBg)
                                .frame(width: colW, height: r.height)
                                .position(x: colW * 3.5, y: r.height / 2)

                            // 3) spades bid/took (cols 5–6) – white
                            Rectangle().fill(Theme.cellBg)
                                .frame(width: colW, height: r.height)
                                .position(x: colW * 4.5, y: r.height / 2)
                            Rectangle().fill(Theme.cellBg)
                                .frame(width: colW, height: r.height)
                                .position(x: colW * 5.5, y: r.height / 2)

                            // 4) hearts / queen / moon (cols 7–9) – dark mini headers
                            Rectangle().fill(Theme.leftHeaderBg)
                                .frame(width: colW, height: r.height)
                                .position(x: colW * 6.5, y: r.height / 2)
                            Rectangle().fill(Theme.leftHeaderBg)
                                .frame(width: colW, height: r.height)
                                .position(x: colW * 7.5, y: r.height / 2)
                            Rectangle().fill(Theme.leftHeaderBg)
                                .frame(width: colW, height: r.height)
                                .position(x: colW * 8.5, y: r.height / 2)

                            // 5) HAND SCORES (cols 10–12)
                            Rectangle().fill(Theme.rightSpadesScoreBg)
                                .frame(width: colW, height: r.height)
                                .position(x: colW * 9.5, y: r.height / 2)
                            Rectangle().fill(Theme.rightHeartsScoreBg)
                                .frame(width: colW, height: r.height)
                                .position(x: colW * 10.5, y: r.height / 2)
                            Rectangle().fill(Theme.rightHandScoreBg)
                                .frame(width: colW, height: r.height)
                                .position(x: colW * 11.5, y: r.height / 2)

                            // 6) TOTAL SCORES (cols 13–15)
                            Rectangle().fill(Theme.rightSpadesTotalBg)
                                .frame(width: colW, height: r.height)
                                .position(x: colW * 12.5, y: r.height / 2)
                            Rectangle().fill(Theme.rightHeartsTotalBg)
                                .frame(width: colW, height: r.height)
                                .position(x: colW * 13.5, y: r.height / 2)
                            Rectangle().fill(Theme.rightAllBagsBg)
                                .frame(width: colW, height: r.height)
                                .position(x: colW * 14.5, y: r.height / 2)

                            // 7) GRAND TOTAL (col 16)
                            if safeCols >= 16 {
                                Rectangle().fill(Theme.rightGameTotalBg)
                                    .frame(width: colW, height: r.height)
                                    .position(x: colW * 15.5, y: r.height / 2)
                            }
                        }

                        // === VERTICAL LINES for THIS ROW (masked to the rounded shape) ===
                        Path { p in
                            if rowNumber == 1 {
                                // Header: cuts only at merge boundaries
                                let cuts = [3, 6, 9, 12, 15]
                                for i in cuts where i < safeCols {
                                    let x = CGFloat(i) * colW
                                    p.move(to: CGPoint(x: x, y: 0))
                                    p.addLine(to: CGPoint(x: x, y: r.height))
                                }
                            } else {
                                // Body: merge 1–3 (skip 1 & 2)
                                if safeCols > 1 {
                                    for i in 1..<safeCols where i != 1 && i != 2 {
                                        let x = CGFloat(i) * colW
                                        p.move(to: CGPoint(x: x, y: 0))
                                        p.addLine(to: CGPoint(x: x, y: r.height))
                                    }
                                }
                            }
                        }
                        .stroke(Theme.gridLine, lineWidth: 1)
                    }
                    // Clip ENTIRE row stack (fills + lines) to rounded ends
                    .clipShape(RoundedRectangle(cornerRadius: rowCornerRadius))
                    // Rounded outline drawn on top; strokeBorder keeps it inside the clip
                    .overlay(
                        RoundedRectangle(cornerRadius: rowCornerRadius)
                            .strokeBorder(Theme.gridLine, lineWidth: 1)
                    )
                    .frame(width: r.width, height: r.height)
                    .position(x: r.midX, y: r.midY)
                }
            }
        }
    }

    // MARK: - Pure helper
    /// Returns uniform-height row rects that exactly fill `tableSize.height`
    /// with `gapH`-tall gaps inserted after rows listed in `gapAfterRows` (1-based).
    private static func buildRowRects(
        tableSize: CGSize,
        rows: Int,
        gapAfterRows: [Int],
        gapH: CGFloat
    ) -> [CGRect] {
        let gapCount = gapAfterRows.count
        let totalGap = CGFloat(gapCount) * gapH
        let rowH = max(0, (tableSize.height - totalGap) / CGFloat(rows))

        var rects: [CGRect] = []
        var y: CGFloat = 0
        for r in 1...rows {
            rects.append(CGRect(x: 0, y: y, width: tableSize.width, height: rowH))
            y += rowH
            if gapAfterRows.contains(r) { y += gapH }
        }
        return rects
    }
}

// MARK: - Preview
#Preview(traits: .landscapeLeft) {
    NotchSafeScoreTable()
}
