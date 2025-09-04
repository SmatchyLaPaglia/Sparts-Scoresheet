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

    // NEW: gaps and size
    var gapAfterRows: [Int] = [1, 3]                   // 1-based row indices with a gap after
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
                // ===== Row borders (each row drawn independently) =====
                Path { p in
                    for r in rowRects { p.addRect(r) }
                }
                .stroke(Theme.gridLine, lineWidth: 1)

                // ===== Vertical dividers, only inside row rects (skip the gaps) =====
                Path { p in
                    for i in 1..<safeCols {
                        let x = CGFloat(i) * colW
                        for r in rowRects {
                            p.move(to: CGPoint(x: x, y: r.minY))
                            p.addLine(to: CGPoint(x: x, y: r.maxY))
                        }
                    }
                }
                .stroke(Theme.gridLine, lineWidth: 1)

                // ===== Header merges (top row only) =====
                if let headerRect = rowRects.first {
                    // Fill to hide the interior verticals inside the header
                    Rectangle()
                        .fill(Theme.leftHeaderBg)
                        .frame(width: headerRect.width, height: headerRect.height)
                        .position(x: headerRect.midX, y: headerRect.midY)

                    // Header outline
                    Rectangle()
                        .stroke(Theme.gridLine, lineWidth: 1)
                        .frame(width: headerRect.width, height: headerRect.height)
                        .position(x: headerRect.midX, y: headerRect.midY)

                    // Re-draw only the desired cut lines inside the header:
                    // after cols 3, 6, 9, 12, 15  → merges: 1–3, 4–6, 7–9, 10–12, 13–15, 16 alone
                    Path { p in
                        let cutIndices: [Int] = [3, 6, 9, 12, 15]
                        for i in cutIndices {
                            let x = CGFloat(i) * colW
                            p.move(to: CGPoint(x: x, y: headerRect.minY))
                            p.addLine(to: CGPoint(x: x, y: headerRect.maxY))
                        }
                    }
                    .stroke(Theme.gridLine, lineWidth: 1)
                }
            }
        }
    }

    // MARK: - Pure helper (keeps control flow out of ViewBuilder)
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
            if gapAfterRows.contains(r) {
                y += gapH
            }
        }
        return rects
    }
}

// MARK: - Preview
#Preview(traits: .landscapeLeft) {
    NotchSafeScoreTable()
}
