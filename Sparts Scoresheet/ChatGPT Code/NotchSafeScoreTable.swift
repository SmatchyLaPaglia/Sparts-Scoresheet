//
//  NotchSafeScoreTable.swift
//  Sparts Scoresheet
//

import SwiftUI

struct NotchSafeScoreTable: View {
    // Table size inside the notch-safe span
    var heightPercent: CGFloat = 60
    // Grid shape
    var columns: Int = 16
    var rows: Int = 5

    // Gaps and size
    var gapAfterRows: [Int] = [1, 3]                   // 1-based indices with a gap after
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
            let colW      = rect.width / CGFloat(safeCols)

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
                // ===== Header fill first (so later lines appear on top) =====
                if let headerRect = rowRects.first {
                    Rectangle()
                        .fill(Theme.leftHeaderBg)
                        .frame(width: headerRect.width, height: headerRect.height)
                        .position(x: headerRect.midX, y: headerRect.midY)
                }

                // ===== Row outlines (no base background grid) =====
                Path { p in
                    for r in rowRects { p.addRect(r) }
                }
                .stroke(Theme.gridLine, lineWidth: 1)

                // ===== Vertical dividers, row-aware =====
                // Header (row 1): cut lines at 3,6,9,12,15
                // Rows 2–5: merge 1–3 → skip verticals at 1 and 2
                Path { p in
                    for (idx, r) in rowRects.enumerated() {
                        let rowNumber = idx + 1
                        if rowNumber == 1 {
                            let headerCuts = [3, 6, 9, 12, 15]
                            for i in headerCuts where i < safeCols {
                                let x = CGFloat(i) * colW
                                p.move(to: CGPoint(x: x, y: r.minY))
                                p.addLine(to: CGPoint(x: x, y: r.maxY))
                            }
                        } else {
                            if safeCols > 1 {
                                for i in 1..<safeCols where i != 1 && i != 2 { // merge cols 1–3
                                    let x = CGFloat(i) * colW
                                    p.move(to: CGPoint(x: x, y: r.minY))
                                    p.addLine(to: CGPoint(x: x, y: r.maxY))
                                }
                            }
                        }
                    }
                }
                .stroke(Theme.gridLine, lineWidth: 1)

                // ===== Header outline last (on top) =====
                if let headerRect = rowRects.first {
                    Rectangle()
                        .stroke(Theme.gridLine, lineWidth: 1)
                        .frame(width: headerRect.width, height: headerRect.height)
                        .position(x: headerRect.midX, y: headerRect.midY)
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
            let rr = CGRect(x: 0, y: y, width: tableSize.width, height: rowH)
            rects.append(rr)
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
