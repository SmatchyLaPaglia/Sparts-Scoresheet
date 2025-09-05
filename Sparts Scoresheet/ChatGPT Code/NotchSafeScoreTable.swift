//
//  NotchSafeScoreTable.swift
//  Sparts Scoresheet
//

import SwiftUI

struct NotchSafeScoreTable: View {
    // Table size inside the notch-safe span
    var heightPercent: CGFloat = 50
    // Grid shape
    var columns: Int = 16
    var rows: Int = 5

    // Rounded row ends (left & right corners per row)
    var rowCornerRadius: CGFloat = 7

    // Gaps that show the phone background between rows (1-based indices)
    var gapAfterRows: [Int] = [1, 3]
    // Gap size relative to screen height
    var rowSeparatorSizeAsPercentOfScreenHeight: CGFloat = 1.5

    var body: some View {
        ZStack{
            Color.gray
            NotchSafeView(
                heightPercent: heightPercent,
                paddingPercentNotchSide: 1.25,
                paddingPercentSideOppositeNotch: 0.25
            ) { rect in
                
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
                
                let layout = ScoreTableLayout(tableRect: rect,
                                              rows: safeRows,
                                              cols: safeCols,
                                              rowRects: rowRects,
                                              colWidth: rect.width / CGFloat(safeCols))
                
                ZStack {
                    // One stack per row so we can clip fills + lines to rounded ends
                    ForEach(0..<rowRects.count, id: \.self) { idx in
                        let r = rowRects[idx]
                        let rowNumber = idx + 1               // 1-based
                        let colW = r.width / CGFloat(safeCols)
                        
                        ZStack {
                            // === BACKGROUND FILLS (rounded via clip on container) ===
                            if rowNumber == 1 {
                                // Header is a single band (can also be overridden per-cell if desired)
                                Rectangle()
                                    .fill(Theme.leftHeaderBg)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                            } else {
                                // Draw each column’s background for this row
                                ForEach(1...safeCols, id: \.self) { col in
                                    let color = colorForCell(row: rowNumber, col: col, totalCols: safeCols)
                                    if let color {
                                        Rectangle()
                                            .fill(color)
                                            .frame(width: colW, height: r.height)
                                            .position(x: (CGFloat(col) - 0.5) * colW, y: r.height / 2)
                                    }
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
                                    // Body: merge 1–3 (skip lines at 1 & 2)
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
                .preference(key: ScoreTableLayoutKey.self, value: layout)
            }
        }
        .ignoresSafeArea(.all)
    }

    // MARK: - Default color scheme + overrides

    /// Returns the background color for a cell (1-based row/col) if any.
    /// Checks overrides first, then falls back to a default scheme.
    private func colorForCell(row: Int, col: Int, totalCols: Int) -> Color? {
        
        // Default scheme
        if row == 1 {
            // Header band
            return Theme.leftHeaderBg
        } else if row == 2 || row == 4 {
            // Team headers
            if col > 9 {
                return Theme.leftHeaderBg
            }
        }

        // Body rows default:
        //  - Cols 1–3: alternating name stripe
        //  - Col 4: leftHeaderBg
        //  - Cols 5–6: white
        //  - Cols 7–9: leftHeaderBg
        //  - 10: rightSpadesScoreBg
        //  - 11: rightHeartsScoreBg
        //  - 12: rightHandScoreBg
        //  - 13: rightSpadesTotalBg
        //  - 14: rightHeartsTotalBg
        //  - 15: rightAllBagsBg
        //  - 16: rightGameTotalBg (if present)
        switch col {
        case 1...3:
            return (row % 2 == 0) ? Theme.nameStripeDark : Theme.nameStripeLight
        case 4:
            return Theme.leftHeaderBg
        case 5, 6:
            if row == 2 || row == 4 {
                return Theme.nameStripeDark
            } else {
                return Theme.nameStripeLight
            }
        case 7, 8, 9:
            if row == 3 || row == 5 {
                return Theme.nameStripeLight
            } else {
                return Theme.leftHeaderBg
            }
        case 10:
            return Theme.rightSpadesScoreBg
        case 11:
            return Theme.rightHeartsScoreBg
        case 12:
            return Theme.rightHandScoreBg
        case 13:
            return Theme.rightSpadesTotalBg
        case 14:
            return Theme.rightHeartsTotalBg
        case 15:
            return Theme.rightAllBagsBg
        case 16 where totalCols >= 16:
            return Theme.rightGameTotalBg
        default:
            return nil
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
    // Example manual overrides:
    // Rows 3 and 5 → cols 5..7 set to nameStripeDark
//    let overrides: [Int: [Int: Color]] = [
//        3: [5: Theme.nameStripeDark, 6: Theme.nameStripeDark, 7: Theme.nameStripeDark],
//        5: [5: Theme.nameStripeDark, 6: Theme.nameStripeDark, 7: Theme.nameStripeDark]
//    ]

    return NotchSafeScoreTable()
}
