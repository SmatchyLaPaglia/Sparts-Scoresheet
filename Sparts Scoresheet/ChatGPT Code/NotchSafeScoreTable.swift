//
//  NotchSafeScoreTable.swift
//  Sparts Scoresheet
//

import SwiftUI

struct NotchSafeScoreTable: View {
    // You can tweak these; 100 means full height inside the safe span.
    var heightPercent: CGFloat = 60
    var columns: Int = 16
    var rows: Int = 5

    var body: some View {
        NotchSafeView(heightPercent: heightPercent,
                      paddingPercentNotchSide: 2,
                      paddingPercentSideOppositeNotch: 1) { rect in

            // Precompute column/row sizes once
            let colW = rect.width / CGFloat(max(columns, 1))
            let rowH = rect.height / CGFloat(max(rows, 1))

            ZStack {
                // ===== Vertical dividers across whole table (unchanged) =====
                Path { p in
                    for i in 1..<columns {
                        let x = CGFloat(i) * colW
                        p.move(to: CGPoint(x: x, y: 0))
                        p.addLine(to: CGPoint(x: x, y: rect.height))
                    }
                }
                .stroke(Theme.gridLine, lineWidth: 1)

                // ===== Horizontal dividers (explicit, not a loop) =====
                // y positions of the boundaries below each row:
                // 0 (top), rowH (after header), 2*rowH, 3*rowH (TEAM GAP), 4*rowH, 5*rowH (bottom)
                // Regular lines:
                Path { p in
                    // after header
                    p.move(to: CGPoint(x: 0, y: rowH))
                    p.addLine(to: CGPoint(x: rect.width, y: rowH))
                    // between team 1 players (rows 1 & 2)
                    p.move(to: CGPoint(x: 0, y: rowH * 2))
                    p.addLine(to: CGPoint(x: rect.width, y: rowH * 2))
                    // between team 2 players (rows 3 & 4)
                    p.move(to: CGPoint(x: 0, y: rowH * 4))
                    p.addLine(to: CGPoint(x: rect.width, y: rowH * 4))
                }
                .stroke(Theme.gridLine, lineWidth: 1)

                // Thicker team boundary between rows 2 and 3 (double stroke)
                Path { p in
                    let y = rowH * 3
                    p.move(to: CGPoint(x: 0, y: y - 1))
                    p.addLine(to: CGPoint(x: rect.width, y: y - 1))
                    p.move(to: CGPoint(x: 0, y: y + 1))
                    p.addLine(to: CGPoint(x: rect.width, y: y + 1))
                }
                .stroke(Theme.gridLine, lineWidth: 1)

                // ===== Top-row merges =====
                // Fill the entire header row to hide interior verticals
                Rectangle()
                    .fill(Theme.leftHeaderBg)
                    .frame(width: rect.width, height: rowH)
                    .position(x: rect.width / 2, y: rowH / 2)

                // Outline the header row
                Rectangle()
                    .stroke(Theme.gridLine, lineWidth: 1)
                    .frame(width: rect.width, height: rowH)
                    .position(x: rect.width / 2, y: rowH / 2)

                // Redraw only the desired cut lines in header:
                // after cols 3, 6, 9, 12, 15  → merges: 1–3, 4–6, 7–9, 10–12, 13–15, and 16 alone
                Path { p in
                    let cutIndices: [Int] = [3, 6, 9, 12, 15]
                    for i in cutIndices {
                        let x = CGFloat(i) * colW
                        p.move(to: CGPoint(x: x, y: 0))
                        p.addLine(to: CGPoint(x: x, y: rowH))
                    }
                }
                .stroke(Theme.gridLine, lineWidth: 1)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    NotchSafeScoreTable()
        .previewInterfaceOrientation(.landscapeLeft)
}
