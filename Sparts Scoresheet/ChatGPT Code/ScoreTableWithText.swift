//
//  ScoreTableWithText.swift
//  Sparts Scoresheet
//

import SwiftUI

// 1-based address (matches what the table publishes)
public struct CellIndex: Hashable {
    public let row: Int
    public let col: Int
    public init(row: Int, col: Int) { self.row = row; self.col = col }
}

// Simple text spec per cell
public struct CellTextSpec {
    public var text: String
    public var color: Color = Theme.leftHeaderText
    public var weight: Font.Weight = .semibold
    /// If nil, we use rowHeight * 0.42
    public var fontScale: CGFloat? = nil
    public var maxLines: Int = 1
    init(_ text: String,
                color: Color = Theme.leftHeaderText,
                weight: Font.Weight = .semibold,
                fontScale: CGFloat? = nil,
                maxLines: Int = 1) {
        self.text = text
        self.color = color
        self.weight = weight
        self.fontScale = fontScale
        self.maxLines = maxLines
    }
}

/// Composes the sealed table plus a **pure text layer**.
/// You provide `textForCell(row,col)` to control any body cell.
/// Header titles are a separate array because that row has merged cells.
struct ScoreTableWithText: View {
    // passthrough knobs
    var heightPercent: CGFloat = 60
    var columns: Int = 16
    var rows: Int = 5
    var rowCornerRadius: CGFloat = 7
    var gapAfterRows: [Int] = [1, 3]
    var rowSeparatorSizeAsPercentOfScreenHeight: CGFloat = 2

    /// Per-cell text provider (1-based row/col). Return nil for no text.
    var textForCell: (CellIndex) -> CellTextSpec?

    /// Header group titles (6 merged groups)
    var headerTitles: [String] = [
        "TEAMS","SPADES","HEARTS","Hand\nScores","Total\nScores","Grand\nTotal"
    ]

    init(heightPercent: CGFloat = 60,
         columns: Int = 16,
         rows: Int = 5,
         rowCornerRadius: CGFloat = 7,
         gapAfterRows: [Int] = [1,3],
         rowSeparatorSizeAsPercentOfScreenHeight: CGFloat = 2,
         headerTitles: [String] = ["TEAMS","SPADES","HEARTS","Hand\nScores","Total\nScores","Grand\nTotal"],
         textForCell: @escaping (CellIndex) -> CellTextSpec? = { _ in nil }) {
        self.heightPercent = heightPercent
        self.columns = columns
        self.rows = rows
        self.rowCornerRadius = rowCornerRadius
        self.gapAfterRows = gapAfterRows
        self.rowSeparatorSizeAsPercentOfScreenHeight = rowSeparatorSizeAsPercentOfScreenHeight
        self.headerTitles = headerTitles
        self.textForCell = textForCell
    }

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
                    TextOverlay(layout: layout,
                                rowCornerRadius: rowCornerRadius,
                                headerTitles: headerTitles,
                                textForCell: textForCell)
                        .allowsHitTesting(false)
                }
            }
        }
    }
}

private struct TextOverlay: View {
    let layout: ScoreTableLayout
    let rowCornerRadius: CGFloat
    let headerTitles: [String]
    let textForCell: (CellIndex) -> CellTextSpec?

    var body: some View {
        ZStack {
            // Header row (merged groups)
            if layout.rows > 0, let header = layout.rowRects.first {
                headerLabels(in: header)
                    .frame(width: header.width, height: header.height)
                    .clipShape(RoundedRectangle(cornerRadius: rowCornerRadius))
                    .position(x: header.midX, y: header.midY)
            }

            // Body rows: draw text per individual cell, using the closure
            // -- in TextOverlay.body, replace the body-row loop --

            if layout.rows >= 2 {
                ForEach(Array(2...layout.rows), id: \.self) { row in
                    let r = layout.rowRects[row - 1]
                    ZStack {
                        // Only iterate columns if we have at least 1
                        if layout.cols >= 1 {
                            ForEach(1...layout.cols, id: \.self) { col in
                                let idx = CellIndex(row: row, col: col)
                                if let rect = cellRect(for: idx, in: layout),
                                   let spec = textForCell(idx) {
                                    let fs = (spec.fontScale ?? 0.42) * r.height
                                    Text(spec.text)
                                        .font(.system(size: fs, weight: spec.weight))
                                        .foregroundColor(spec.color)
                                        .lineLimit(spec.maxLines)
                                        .minimumScaleFactor(0.5)
                                        .multilineTextAlignment(.center)
                                        .frame(width: rect.width, height: rect.height)
                                        .position(x: rect.midX, y: rect.midY)
                                }
                            }
                        }
                    }
                    .frame(width: r.width, height: r.height)
                    .clipShape(RoundedRectangle(cornerRadius: rowCornerRadius))
                    .position(x: r.midX, y: r.midY)
                }
            }        }
    }

    // MARK: Header (merged) labels

    private func headerLabels(in header: CGRect) -> some View {
        let colW = layout.colWidth
        // Unify header font so all six groups fit
        let fs = unifiedHeaderFontSize(
            specs: [
                .init(text: headerTitles[safe: 0] ?? "TEAMS",         maxWidth: colW*3 - 10, maxHeight: header.height - 8, maxLines: 1),
                .init(text: headerTitles[safe: 1] ?? "SPADES",        maxWidth: colW*3 - 10, maxHeight: header.height - 8, maxLines: 1),
                .init(text: headerTitles[safe: 2] ?? "HEARTS",        maxWidth: colW*3 - 10, maxHeight: header.height - 8, maxLines: 1),
                .init(text: headerTitles[safe: 3] ?? "Hand\nScores",  maxWidth: colW*3 - 10, maxHeight: header.height - 8, maxLines: 2),
                .init(text: headerTitles[safe: 4] ?? "Total\nScores", maxWidth: colW*3 - 10, maxHeight: header.height - 8, maxLines: 2),
                .init(text: headerTitles[safe: 5] ?? "Grand\nTotal",  maxWidth: colW*1 - 10, maxHeight: header.height - 8, maxLines: 2),
            ],
            baseFont: .systemFont(ofSize: 64, weight: .semibold)
        )

        let centers: [CGFloat] = [1.5, 4.5, 7.5, 10.5, 13.5, 15.5].map { $0 * colW }
        let widths:  [CGFloat] = [3,   3,   3,    3,    3,    1   ].map { CGFloat($0) * colW }

        return ZStack {
            ForEach(0..<centers.count, id: \.self) { i in
                Text(headerTitles[safe: i] ?? "")
                    .font(.system(size: fs, weight: .semibold))
                    .foregroundColor(Theme.leftHeaderText)
                    .multilineTextAlignment(.center)
                    .lineLimit((headerTitles[safe: i] ?? "").contains("\n") ? 2 : 1)
                    .minimumScaleFactor(0.5)
                    .frame(width: widths[i], height: header.height)
                    .position(x: centers[i], y: header.height/2)
            }
        }
    }

    // MARK: Geometry

    private func cellRect(for index: CellIndex, in layout: ScoreTableLayout) -> CGRect? {
        guard index.row >= 1, index.row <= layout.rows,
              index.col >= 1, index.col <= layout.cols,
              layout.rowRects.indices.contains(index.row - 1) else { return nil }
        let rowRect = layout.rowRects[index.row - 1]
        let x0 = rowRect.minX + CGFloat(index.col - 1) * layout.colWidth
        return CGRect(x: x0, y: rowRect.minY, width: layout.colWidth, height: rowRect.height)
    }
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

        let lineH = max(f.lineHeight, 1)
        let lines = max(1, Int(ceil(rect.height / lineH)))
        let fits = rect.width <= maxWidth && rect.height <= maxHeight && lines <= maxLines

        if fits { lo = mid } else { hi = mid }
    }
    return floor(lo)
}

private extension Array {
    subscript(safe i: Int) -> Element? { indices.contains(i) ? self[i] : nil }
}

// MARK: - Preview demonstrating the closure

#Preview(traits: .landscapeLeft) {
    // Provide any text you want, cell-by-cell (1-based).
    let demo = ScoreTableWithText(
        heightPercent: 60,
        columns: 16,
        rows: 5,
        rowCornerRadius: 7,
        gapAfterRows: [1,3],
        rowSeparatorSizeAsPercentOfScreenHeight: 2,
        headerTitles: ["TEAMS","SPADES","HEARTS","Hand\nScores","Total\nScores","Grand\nTotal"]
    ) { idx in
        // Names in col 1 (you can also fill 2&3 if you want, but 1 is fine visually)
        if idx.col == 1 && idx.row >= 2 {
            let names = ["", "Lecia", "Arthur", "Elena", "Jesse"]
            let name = names.indices.contains(idx.row) ? names[idx.row] : ""
            return CellTextSpec(name, color: Theme.textOnLight, weight: .bold, fontScale: 0.42)
        }

        // Chip captions (rows 2–5, columns 4..8)
        if (2...5).contains(idx.row) {
            switch idx.col {
            case 4: return CellTextSpec("bid")
            case 5: return CellTextSpec("took")
            case 7: return CellTextSpec("hearts")
            case 8: return CellTextSpec("queen")
            case 9: return CellTextSpec("moon")
            default: break
            }
        }

        // Right-side placeholders for row 3 & 5
        if (idx.row == 3 || idx.row == 5), (10...16).contains(idx.col) {
            return CellTextSpec("—", color: Theme.rightNumberTxt, weight: .semibold, fontScale: 0.46)
        }

        return nil
    }

    return demo
}
