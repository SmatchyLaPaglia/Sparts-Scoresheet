//
//  Layout.swift
//  Sparts Scoresheet
//
//  Created by Jesse Macbook Clark on 9/3/25.
//


import SwiftUI

// MARK: - Inputs mirroring your Codea config

struct Layout {
    var overallWidthPercent:  CGFloat
    var overallHeightPercent: CGFloat
    var overallInnerPadding:  CGFloat

    var leftTableWidthPercent: CGFloat
    var gapTablesPercent:      CGFloat
    var tablesHeightPercent:   CGFloat

    var headerGap: CGFloat
    var teamGap:   CGFloat
}

struct LeftCols {
    var nameFrac:   CGFloat
    var narrowFrac: CGFloat
    var heartsFrac: CGFloat
}

struct RIGHT {
    var cols: CGFloat
}

// MARK: - Output metrics (mirrors `self.metrics` in Codea)

struct Metrics {
    // Heights
    var leftHeaderH:  CGFloat
    var leftRowH:     CGFloat
    var rightHeaderH: CGFloat
    var rightRowH:    CGFloat

    // Column widths
    var wName:   CGFloat
    var wNarrow: CGFloat
    var wHearts: CGFloat
    var wScore:  CGFloat

    // Anchors
    var innerX:  CGFloat
    var innerY:  CGFloat
    var leftW:   CGFloat
    var gapW:    CGFloat
    var rightW:  CGFloat
    var tablesH: CGFloat

    // Y positions
    var headY:         CGFloat
    var yAfterHeadGap: CGFloat
    var t1_row1:       CGFloat
    var t1_row2:       CGFloat
    var t2_row1:       CGFloat
    var t2_row2:       CGFloat

    // Font sizing
    var numberFontSize: CGFloat

    // Helpers (post-bump)
    var x_afterLabel: CGFloat
    var x_heartsCol:  CGFloat
    var x_qsCol:      CGFloat
    var x_moonCol:    CGFloat
}

// MARK: - Pure layout function (no drawing)

func computeMetrics(
    safeW: CGFloat,              // WIDTH  (use your notch-bounded span width)
    safeH: CGFloat,              // HEIGHT (likely the full view height)
    layout: Layout,
    leftCols: LeftCols,
    right: RIGHT
) -> Metrics {

    // === Direct port of your math ===

    // Overall box
    let overallW = safeW * layout.overallWidthPercent / 100
    let overallH = safeH * layout.overallHeightPercent / 100
    let overallX = (safeW - overallW) / 2
    let overallY = (safeH - overallH) / 2

    // Inner content rect
    let pad   = layout.overallInnerPadding
    let innerX = overallX + pad
    let innerY = overallY + pad
    let innerW = overallW - pad * 2
    let innerH = overallH - pad * 2

    // Left / gap / right widths
    let leftW0  = innerW * layout.leftTableWidthPercent / 100
    let gapW    = innerW * layout.gapTablesPercent      / 100
    let rightW0 = max(0, innerW - leftW0 - gapW)

    // Tables region height
    let tablesH = innerH * layout.tablesHeightPercent / 100

    // Heights
    let leftHeaderH  = max(28, min(64, tablesH / 5))
    let leftRowH     = leftHeaderH
    let rightHeaderH = leftHeaderH
    let rightRowH    = leftRowH

    // Column widths (pre-bump)
    var wName   = leftW0 * leftCols.nameFrac
    let wNarrow = leftW0 * leftCols.narrowFrac
    let wHearts = leftW0 * leftCols.heartsFrac
    let wScore0 = rightW0 / right.cols

    // Anchors (pre-bump)
    var leftW  = leftW0
    var rightW = rightW0
    var wScore = wScore0

    // Y positions (top-aligned header in Codea’s coordinate system)
    let headY         = innerY + tablesH - leftHeaderH
    let yAfterHeadGap = headY - layout.headerGap
    let t1_row1       = yAfterHeadGap - leftRowH
    let t1_row2       = t1_row1 - leftRowH
    let t2_row1       = t1_row2 - layout.teamGap - leftRowH
    let t2_row2       = t2_row1 - leftRowH

    let numberFontSize = leftRowH * 0.5

    // Bump: take 1 right column into the name column
    let bumpW = wScore0
    wName     = wName + bumpW
    leftW     = leftW + bumpW
    rightW    = rightW - bumpW
    wScore    = rightW / right.cols

    // Base X helpers (post-bump)
    let x_afterLabel = innerX + wName + wNarrow                 // after "bid/took"
    let x_heartsCol  = innerX + wName + wNarrow * 3
    let x_qsCol      = x_heartsCol + wHearts
    let x_moonCol    = x_heartsCol + wHearts * 2

    // Pack results
    return Metrics(
        leftHeaderH: leftHeaderH,
        leftRowH: leftRowH,
        rightHeaderH: rightHeaderH,
        rightRowH: rightRowH,
        wName: wName,
        wNarrow: wNarrow,
        wHearts: wHearts,
        wScore: wScore,
        innerX: innerX,
        innerY: innerY,
        leftW: leftW,
        gapW: gapW,
        rightW: rightW,
        tablesH: tablesH,
        headY: headY,
        yAfterHeadGap: yAfterHeadGap,
        t1_row1: t1_row1,
        t1_row2: t1_row2,
        t2_row1: t2_row1,
        t2_row2: t2_row2,
        numberFontSize: numberFontSize,
        x_afterLabel: x_afterLabel,
        x_heartsCol: x_heartsCol,
        x_qsCol: x_qsCol,
        x_moonCol: x_moonCol
    )
}