//
//  ScoreTableWithText.swift
//  Sparts Scoresheet
//
//  Created by Jesse Macbook Clark on 9/4/25.
//


//  NotchSafeScoreTextOverlay.swift
//  Sparts Scoresheet

import SwiftUI

/// Composes the sealed table + a non-interactive text layer that
/// positions labels using the geometry published by the table.
struct ScoreTableWithText: View {
    // Pass through any knobs you want to keep configurable
    var heightPercent: CGFloat = 60
    var columns: Int = 16
    var rows: Int = 5
    var rowCornerRadius: CGFloat = 7
    var gapAfterRows: [Int] = [1, 3]
    var rowSeparatorSizeAsPercentOfScreenHeight: CGFloat = 2

    var body: some View {
        NotchSafeScoreTable(
            heightPercent: heightPercent,
            columns: columns,
            rows: rows,
            rowCornerRadius: rowCornerRadius,
            gapAfterRows: gapAfterRows,
            rowSeparatorSizeAsPercentOfScreenHeight: rowSeparatorSizeAsPercentOfScreenHeight
        )
        .overlayPreferenceValue(ScoreTableLayoutKey.self) { layout in
            GeometryReader { _ in
                if let layout {
                    ScoreTableStaticText(layout: layout,
                                         rowCornerRadius: rowCornerRadius)
                        .allowsHitTesting(false) // purely visual
                }
            }
        }
    }
}

/// The text-only layer. It uses the exact same row clipping
/// so nothing bleeds outside rounded ends.
private struct ScoreTableStaticText: View {
    let layout: ScoreTableLayout
    let rowCornerRadius: CGFloat

    var body: some View {
        ZStack {
            // Header row (row 0)
            if layout.rows > 0, let header = layout.rowRects.first {
                headerLabels(in: header)
                    .frame(width: header.width, height: header.height)
                    .clipShape(RoundedRectangle(cornerRadius: rowCornerRadius))
                    .overlay(RoundedRectangle(cornerRadius: rowCornerRadius).stroke(.clear))
                    .position(x: header.midX, y: header.midY)
            }

            // Body rows (rows 1...N-1) chip labels
            ForEach(1..<layout.rows, id: \.self) { row in
                let r = layout.rowRects[row]
                bodyRowChips(for: row, in: r)
                    .frame(width: r.width, height: r.height)
                    .clipShape(RoundedRectangle(cornerRadius: rowCornerRadius))
                    .overlay(RoundedRectangle(cornerRadius: rowCornerRadius).stroke(.clear))
                    .position(x: r.midX, y: r.midY)
            }
        }
    }

    // MARK: Header labels
    @ViewBuilder
    private func headerLabels(in header: CGRect) -> some View {
        let colW = layout.colWidth
        let fs = unifiedHeaderFontSize(
            specs: [
                .init(text: "TEAMS",         maxWidth: colW*3 - 10, maxHeight: header.height - 8, maxLines: 1),
                .init(text: "SPADES",        maxWidth: colW*3 - 10, maxHeight: header.height - 8, maxLines: 1),
                .init(text: "HEARTS",        maxWidth: colW*3 - 10, maxHeight: header.height - 8, maxLines: 1),
                .init(text: "Hand\nScores",  maxWidth: colW*3 - 10, maxHeight: header.height - 8, maxLines: 2),
                .init(text: "Total\nScores", maxWidth: colW*3 - 10, maxHeight: header.height - 8, maxLines: 2),
                .init(text: "Grand\nTotal",  maxWidth: colW*1 - 10, maxHeight: header.height - 8, maxLines: 2),
            ],
            baseFont: .systemFont(ofSize: 64, weight: .semibold)
        )

        let centers: [CGFloat] = [
            colW * 1.5,   // TEAMS (1–3)
            colW * 4.5,   // SPADES (4–6)
            colW * 7.5,   // HEARTS (7–9)
            colW * 10.5,  // Hand Scores (10–12)
            colW * 13.5,  // Total Scores (13–15)
            colW * 15.5   // Grand Total (16)
        ]
        let labels = ["TEAMS","SPADES","HEARTS","Hand\nScores","Total\nScores","Grand\nTotal"]
        let widths: [CGFloat] = [colW*3, colW*3, colW*3, colW*3, colW*3, colW*1]

        ZStack {
            ForEach(0..<labels.count, id: \.self) { i in
                Text(labels[i])
                    .font(.system(size: fs, weight: .semibold))
                    .foregroundColor(Theme.leftHeaderText)
                    .multilineTextAlignment(.center)
                    .lineLimit(labels[i].contains("\n") ? 2 : 1)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(width: widths[i], height: header.height)
                    .position(x: centers[i], y: header.height/2)
            }
        }
    }

    // MARK: Body “chip” labels per row
    @ViewBuilder
    private func bodyRowChips(for row: Int, in rect: CGRect) -> some View {
        let colW = layout.colWidth
        let chipFS = rect.height * 0.32

        ZStack {
            Text("bid")
                .font(.system(size: chipFS, weight: .semibold))
                .foregroundColor(Theme.leftHeaderText)
                .frame(width: colW, height: rect.height)
                .position(x: colW * 3.5, y: rect.height/2)

            Text("took")
                .font(.system(size: chipFS, weight: .semibold))
                .foregroundColor(Theme.leftHeaderText)
                .frame(width: colW, height: rect.height)
                .position(x: colW * 4.5, y: rect.height/2)

            Text("hearts")
                .font(.system(size: chipFS, weight: .semibold))
                .foregroundColor(Theme.leftHeaderText)
                .frame(width: colW, height: rect.height)
                .position(x: colW * 6.5, y: rect.height/2)

            Text("queen")
                .font(.system(size: chipFS, weight: .semibold))
                .foregroundColor(Theme.leftHeaderText)
                .frame(width: colW, height: rect.height)
                .position(x: colW * 7.5, y: rect.height/2)

            Text("moon")
                .font(.system(size: chipFS, weight: .semibold))
                .foregroundColor(Theme.leftHeaderText)
                .frame(width: colW, height: rect.height)
                .position(x: colW * 8.5, y: rect.height/2)
        }
    }
}

// MARK: - Header font fitting helpers (same API we used earlier)

//struct HeaderSpec {
//    let text: String
//    let maxWidth: CGFloat
//    let maxHeight: CGFloat
//    let maxLines: Int
//}

func unifiedHeaderFontSize(specs: [HeaderSpec], baseFont: UIFont) -> CGFloat {
    guard !specs.isEmpty else { return 14 }
    var best = CGFloat.greatestFiniteMagnitude
    for s in specs {
        let f = fitFontSize(text: s.text,
                            maxWidth: s.maxWidth,
                            maxHeight: s.maxHeight,
                            maxLines: s.maxLines,
                            baseFont: baseFont)
        best = min(best, f)
    }
    return max(8, best)
}

func fitFontSize(text: String,
                 maxWidth: CGFloat,
                 maxHeight: CGFloat,
                 maxLines: Int,
                 baseFont: UIFont) -> CGFloat {
    guard maxWidth > 0, maxHeight > 0 else { return 8 }
    var lo: CGFloat = 6
    var hi: CGFloat = min(maxWidth, maxHeight) * 1.2
    let opts: NSStringDrawingOptions = [.usesLineFragmentOrigin, .usesFontLeading]

    for _ in 0..<18 {
        let mid = (lo + hi) / 2
        let f = baseFont.withSize(mid)
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        style.lineBreakMode = .byWordWrapping

        let attr: [NSAttributedString.Key: Any] = [
            .font: f,
            .paragraphStyle: style
        ]
        let box = CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude)
        let rect = (text as NSString).boundingRect(with: box, options: opts, attributes: attr, context: nil)

        // crude line-count check: assume ~1.2x line height
        let lineH = f.lineHeight
        let lines = max(1, Int(ceil(rect.height / max(lineH, 1))))
        let fits = rect.width <= maxWidth && rect.height <= maxHeight && lines <= maxLines

        if fits { lo = mid } else { hi = mid }
    }
    return floor(lo)
}

// MARK: - Preview

#Preview(traits: .landscapeLeft) {
    ScoreTableWithText()
}
