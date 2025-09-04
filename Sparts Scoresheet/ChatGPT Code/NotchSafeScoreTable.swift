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
                
                // Header fill first (unchanged)
                if let headerRect = rowRects.first {
                    Rectangle()
                        .fill(Theme.leftHeaderBg)
                        .frame(width: headerRect.width, height: headerRect.height)
                        .position(x: headerRect.midX, y: headerRect.midY)
                }

                // NEW: paint body cell backgrounds behind the lines
                let fills = NotchSafeScoreTable.buildBodyFills(rowRects: rowRects, cols: safeCols, colW: colW)
                ForEach(0..<fills.count, id: \.self) { i in
                    let f = fills[i]
                    Rectangle()
                        .fill(f.color)
                        .frame(width: f.rect.width, height: f.rect.height)
                        .position(x: f.rect.midX, y: f.rect.midY)
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
    
    private struct CellFill { let rect: CGRect; let color: Color }

    private static func buildBodyFills(
        rowRects: [CGRect],
        cols: Int,
        colW: CGFloat
    ) -> [CellFill] {
        guard rowRects.count >= 2 else { return [] }           // rows 2–N only
        var fills: [CellFill] = []

        func colRect(_ c0: Int, _ c1Exclusive: Int, in row: CGRect) -> CGRect {
            let x0 = CGFloat(c0) * colW
            let w  = CGFloat(c1Exclusive - c0) * colW
            return CGRect(x: row.minX + x0, y: row.minY, width: w, height: row.height)
        }

        for (i, row) in rowRects.enumerated() where i >= 1 {   // 1-based rows 2..N
            let r = i + 1                                      // 1-based index
            // Name stripe (merged 1–3), alternating light/dark
            let nameColor = (r % 2 == 0) ? Theme.nameStripeDark : Theme.nameStripeLight
            fills.append(.init(rect: colRect(0, 3, in: row), color: nameColor))

            // bid/took (col 4)
            fills.append(.init(rect: colRect(3, 4, in: row), color: Theme.leftHeaderBg))

            // spades bid/took (cols 5–6) – white
            fills.append(.init(rect: colRect(4, 5, in: row), color: Theme.cellBg))
            fills.append(.init(rect: colRect(5, 6, in: row), color: Theme.cellBg))

            // hearts / queen / moon (cols 7–9) – dark mini headers
            fills.append(.init(rect: colRect(6, 7, in: row), color: Theme.leftHeaderBg))
            fills.append(.init(rect: colRect(7, 8, in: row), color: Theme.leftHeaderBg))
            fills.append(.init(rect: colRect(8, 9, in: row), color: Theme.leftHeaderBg))

            // HAND SCORES (cols 10–12)
            fills.append(.init(rect: colRect(9, 10, in: row), color: Theme.rightSpadesScoreBg))
            fills.append(.init(rect: colRect(10, 11, in: row), color: Theme.rightHeartsScoreBg))
            fills.append(.init(rect: colRect(11, 12, in: row), color: Theme.rightHandScoreBg))

            // TOTAL SCORES (cols 13–15)
            fills.append(.init(rect: colRect(12, 13, in: row), color: Theme.rightSpadesTotalBg))
            fills.append(.init(rect: colRect(13, 14, in: row), color: Theme.rightHeartsTotalBg))
            fills.append(.init(rect: colRect(14, 15, in: row), color: Theme.rightAllBagsBg))

            // GRAND TOTAL (col 16)
            if cols >= 16 {
                fills.append(.init(rect: colRect(15, 16, in: row), color: Theme.rightGameTotalBg))
            }
        }
        return fills
    }
}

// MARK: - Preview
#Preview(traits: .landscapeLeft) {
    NotchSafeScoreTable()
}
