//
//  ScoreTableLayout.swift
//  Sparts Scoresheet
//
//  Created by Jesse Macbook Clark on 9/4/25.
//


//  ScoreTableLayout.swift
//  Sparts Scoresheet

import SwiftUI

/// Lightweight geometry snapshot that other layers (text, hit areas, etc.)
/// can consume without touching the base table implementation.
struct ScoreTableLayout: Equatable {
    let tableRect: CGRect
    let rows: Int
    let cols: Int
    let rowRects: [CGRect]
    let colWidth: CGFloat

    /// Convenience: local X center for a column span in a given row.
    /// - row: 0-based row index
    /// - c0, c1: 0-based half-open range [c0, c1)
    func centerX(row: Int, c0: Int, c1: Int) -> CGFloat {
        let r = rowRects[row]
        let w = CGFloat(c1 - c0) * colWidth
        let x0 = r.minX + CGFloat(c0) * colWidth
        return x0 + w / 2
    }
}

struct ScoreTableLayoutKey: PreferenceKey {
    static var defaultValue: ScoreTableLayout? = nil
    static func reduce(value: inout ScoreTableLayout?, nextValue: () -> ScoreTableLayout?) {
        value = nextValue() ?? value
    }
}