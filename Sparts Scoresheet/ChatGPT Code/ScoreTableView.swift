import SwiftUI
import UIKit

// --- Stubs to mirror Codea structures ---
struct Teams {
    var players: [Player]
    var hearts: Int
    var queensSpades: Bool
    var moonShot: Bool
}

struct Player {
    var bid: Int
    var took: Int
}

// Extend IncrementingCell and CheckboxCell with style properties
struct IncrementingCell {
    var x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat
    var value: Int
    var set: Bool = true
    var min: Int = 0, max: Int = 0
    var wrap: Bool = false
    var fontSize: CGFloat = 0
    var hasSet: Bool = false
    
    // Style props
    var colBg: Color? = nil
    var colBgPressed: Color? = nil
    var colStroke: Color? = nil
    var colText: Color? = nil
    var colTextUnset: Color? = nil
}

struct CheckboxCell {
    var x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat
    var value: Bool
    
    // Style props
    var colBg: Color? = nil
    var colBgPressed: Color? = nil
    var colStroke: Color? = nil
    var colTick: Color? = nil
}

struct LongPressState {
    var pressed: Bool = false
    var start: Date? = nil
    var fired: Bool = false
}

// New file or next to ScoreTable — minimal stub
enum ScoreRules {
    /// Decide if the hearts portion is "ready" for this team.
    /// TODO: implement real logic (e.g., require an explicit hearts entry, etc.)
    static func heartsReady(_ team: Teams) -> Bool {
        // Stub: always false until you wire real readiness criteria
        return false
    }
    static func syncHeartsMoon(_ teams: inout [Teams]) {
            // Codea: ScoreRules.syncHeartsMoon(self.teams)
            // SwiftUI port: no-op stub for now.
    }
}

// MARK: - Confirm Modal Model (mirrors Codea table)
struct ConfirmModel {
    var visible: Bool = false
    // In Codea these were Sensors; here they’re just identifiers
    // you’ll attach gestures to later when you build the overlay.
    enum Target: String {
        case backdrop, btnYes, btnNo
    }
}

// MARK: - Layout params used by layout(...)
struct LayoutParams {
    var overallWidthPercent: CGFloat       // e.g. 92
    var overallHeightPercent: CGFloat      // e.g. 60
    var overallInnerPadding: CGFloat       // pts
    var leftTableWidthPercent: CGFloat     // e.g. 62
    var gapTablesPercent: CGFloat          // e.g. 2
    var tablesHeightPercent: CGFloat       // e.g. 80
    var headerGap: CGFloat                 // pts between header and first row
    var teamGap: CGFloat                   // pts between team1 bottom and team2 top

    static var `default`: LayoutParams {
        LayoutParams(
            overallWidthPercent: 92,
            overallHeightPercent: 60,
            overallInnerPadding: 8,
            leftTableWidthPercent: 62,
            gapTablesPercent: 2,
            tablesHeightPercent: 80,
            headerGap: 4,
            teamGap: 8
        )
    }
}

// MARK: - Metrics bag the function fills in
struct Metrics {
    // Heights
    var leftHeaderH: CGFloat = 0
    var leftRowH: CGFloat = 0
    var rightHeaderH: CGFloat = 0
    var rightRowH: CGFloat = 0

    // Column widths
    var wName: CGFloat = 0
    var wNarrow: CGFloat = 0
    var wHearts: CGFloat = 0
    var wScore: CGFloat = 0

    // Anchors / sizes
    var innerX: CGFloat = 0
    var innerY: CGFloat = 0
    var leftW: CGFloat = 0
    var gapW: CGFloat = 0
    var rightW: CGFloat = 0
    var tablesH: CGFloat = 0

    // Y positions
    var headY: CGFloat = 0
    var yAfterHeadGap: CGFloat = 0
    var t1_row1: CGFloat = 0
    var t1_row2: CGFloat = 0
    var t2_row1: CGFloat = 0
    var t2_row2: CGFloat = 0
}

// MARK: - Column fractions (left table)
enum LeftCols {
    // Fractions of left table width. Tune to your Codea values if needed.
    static let nameFrac:   CGFloat = 0.34
    static let narrowFrac: CGFloat = 0.08   // used twice (bid/took)
    static let heartsFrac: CGFloat = 0.16   // used three times (hearts / QS / moon)
    // 0.34 + 0.08*2 + 0.16*3 = 0.98 (leaves a hair for rounding)
}

// MARK: - Right table column count
enum RIGHT {
    static let cols: Int = 7
}

// --- View translated from Codea ScoreTable ---
struct ScoreTable: View {
    
    var teams: [Teams]
    var lp: [String]
    var lpThreshold: TimeInterval = 0.45
    var layout: LayoutParams = .default
    
    // One state object for each entry in lp
    @State private var lpStates: [String: LongPressState] = [:]
    @State private var confirm = ConfirmModel()
    @State private var longPressEnabled: Bool = true
    @State private var confirmVisible: Bool = false
    @State private var cells: [String: Any] = [:]
    @State private var metrics = Metrics()
    @State private var numberFontSize: CGFloat = 12
    @State private var lpFrames: [String: CGRect] = [:]
    
    // MARK: - Confirm handlers (Codea -> SwiftUI)
    private func confirmBackdropTapped() {
        if confirm.visible {
            confirm.visible = false
            _resetHeaderLP()
        }
    }

    private func confirmNoTapped() {
        if confirm.visible {
            confirm.visible = false
            _resetHeaderLP()
        }
    }

    private func confirmYesTapped() {
        guard confirm.visible else { return }
        _clearEntireHand()
        confirm.visible = false
        _resetHeaderLP()
    }
    
    // MARK: - New helpers (add inside ScoreTable)
    private func setLPFrame(_ key: String, _ rect: CGRect) {
        lpFrames[key] = rect
    }
    
    @Environment(\.displayScale) private var displayScale

    @inline(__always)
    private func px(_ v: CGFloat) -> CGFloat { (v * displayScale).rounded() / displayScale }
    
    @ViewBuilder
    func headerSectionCanvas(size: CGSize) -> some View {
        let m = selfLayout(size)               // your existing layout -> Metrics
        let handGroupW  = m.wScore * 3
        let totalGroupW = m.wScore * 3
        let grandGroupW = m.wScore * 1

        let headerFont = min(
            fitFontSize("TEAMS",         m.wName - 10,          m.leftHeaderH - 8, lines: 1),
            fitFontSize("SPADES",        m.wNarrow * 3 - 10,    m.leftHeaderH - 8, lines: 1),
            fitFontSize("HEARTS",        m.wHearts * 3 - 10,    m.leftHeaderH - 8, lines: 1),
            fitFontSize("Hand\nScores",  handGroupW - 10,       m.leftHeaderH - 8, lines: 2),
            fitFontSize("Total\nScores", totalGroupW - 10,      m.leftHeaderH - 8, lines: 2),
            fitFontSize("Grand\nTotal",  grandGroupW - 10,      m.leftHeaderH - 8, lines: 2)
        )

        Canvas { ctx, _ in
            func drawCell(x: CGFloat, w: CGFloat, label: String?) {
                let r = CGRect(
                    x: px(x),
                    y: px(m.headY),
                    width: px(w),
                    height: px(m.leftHeaderH)
                ).integral

                // fill + 1pt stroke (exactly like Codea)
                ctx.fill(Path(r), with: .color(Theme.leftHeaderBg))
                ctx.stroke(Path(r), with: .color(Theme.gridLine), lineWidth: 1)

                guard let label = label else { return }

                var att = AttributedString(label)
                att.font = .custom("HelveticaNeue-Bold", size: headerFont)
                att.foregroundColor = Theme.leftHeaderText

                // Center the text in the rect (Canvas handles this reliably)
                ctx.draw(Text(att), in: r)
            }

            var x = m.innerX
            // LEFT titles
            drawCell(x: x,                     w: m.wName,        label: "TEAMS");          x += m.wName
            drawCell(x: x,                     w: m.wNarrow * 3,  label: "SPADES");         x += m.wNarrow * 3
            drawCell(x: x,                     w: m.wHearts * 3,  label: "HEARTS");         x += m.wHearts * 3
            if m.gapW > 0 { drawCell(x: x,     w: m.gapW,         label: nil);              x += m.gapW }
            // RIGHT group titles
            drawCell(x: x,                     w: handGroupW,     label: "HAND\nSCORES");   x += handGroupW
            drawCell(x: x,                     w: totalGroupW,    label: "TOTAL\nSCORES");  x += totalGroupW
            drawCell(x: x,                     w: grandGroupW,    label: "GRAND\nTOTAL")
        }
        .allowsHitTesting(false)
        .dynamicTypeSize(.medium)   // lock text so it doesn’t auto-scale
        .ignoresSafeArea()          // we’re using your own safe-area math already
    }

    private func setCellFrame(key: String, x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat) {
        if var inc = cells[key] as? IncrementingCell {
            inc.x = x; inc.y = y; inc.w = w; inc.h = h
            cells[key] = inc
        } else if var cb = cells[key] as? CheckboxCell {
            cb.x = x; cb.y = y; cb.w = w; cb.h = h
            cells[key] = cb
        } else {
            // Unknown key/type; ignore
        }
    }

    init(teams: [Teams]) {
        self.teams = teams

        // Build cells
        var c: [String: Any] = [:]

        // Incrementing cells
        c["t1_p1_bid"]  = IncrementingCell(x: 0, y: 0, w: 0, h: 0, value: teams[0].players[0].bid)
        c["t1_p1_took"] = IncrementingCell(x: 0, y: 0, w: 0, h: 0, value: teams[0].players[0].took)
        c["t1_p2_bid"]  = IncrementingCell(x: 0, y: 0, w: 0, h: 0, value: teams[0].players[1].bid)
        c["t1_p2_took"] = IncrementingCell(x: 0, y: 0, w: 0, h: 0, value: teams[0].players[1].took)
        c["t1_hearts"]  = IncrementingCell(x: 0, y: 0, w: 0, h: 0, value: teams[0].hearts)

        c["t2_p1_bid"]  = IncrementingCell(x: 0, y: 0, w: 0, h: 0, value: teams[1].players[0].bid)
        c["t2_p1_took"] = IncrementingCell(x: 0, y: 0, w: 0, h: 0, value: teams[1].players[0].took)
        c["t2_p2_bid"]  = IncrementingCell(x: 0, y: 0, w: 0, h: 0, value: teams[1].players[1].bid)
        c["t2_p2_took"] = IncrementingCell(x: 0, y: 0, w: 0, h: 0, value: teams[1].players[1].took)
        c["t2_hearts"]  = IncrementingCell(x: 0, y: 0, w: 0, h: 0, value: teams[1].hearts)

        // Checkbox cells
        c["t1_qs"]   = CheckboxCell(x: 0, y: 0, w: 0, h: 0, value: teams[0].queensSpades)
        c["t1_moon"] = CheckboxCell(x: 0, y: 0, w: 0, h: 0, value: teams[0].moonShot)
        c["t2_qs"]   = CheckboxCell(x: 0, y: 0, w: 0, h: 0, value: teams[1].queensSpades)
        c["t2_moon"] = CheckboxCell(x: 0, y: 0, w: 0, h: 0, value: teams[1].moonShot)

        // Optional bounds for incrementing cells
        for (k, v) in c {
            if var cell = v as? IncrementingCell, cell.set {
                cell.min = 0
                cell.max = 13
                cell.wrap = true
                c[k] = cell
            }
        }

        self.cells = c

        // Long-press “sensors” list (names + header)
        self.lp = [
            "t1_p1_name",
            "t1_p2_name",
            "t2_p1_name",
            "t2_p2_name",
            "headerTeam"
        ]

        self.lpThreshold = 0.45

        // Init per-key long-press state (SwiftUI requires underscore form)
        _lpStates = State(initialValue:
            Dictionary(uniqueKeysWithValues: self.lp.map { ($0, LongPressState()) })
        )

        // Placeholder for later:
         for key in lp { assignLongPressCellActions(key) }
    }
    
    // no-op placeholder; we’ll attach gestures later in the rendering layer
    private func assignLongPressCellActions(_ key: String) { /* no-op */ }
    
    // MARK: - ScoreTable.layout (line-by-line from Codea)

    private func selfLayout() {
        let safeW = UIScreen.main.bounds.width
        let safeH = UIScreen.main.bounds.height
        let overallW = safeW * layout.overallWidthPercent / 100
        let overallH = safeH * layout.overallHeightPercent / 100
        let overallX = (safeW - overallW) / 2
        let overallY = (safeH - overallH) / 2
        let pad = layout.overallInnerPadding
        let innerX = overallX + pad
        let innerY = overallY + pad
        let innerW = overallW - pad*2
        let innerH = overallH - pad*2

        // left / gap / right widths & tables height
        let leftW  = innerW * layout.leftTableWidthPercent / 100
        let gapW   = innerW * layout.gapTablesPercent      / 100
        let rightW = max(0, innerW - leftW - gapW)
        let tablesH = innerH * layout.tablesHeightPercent / 100
        
        //   - write to `numberFontSize` only if it’s a @State (otherwise skip for now)
        var m = metrics

        // -- Heights
        m.leftHeaderH  = max(28, min(64, tablesH / 5))
        m.leftRowH     = m.leftHeaderH
        m.rightHeaderH = m.leftHeaderH
        // right table rows should match left table row height (no double height)
        m.rightRowH    = m.leftRowH

        // -- Column widths
        m.wName   = leftW * LeftCols.nameFrac
        m.wNarrow = leftW * LeftCols.narrowFrac
        m.wHearts = leftW * LeftCols.heartsFrac
        m.wScore  = rightW / CGFloat(RIGHT.cols)

        // -- Anchors
        m.innerX = innerX
        m.innerY = innerY
        m.leftW  = leftW
        m.gapW   = gapW
        m.rightW = rightW
        m.tablesH = tablesH

        // -- Y positions
        m.headY         = innerY + tablesH - m.leftHeaderH
        m.yAfterHeadGap = m.headY - layout.headerGap
        m.t1_row1       = m.yAfterHeadGap - m.leftRowH
        m.t1_row2       = m.t1_row1 - m.leftRowH
        m.t2_row1       = m.t1_row2 - layout.teamGap - m.leftRowH
        m.t2_row2       = m.t2_row1 - m.leftRowH

        self.numberFontSize = m.leftRowH * 0.5

        // -- Take one score-column from the right table to widen the name column
        let bumpW = m.wScore                // width of one right-table column
        m.wName   = m.wName + bumpW         // widen the TEAM/PLAYER name column
        m.leftW   = m.leftW + bumpW         // shift the boundary between left and right tables
        m.rightW  = m.rightW - bumpW        // shrink right table to keep total width consistent
        m.wScore  = m.rightW / CGFloat(RIGHT.cols)  // recompute per-column width on the right

        // -- Base X helpers
        let x_afterLabel = m.innerX + m.wName + m.wNarrow        // after "bid/took"
        let x_heartsCol  = m.innerX + m.wName + m.wNarrow * 3
        let x_qsCol      = x_heartsCol + m.wHearts
        let x_moonCol    = x_heartsCol + m.wHearts * 2

        // -- Name cell rectangles
        func nameRect(_ y: CGFloat) -> CGRect {
            CGRect(x: m.innerX, y: y, width: m.wName, height: m.leftRowH)
        }
        setLPFrame("t1_p1_name", nameRect(m.t1_row1))
        setLPFrame("t1_p2_name", nameRect(m.t1_row2))
        setLPFrame("t2_p1_name", nameRect(m.t2_row1))
        setLPFrame("t2_p2_name", nameRect(m.t2_row2))

        // -- TEAMS header cell rectangle
        setLPFrame(
            "headerTeam",
            CGRect(x: m.innerX, y: m.headY, width: m.wName, height: m.leftHeaderH)
        )

        // -- Team 1, player 1 (top row)
        setCellFrame(key: "t1_p1_bid",   x: x_afterLabel,             y: m.t1_row1, w: m.wNarrow, h: m.leftRowH)
        setCellFrame(key: "t1_p1_took",  x: x_afterLabel + m.wNarrow, y: m.t1_row1, w: m.wNarrow, h: m.leftRowH)

        // -- Team 1, player 2 (bottom row)
        setCellFrame(key: "t1_p2_bid",   x: x_afterLabel,             y: m.t1_row2, w: m.wNarrow, h: m.leftRowH)
        setCellFrame(key: "t1_p2_took",  x: x_afterLabel + m.wNarrow, y: m.t1_row2, w: m.wNarrow, h: m.leftRowH)
        setCellFrame(key: "t1_hearts",   x: x_heartsCol,              y: m.t1_row2, w: m.wHearts, h: m.leftRowH)
        setCellFrame(key: "t1_qs",       x: x_qsCol,                  y: m.t1_row2, w: m.wHearts, h: m.leftRowH)
        setCellFrame(key: "t1_moon",     x: x_moonCol,                y: m.t1_row2, w: m.wHearts, h: m.leftRowH)

        // -- Team 2, player 1 (top row)
        setCellFrame(key: "t2_p1_bid",   x: x_afterLabel,             y: m.t2_row1, w: m.wNarrow, h: m.leftRowH)
        setCellFrame(key: "t2_p1_took",  x: x_afterLabel + m.wNarrow, y: m.t2_row1, w: m.wNarrow, h: m.leftRowH)

        // -- Team 2, player 2 (bottom row)
        setCellFrame(key: "t2_p2_bid",   x: x_afterLabel,             y: m.t2_row2, w: m.wNarrow, h: m.leftRowH)
        setCellFrame(key: "t2_p2_took",  x: x_afterLabel + m.wNarrow, y: m.t2_row2, w: m.wNarrow, h: m.leftRowH)
        setCellFrame(key: "t2_hearts",   x: x_heartsCol,              y: m.t2_row2, w: m.wHearts, h: m.leftRowH)
        setCellFrame(key: "t2_qs",       x: x_qsCol,                  y: m.t2_row2, w: m.wHearts, h: m.leftRowH)
        setCellFrame(key: "t2_moon",     x: x_moonCol,                y: m.t2_row2, w: m.wHearts, h: m.leftRowH)

        self.numberFontSize = m.leftRowH * 0.5   // (match Codea placement)

        metrics = m
        
        applyNumberFontSize()
    }
//    mutating func layout(safeW: CGFloat, safeH: CGFloat) {
//        // local safeW, safeH = WIDTH, HEIGHT
//        // overallW/H and inner rect
//        let overallW = safeW * layout.overallWidthPercent / 100
//        let overallH = safeH * layout.overallHeightPercent / 100
//        let overallX = (safeW - overallW) / 2
//        let overallY = (safeH - overallH) / 2
//        let pad = layout.overallInnerPadding
//        let innerX = overallX + pad
//        let innerY = overallY + pad
//        let innerW = overallW - pad*2
//        let innerH = overallH - pad*2
//
//        // left / gap / right widths & tables height
//        let leftW  = innerW * layout.leftTableWidthPercent / 100
//        let gapW   = innerW * layout.gapTablesPercent      / 100
//        let rightW = max(0, innerW - leftW - gapW)
//        let tablesH = innerH * layout.tablesHeightPercent / 100
//
//        // self.metrics = self.metrics or {}
//        // local m = self.metrics
//        if metrics == nil { metrics = Metrics() }
//        var m = metrics!
//
//        // -- Heights
//        m.leftHeaderH  = max(28, min(64, tablesH / 5))
//        m.leftRowH     = m.leftHeaderH
//        m.rightHeaderH = m.leftHeaderH
//        // right table rows should match left table row height (no double height)
//        m.rightRowH    = m.leftRowH
//
//        // -- Column widths
//        m.wName   = leftW * LeftCols.nameFrac
//        m.wNarrow = leftW * LeftCols.narrowFrac
//        m.wHearts = leftW * LeftCols.heartsFrac
//        m.wScore  = rightW / CGFloat(RIGHT.cols)
//
//        // -- Anchors
//        m.innerX = innerX
//        m.innerY = innerY
//        m.leftW  = leftW
//        m.gapW   = gapW
//        m.rightW = rightW
//        m.tablesH = tablesH
//
//        // -- Y positions
//        m.headY         = innerY + tablesH - m.leftHeaderH
//        m.yAfterHeadGap = m.headY - layout.headerGap
//        m.t1_row1       = m.yAfterHeadGap - m.leftRowH
//        m.t1_row2       = m.t1_row1 - m.leftRowH
//        m.t2_row1       = m.t1_row2 - layout.teamGap - m.leftRowH
//        m.t2_row2       = m.t2_row1 - m.leftRowH
//
//        self.numberFontSize = m.leftRowH * 0.5
//
//        // -- Take one score-column from the right table to widen the name column
//        let bumpW = m.wScore                // width of one right-table column
//        m.wName   = m.wName + bumpW         // widen the TEAM/PLAYER name column
//        m.leftW   = m.leftW + bumpW         // shift the boundary between left and right tables
//        m.rightW  = m.rightW - bumpW        // shrink right table to keep total width consistent
//        m.wScore  = m.rightW / CGFloat(RIGHT.cols)  // recompute per-column width on the right
//
//        // -- Base X helpers
//        let x_afterLabel = m.innerX + m.wName + m.wNarrow        // after "bid/took"
//        let x_heartsCol  = m.innerX + m.wName + m.wNarrow * 3
//        let x_qsCol      = x_heartsCol + m.wHearts
//        let x_moonCol    = x_heartsCol + m.wHearts * 2
//
//        // -- Name cell rectangles
//        func nameRect(_ y: CGFloat) -> CGRect {
//            CGRect(x: m.innerX, y: y, width: m.wName, height: m.leftRowH)
//        }
//        setLPFrame("t1_p1_name", nameRect(m.t1_row1))
//        setLPFrame("t1_p2_name", nameRect(m.t1_row2))
//        setLPFrame("t2_p1_name", nameRect(m.t2_row1))
//        setLPFrame("t2_p2_name", nameRect(m.t2_row2))
//
//        // -- TEAMS header cell rectangle
//        setLPFrame(
//            "headerTeam",
//            CGRect(x: m.innerX, y: m.headY, width: m.wName, height: m.leftHeaderH)
//        )
//
//        // -- Team 1, player 1 (top row)
//        setCellFrame(key: "t1_p1_bid",   x: x_afterLabel,             y: m.t1_row1, w: m.wNarrow, h: m.leftRowH)
//        setCellFrame(key: "t1_p1_took",  x: x_afterLabel + m.wNarrow, y: m.t1_row1, w: m.wNarrow, h: m.leftRowH)
//
//        // -- Team 1, player 2 (bottom row)
//        setCellFrame(key: "t1_p2_bid",   x: x_afterLabel,             y: m.t1_row2, w: m.wNarrow, h: m.leftRowH)
//        setCellFrame(key: "t1_p2_took",  x: x_afterLabel + m.wNarrow, y: m.t1_row2, w: m.wNarrow, h: m.leftRowH)
//        setCellFrame(key: "t1_hearts",   x: x_heartsCol,              y: m.t1_row2, w: m.wHearts, h: m.leftRowH)
//        setCellFrame(key: "t1_qs",       x: x_qsCol,                  y: m.t1_row2, w: m.wHearts, h: m.leftRowH)
//        setCellFrame(key: "t1_moon",     x: x_moonCol,                y: m.t1_row2, w: m.wHearts, h: m.leftRowH)
//
//        // -- Team 2, player 1 (top row)
//        setCellFrame(key: "t2_p1_bid",   x: x_afterLabel,             y: m.t2_row1, w: m.wNarrow, h: m.leftRowH)
//        setCellFrame(key: "t2_p1_took",  x: x_afterLabel + m.wNarrow, y: m.t2_row1, w: m.wNarrow, h: m.leftRowH)
//
//        // -- Team 2, player 2 (bottom row)
//        setCellFrame(key: "t2_p2_bid",   x: x_afterLabel,             y: m.t2_row2, w: m.wNarrow, h: m.leftRowH)
//        setCellFrame(key: "t2_p2_took",  x: x_afterLabel + m.wNarrow, y: m.t2_row2, w: m.wNarrow, h: m.leftRowH)
//        setCellFrame(key: "t2_hearts",   x: x_heartsCol,              y: m.t2_row2, w: m.wHearts, h: m.leftRowH)
//        setCellFrame(key: "t2_qs",       x: x_qsCol,                  y: m.t2_row2, w: m.wHearts, h: m.leftRowH)
//        setCellFrame(key: "t2_moon",     x: x_moonCol,                y: m.t2_row2, w: m.wHearts, h: m.leftRowH)
//
//        self.numberFontSize = m.leftRowH * 0.5   // (match Codea placement)
//        self.metrics = m                         // write back
//        
//        applyNumberFontSize()
//    }

    // Direct line-by-line analog to setLongPressEnabled(on)
    func setLongPressEnabled(_ on: Bool = true) {
        longPressEnabled = on
        if !on {
            // Reset per-key LP state exactly like the Codea loop
            for key in lp {
                lpStates[key] = LongPressState()  // pressed=false, start=nil, fired=false
            }
        }
    }
    
    func _promptClearHand() {
        confirmVisible = true
    }
    
    // Helper to mutate a typed cell stored as Any
    private func _mutateCell<T>(_ key: String, as _: T.Type, _ body: (inout T) -> Void) {
        guard var val = cells[key] as? T else { return }
        body(&val)
        cells[key] = val
    }

    // Direct translation of _clearPlayer(...)
    mutating func _clearPlayer(teamIndex: Int, playerIndex: Int) {
        switch (teamIndex, playerIndex) {
        case (1, 1):
            _resetCellToUnset("t1_p1_bid")
            _resetCellToUnset("t1_p1_took")
            _resetCellToUnset("t1_hearts")
            _mutateCell("t1_qs",   as: CheckboxCell.self) { $0.value = false }
            _mutateCell("t1_moon", as: CheckboxCell.self) { $0.value = false }

        case (1, 2):
            _resetCellToUnset("t1_p2_bid")
            _resetCellToUnset("t1_p2_took")
            _resetCellToUnset("t1_hearts")
            _mutateCell("t1_qs",   as: CheckboxCell.self) { $0.value = false }
            _mutateCell("t1_moon", as: CheckboxCell.self) { $0.value = false }

        case (2, 1):
            _resetCellToUnset("t2_p1_bid")
            _resetCellToUnset("t2_p1_took")
            _resetCellToUnset("t2_hearts")
            _mutateCell("t2_qs",   as: CheckboxCell.self) { $0.value = false }
            _mutateCell("t2_moon", as: CheckboxCell.self) { $0.value = false }

        case (2, 2):
            _resetCellToUnset("t2_p2_bid")
            _resetCellToUnset("t2_p2_took")
            _resetCellToUnset("t2_hearts")
            _mutateCell("t2_qs",   as: CheckboxCell.self) { $0.value = false }
            _mutateCell("t2_moon", as: CheckboxCell.self) { $0.value = false }

        default:
            break
        }
    }

    // MARK: - Codea → SwiftUI translations

    // ScoreTable:_resetHeaderLP()
    private func _resetHeaderLP() {
        guard lpStates.keys.contains("headerTeam") else { return }
        lpStates["headerTeam"] = LongPressState() // pressed=false, start=nil, fired=false
    }

    // ScoreTable:_clearEntireHand()
    private func _clearEntireHand() {
        // bids & tooks
        _resetCellToUnset("t1_p1_bid")
        _resetCellToUnset("t1_p1_took")
        _resetCellToUnset("t1_p2_bid")
        _resetCellToUnset("t1_p2_took")
        _resetCellToUnset("t2_p1_bid")
        _resetCellToUnset("t2_p1_took")
        _resetCellToUnset("t2_p2_bid")
        _resetCellToUnset("t2_p2_took")

        // hearts
        _resetCellToUnset("t1_hearts")
        _resetCellToUnset("t2_hearts")

        // checkboxes
        if var qs = cells["t1_qs"] as? CheckboxCell { qs.value = false; cells["t1_qs"] = qs }
        if var mn = cells["t1_moon"] as? CheckboxCell { mn.value = false; cells["t1_moon"] = mn }
        if var qs = cells["t2_qs"] as? CheckboxCell { qs.value = false; cells["t2_qs"] = qs }
        if var mn = cells["t2_moon"] as? CheckboxCell { mn.value = false; cells["t2_moon"] = mn }
    }

    // Helper used above in Codea: _resetCellToUnset(cell)
    // Swift version works by key since we store cells in a dictionary.
    private func _resetCellToUnset(_ key: String) {
        if var inc = cells[key] as? IncrementingCell {
            // mimic “unset” — pick whatever semantics you prefer:
            inc.value = 0
            inc.set = false
            cells[key] = inc
        }
    }
    
    // Stub — in SwiftUI we don’t manually set frames or sensors this way.
    private func setCellFrame(_ key: String, x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat) {
        if var inc = cells[key] as? IncrementingCell {
            inc.x = x; inc.y = y; inc.w = w; inc.h = h
            cells[key] = inc
        } else if var cb = cells[key] as? CheckboxCell {
            cb.x = x; cb.y = y; cb.w = w; cb.h = h
            cells[key] = cb
        }
    }
    
    private func applyNumberFontSize() {
        for (key, value) in cells {
            if var inc = value as? IncrementingCell, inc.set {
                // Add a fontSize property to IncrementingCell if it doesn’t exist yet
                inc.fontSize = numberFontSize
                cells[key] = inc
            }
        }
    }
    
    // Paste inside ScoreTable (method or private extension)
    func _spadesReady(teamIndex: Int) -> Bool {
        let prefix = (teamIndex == 1) ? "t1" : "t2"
        // Pull the four left-side incrementing cells for that team
        guard
            let p1_bid  = cells["\(prefix)_p1_bid"]  as? IncrementingCell,
            let p1_took = cells["\(prefix)_p1_took"] as? IncrementingCell,
            let p2_bid  = cells["\(prefix)_p2_bid"]  as? IncrementingCell,
            let p2_took = cells["\(prefix)_p2_took"] as? IncrementingCell
        else {
            return false
        }

        func bidReady(_ bidCell: IncrementingCell) -> Bool {
            return (bidCell.value == 0) || bidCell.hasSet
        }

        func tookReady(_ tookCell: IncrementingCell) -> Bool {
            return tookCell.hasSet
        }

        return bidReady(p1_bid) && bidReady(p2_bid) && tookReady(p1_took) && tookReady(p2_took)
    }
    
    // Inside ScoreTable
    func _heartsReady(teamIndex: Int) -> Bool {
        // Codea uses 1-based indexing; keep that here.
        let i = teamIndex - 1
        guard teams.indices.contains(i) else { return false }
        return ScoreRules.heartsReady(teams[i])
    }
    
    // Inside ScoreTable or as a separate struct
    @ViewBuilder
    func _cell(x: CGFloat,
               y: CGFloat,
               w: CGFloat,
               h: CGFloat,
               bg: Color,
               txt: String? = nil,
               txtCol: Color = Theme.textOnLight,
               fsz: CGFloat? = nil) -> some View {
        ZStack {
            Rectangle()
                .fill(bg)
                .overlay(Rectangle().stroke(Theme.gridLine, lineWidth: 1))

            if let text = txt {
                Text(text)
                    .font(.system(size: fsz ?? (h * 0.45), weight: .bold))
                    .foregroundColor(txtCol)
                    .multilineTextAlignment(.center)
                    .frame(width: w, height: h)
            }
        }
        .frame(width: w, height: h)
        .position(x: x + w/2, y: y + h/2)
    }
    
    private func _skinInputs() {
        for (k, v) in cells {
            if var cell = v as? IncrementingCell, cell.set {
                cell.colBg        = Theme.cellBg
                cell.colBgPressed = Theme.cellBgPressed
                cell.colStroke    = Theme.gridLine
                cell.colText      = Theme.textAccentBlue
                cell.colTextUnset = Theme.textDisabled
                cells[k] = cell
            } else if var check = v as? CheckboxCell {
                check.colBg        = Theme.cellBg
                check.colBgPressed = Theme.cellBgPressed
                check.colStroke    = Theme.gridLine
                check.colTick      = Theme.checkboxTick
                cells[k] = check
            }
        }
    }
    
    // Aliases for the Codea "local m = self.metrics ..."
    // Returns nil until layout() has run.
    // Aliases for the Codea "local m = self.metrics ..."
    private func metricsAliases()
    -> (m: Metrics, innerX: CGFloat, wName: CGFloat, wNarrow: CGFloat,
        wHearts: CGFloat, wScore: CGFloat, gapW: CGFloat) {
        let m = metrics
        return (m, m.innerX, m.wName, m.wNarrow, m.wHearts, m.wScore, m.gapW)
    }

    func fitFontSize(_ text: String, _ maxW: CGFloat, _ maxH: CGFloat, lines: Int = 1) -> CGFloat {
        let lines = max(1, lines)
        var trySize: CGFloat = (maxH / CGFloat(lines)) * 0.9
        let minSz: CGFloat = 8
        let steps = 20

        // mimic Codea’s unwrapped text measurement (we’ll wrap by width constraint)
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byWordWrapping
        paragraph.alignment = .center

        let options: NSStringDrawingOptions = [.usesLineFragmentOrigin, .usesFontLeading]

        for i in 1...steps {
            let font = UIFont(name: "HelveticaNeue-Bold", size: trySize) ?? .boldSystemFont(ofSize: trySize)
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .paragraphStyle: paragraph
            ]

            // measure within maxW; height will expand to what’s needed
            let box = CGSize(width: maxW, height: .greatestFiniteMagnitude)
            let rect = (text as NSString).boundingRect(with: box, options: options, attributes: attrs, context: nil)

            let w = rect.width
            let h = rect.height

            if w <= maxW * 0.98 && h <= maxH * 0.98 {
                return trySize
            }

            // Codea’s decrement: max((try - minSz)/(steps - i + 1), 0.5)
            let dec = max((trySize - minSz) / CGFloat(steps - i + 1), 0.5)
            trySize -= dec
            if trySize <= minSz { break }
        }
        return minSz
    }
    
    // Overload: choose the smallest fitting font across multiple candidates
    func fitFontSize(_ candidates: [(String, CGFloat, CGFloat, Int)]) -> CGFloat {
        var best = CGFloat.greatestFiniteMagnitude
        for (text, maxW, maxH, lines) in candidates {
            let sz = fitFontSize(text, maxW, maxH, lines: lines)
            best = min(best, sz)
        }
        // If nothing ran (empty list), fall back to a sensible minimum
        return best == .greatestFiniteMagnitude ? 8 : best
    }
    
    @ViewBuilder
    func headerSection(m: Metrics) -> some View {
        // ---- compute outside the builder closure ----
        let handGroupW  = m.wScore * 3
        let totalGroupW = m.wScore * 3
        let grandGroupW = m.wScore * 1

        let headerFont = fitFontSize(
            [
                ("TEAMS",         m.wName - 10,           m.leftHeaderH - 8, 1),
                ("SPADES",        m.wNarrow * 3 - 10,     m.leftHeaderH - 8, 1),
                ("HEARTS",        m.wHearts * 3 - 10,     m.leftHeaderH - 8, 1),
                ("Hand\nScores",  handGroupW - 10,        m.leftHeaderH - 8, 2),
                ("Total\nScores", totalGroupW - 10,       m.leftHeaderH - 8, 2),
                ("Grand\nTotal",  grandGroupW - 10,       m.leftHeaderH - 8, 2)
            ]
        )

        let x0 = m.innerX
        let x1 = x0 + m.wName
        let x2 = x1 + m.wNarrow * 3
        let x3 = x2 + m.wHearts * 3
        let x4 = x3 + max(0 as CGFloat, m.gapW)
        let x5 = x4 + handGroupW
        let x6 = x5 + totalGroupW
        // ---------------------------------------------

        ZStack {
            _cell(x: x0, y: m.headY, w: m.wName,        h: m.leftHeaderH,
                  bg: Theme.leftHeaderBg, txt: "TEAMS", txtCol: Theme.leftHeaderText, fsz: headerFont)

            _cell(x: x1, y: m.headY, w: m.wNarrow * 3,  h: m.leftHeaderH,
                  bg: Theme.leftHeaderBg, txt: "SPADES", txtCol: Theme.leftHeaderText, fsz: headerFont)

            _cell(x: x2, y: m.headY, w: m.wHearts * 3,  h: m.leftHeaderH,
                  bg: Theme.leftHeaderBg, txt: "HEARTS", txtCol: Theme.leftHeaderText, fsz: headerFont)

            if m.gapW > 0 {
                _cell(x: x3, y: m.headY, w: m.gapW,     h: m.leftHeaderH,
                      bg: Theme.leftHeaderBg, txt: nil)
            }

            _cell(x: x4, y: m.headY, w: handGroupW,     h: m.leftHeaderH,
                  bg: Theme.leftHeaderBg, txt: "HAND\nSCORES",  txtCol: Theme.leftHeaderText, fsz: headerFont)

            _cell(x: x5, y: m.headY, w: totalGroupW,    h: m.leftHeaderH,
                  bg: Theme.leftHeaderBg, txt: "TOTAL\nSCORES", txtCol: Theme.leftHeaderText, fsz: headerFont)

            _cell(x: x6, y: m.headY, w: grandGroupW,    h: m.leftHeaderH,
                  bg: Theme.leftHeaderBg, txt: "GRAND\nTOTAL",  txtCol: Theme.leftHeaderText, fsz: headerFont)
        }
    }
    
    // Pure version that computes and RETURNS Metrics from a size
    func selfLayout(_ size: CGSize) -> Metrics {
        let safeW = size.width
        let safeH = size.height
        let l = layout  // your LayoutParams

        // overall + inner rect
        let overallW = safeW * l.overallWidthPercent / 100
        let overallH = safeH * l.overallHeightPercent / 100
        let overallX = (safeW - overallW) / 2
        let overallY = (safeH - overallH) / 2
        let pad = l.overallInnerPadding
        let innerX = overallX + pad
        let innerY = overallY + pad
        let innerW = overallW - pad*2
        let innerH = overallH - pad*2

        // left / gap / right widths & tables height
        let leftW  = innerW * l.leftTableWidthPercent / 100
        let gapW   = innerW * l.gapTablesPercent      / 100
        let rightW0 = max(0, innerW - leftW - gapW)
        let tablesH = innerH * l.tablesHeightPercent / 100

        var m = Metrics()

        // Heights
        m.leftHeaderH  = max(28, min(64, tablesH / 5))
        m.leftRowH     = m.leftHeaderH
        m.rightHeaderH = m.leftHeaderH
        m.rightRowH    = m.leftRowH

        // Column widths
        m.wName   = leftW * LeftCols.nameFrac
        m.wNarrow = leftW * LeftCols.narrowFrac
        m.wHearts = leftW * LeftCols.heartsFrac
        m.wScore  = rightW0 / CGFloat(RIGHT.cols)

        // Anchors
        m.innerX = innerX
        m.innerY = innerY
        m.leftW  = leftW
        m.gapW   = gapW
        m.rightW = rightW0
        m.tablesH = tablesH

        // Y positions
        m.headY         = innerY + tablesH - m.leftHeaderH
        m.yAfterHeadGap = m.headY - l.headerGap
        m.t1_row1       = m.yAfterHeadGap - m.leftRowH
        m.t1_row2       = m.t1_row1 - m.leftRowH
        m.t2_row1       = m.t1_row2 - l.teamGap - m.leftRowH
        m.t2_row2       = m.t2_row1 - m.leftRowH

        // Take one score-column from the right table to widen the name column
        let bumpW = m.wScore
        m.wName   += bumpW
        m.leftW   += bumpW
        m.rightW  -= bumpW
        m.wScore   = m.rightW / CGFloat(RIGHT.cols)

        return m
    }
    
    var body: some View {
        GeometryReader { geo in
            headerSectionCanvas(size: geo.size)
        }
        .background(Color.black.opacity(0.001)) // keeps hit-testing sane; no padding
    }
    
    
    
//    var body: some View {
//        EmptyView()
//            .onAppear {
//                selfLayout()
//                _skinInputs()
//            }
//        //    not translated bc data binding obsoletes syncing
//        //    self:syncBack()
//        //    ScoreRules.syncHeartsMoon(self.teams)
//        //    self:_syncHeartsCellsFromTeams()
//
//        //moved outside of this method: Codea convenience assignments of variables in the metrics table
//        
//        // --- widths for right-side groups
//        let a = metricsAliases()
//        let m = a.m
//
//        let handGroupW: CGFloat  = a.wScore * 3
//        let totalGroupW: CGFloat = a.wScore * 3
//        let grandGroupW: CGFloat = a.wScore * 1
//
//        // --- find a font that fits all header cells
//        let headerFont: CGFloat = [
//            fitFontSize("TEAMS",        m.wName - 10,          m.leftHeaderH - 8, lines: 1),
//            fitFontSize("SPADES",       a.wNarrow * 3 - 10,    m.leftHeaderH - 8, lines: 1),
//            fitFontSize("HEARTS",       m.wHearts * 3 - 10,    m.leftHeaderH - 8, lines: 1),
//            fitFontSize("Hand\nScores", handGroupW - 10,       m.leftHeaderH - 8, lines: 2),
//            fitFontSize("Total\nScores",totalGroupW - 10,      m.leftHeaderH - 8, lines: 2),
//            fitFontSize("Grand\nTotal", grandGroupW - 10,      m.leftHeaderH - 8, lines: 2)
//        ].min() ?? 12
//        
//        let x0 = m.innerX
//
//        Group {
//            // LEFT section titles
//            _cell(x: x0,
//                  y: m.headY,
//                  w: m.wName,
//                  h: m.leftHeaderH,
//                  bg: Theme.leftHeaderBg,
//                  txt: "TEAMS",
//                  txtCol: Theme.leftHeaderText,
//                  fsz: headerFont)
//
//            _cell(x: x0 + m.wName,
//                  y: m.headY,
//                  w: m.wNarrow * 3,
//                  h: m.leftHeaderH,
//                  bg: Theme.leftHeaderBg,
//                  txt: "SPADES",
//                  txtCol: Theme.leftHeaderText,
//                  fsz: headerFont)
//
//            _cell(x: x0 + m.wName + m.wNarrow * 3,
//                  y: m.headY,
//                  w: m.wHearts * 3,
//                  h: m.leftHeaderH,
//                  bg: Theme.leftHeaderBg,
//                  txt: "HEARTS",
//                  txtCol: Theme.leftHeaderText,
//                  fsz: headerFont)
//
//            if m.gapW > 0 {
//                _cell(x: x0 + m.wName + m.wNarrow * 3 + m.wHearts * 3,
//                      y: m.headY,
//                      w: m.gapW,
//                      h: m.leftHeaderH,
//                      bg: Theme.leftHeaderBg,
//                      txt: nil)
//            }
//
//            // RIGHT group titles
//            let xRightStart = x0 + m.wName + m.wNarrow * 3 + m.wHearts * 3 + max(0 as CGFloat, m.gapW)
//
//            _cell(x: xRightStart,
//                  y: m.headY,
//                  w: handGroupW,
//                  h: m.leftHeaderH,
//                  bg: Theme.leftHeaderBg,
//                  txt: "HAND\nSCORES",
//                  txtCol: Theme.leftHeaderText,
//                  fsz: headerFont)
//
//            _cell(x: xRightStart + handGroupW,
//                  y: m.headY,
//                  w: totalGroupW,
//                  h: m.leftHeaderH,
//                  bg: Theme.leftHeaderBg,
//                  txt: "TOTAL\nSCORES",
//                  txtCol: Theme.leftHeaderText,
//                  fsz: headerFont)
//
//            _cell(x: xRightStart + handGroupW + totalGroupW,
//                  y: m.headY,
//                  w: grandGroupW,
//                  h: m.leftHeaderH,
//                  bg: Theme.leftHeaderBg,
//                  txt: "GRAND\nTOTAL",
//                  txtCol: Theme.leftHeaderText,
//                  fsz: headerFont)
//        }
//        
//        
//        
//        
//        
//        
//        
//        
//        
//        
//        
//        
//        
//        
//        
//        
//        
//        
//        
//        
//        
//        
//        
//        
//    }
    
    private func _syncHeartsCellsFromTeams() {
        // Codea: self:_syncHeartsCellsFromTeams()
        // SwiftUI port: no-op stub for now.
    }
}

// --- Preview with tiny stub data ---
#Preview {
    let team1 = Teams(
        players: [Player(bid: 0, took: 0), Player(bid: 0, took: 0)],
        hearts: 0, queensSpades: false, moonShot: false
    )
    let team2 = Teams(
        players: [Player(bid: 0, took: 0), Player(bid: 0, took: 0)],
        hearts: 0, queensSpades: false, moonShot: false
    )
    return ScoreTable(teams: [team1, team2])
}




//-- ScoreTable.lua
//-- Renders the two-table sheet and uses IncrementingCell + CheckboxCell.
//
//ScoreTable = class()
//
//function ScoreTable:init(teams)
//    self.teams = teams
//    self.cells = {}
//    
//    -- Incrementing cells (10)
//    self.cells.t1_p1_bid   = IncrementingCell(0,0,0,0, teams[1].players[1].bid)
//    self.cells.t1_p1_took  = IncrementingCell(0,0,0,0, teams[1].players[1].took)
//    self.cells.t1_p2_bid   = IncrementingCell(0,0,0,0, teams[1].players[2].bid)
//    self.cells.t1_p2_took  = IncrementingCell(0,0,0,0, teams[1].players[2].took)
//    self.cells.t1_hearts   = IncrementingCell(0,0,0,0, teams[1].hearts)
//    
//    self.cells.t2_p1_bid   = IncrementingCell(0,0,0,0, teams[2].players[1].bid)
//    self.cells.t2_p1_took  = IncrementingCell(0,0,0,0, teams[2].players[1].took)
//    self.cells.t2_p2_bid   = IncrementingCell(0,0,0,0, teams[2].players[2].bid)
//    self.cells.t2_p2_took  = IncrementingCell(0,0,0,0, teams[2].players[2].took)
//    self.cells.t2_hearts   = IncrementingCell(0,0,0,0, teams[2].hearts)
//    
//    -- Checkbox cells (4)
//    self.cells.t1_qs       = CheckboxCell(0,0,0,0, teams[1].queensSpades)
//    self.cells.t1_moon     = CheckboxCell(0,0,0,0, teams[1].moonShot)
//    self.cells.t2_qs       = CheckboxCell(0,0,0,0, teams[2].queensSpades)
//    self.cells.t2_moon     = CheckboxCell(0,0,0,0, teams[2].moonShot)
//    
//    -- Optional bounds for incrementing cells
//    for k,c in pairs(self.cells) do
//        if c.set then
//            c.min, c.max, c.wrap = 0, 13, true
//        end
//    end
//    
//    -- Long-press sensors (names + header)
//    self.lp = {
//        t1_p1_name = Sensor{ parent = {x=0,y=0,w=0,h=0} },
//        t1_p2_name = Sensor{ parent = {x=0,y=0,w=0,h=0} },
//        t2_p1_name = Sensor{ parent = {x=0,y=0,w=0,h=0} },
//        t2_p2_name = Sensor{ parent = {x=0,y=0,w=0,h=0} },
//        headerTeam = Sensor{ parent = {x=0,y=0,w=0,h=0} },
//    }
//    self._lpTH = 0.45
//    for _, s in pairs(self.lp) do
//        s._pressed, s._start, s._fired = false, nil, false
//        s:onTouch(function(ev)
//            if ev.state then
//                s._pressed = true; s._start = ElapsedTime; s._fired = false
//            else
//                s._pressed = false; s._start = nil;        s._fired = false
//            end
//        end)
//    end

//    self._confirm = {
//        visible = false,
//        backdrop = Sensor{ parent = {x=0,y=0,w=0,h=0}, xywhMode = CORNER },
//        btnYes   = Sensor{ parent = {x=0,y=0,w=0,h=0}, xywhMode = CORNER },
//        btnNo    = Sensor{ parent = {x=0,y=0,w=0,h=0}, xywhMode = CORNER },
//    }
//    
//    -- capture everything while visible; tapping backdrop dismisses
//    self._confirm.backdrop:onTap(function()
//        if self._confirm.visible then
//            self._confirm.visible = false
//            self:_resetHeaderLP()
//        end
//    end)
//    
//    self._confirm.btnNo:onTap(function()
//        if self._confirm.visible then
//            self._confirm.visible = false
//            self:_resetHeaderLP()
//        end
//    end)
//    
//    self._confirm.btnYes:onTap(function()
//        if not self._confirm.visible then return end
//        self:_clearEntireHand()
//        self._confirm.visible = false
//        self:_resetHeaderLP()
//    end)
//end
//
//function ScoreTable:layout()
//    local safeW, safeH = WIDTH, HEIGHT
//    local overallW = safeW * layout.overallWidthPercent / 100
//    local overallH = safeH * layout.overallHeightPercent / 100
//    local overallX = (safeW - overallW)/2
//    local overallY = (safeH - overallH)/2
//    local pad = layout.overallInnerPadding
//    local innerX, innerY = overallX + pad, overallY + pad
//    local innerW, innerH = overallW - pad*2, overallH - pad*2
//    local leftW  = innerW * layout.leftTableWidthPercent / 100
//    local gapW   = innerW * layout.gapTablesPercent      / 100
//    local rightW = math.max(0, innerW - leftW - gapW)
//    local tablesH = innerH * layout.tablesHeightPercent / 100
//    
//    self.metrics = self.metrics or {}
//    local m = self.metrics
//    
//    -- Heights
//    m.leftHeaderH  = math.max(28, math.min(64, tablesH / 5))
//    m.leftRowH     = m.leftHeaderH
//    m.rightHeaderH = m.leftHeaderH
//    -- right table rows should match left table row height (no double height)
//    m.rightRowH    = m.leftRowH
//    
//    -- Column widths
//    m.wName   = leftW * LeftCols.nameFrac
//    m.wNarrow = leftW * LeftCols.narrowFrac
//    m.wHearts = leftW * LeftCols.heartsFrac
//    m.wScore  = rightW / RIGHT.cols
//    
//    -- Anchors
//    m.innerX, m.innerY, m.leftW, m.gapW, m.rightW, m.tablesH =
//    innerX, innerY, leftW, gapW, rightW, tablesH
//    
//    -- Y positions
//    m.headY   = innerY + tablesH - m.leftHeaderH
//    m.yAfterHeadGap = m.headY - layout.headerGap
//    m.t1_row1 = m.yAfterHeadGap - m.leftRowH
//    m.t1_row2 = m.t1_row1 - m.leftRowH
//    m.t2_row1 = m.t1_row2 - layout.teamGap - m.leftRowH
//    m.t2_row2 = m.t2_row1 - m.leftRowH
//    
//    self.numberFontSize = m.leftRowH * 0.5
//    
//    -- Take one score-column from the right table to widen the name column
//    local bumpW = m.wScore          -- width of one right-table column (after RIGHT.cols = 7)
//    m.wName     = m.wName + bumpW   -- widen the TEAM/PLAYER name column
//    m.leftW     = m.leftW + bumpW   -- shift the boundary between left and right tables
//    m.rightW    = m.rightW - bumpW  -- shrink right table to keep total width consistent
//    m.wScore    = m.rightW / RIGHT.cols  -- recompute per-column width on the right
//    
//    -- Base X helpers
//    local x_afterLabel = m.innerX + m.wName + m.wNarrow -- after "bid/took"
//    local x_heartsCol  = m.innerX + m.wName + m.wNarrow*3
//    local x_qsCol      = x_heartsCol + m.wHearts
//    local x_moonCol    = x_heartsCol + m.wHearts*2
//    
//    -- Name cell rectangles
//    local nameRect = function(y) return {x = m.innerX, y = y, w = m.wName, h = m.leftRowH} end
//    self.lp.t1_p1_name:setParent{ parent = nameRect(m.t1_row1), xywhMode = CORNER }
//    self.lp.t1_p2_name:setParent{ parent = nameRect(m.t1_row2), xywhMode = CORNER }
//    self.lp.t2_p1_name:setParent{ parent = nameRect(m.t2_row1), xywhMode = CORNER }
//    self.lp.t2_p2_name:setParent{ parent = nameRect(m.t2_row2), xywhMode = CORNER }
//    
//    -- TEAMS header cell rectangle
//    self.lp.headerTeam:setParent{
//        parent = { x = m.innerX, y = m.headY, w = m.wName, h = m.leftHeaderH },
//        xywhMode = CORNER
//    }
//    
//    -- Team 1, player 1 (top row)
//    self:setCellFrame(self.cells.t1_p1_bid,   x_afterLabel,             m.t1_row1, m.wNarrow, m.leftRowH)
//    self:setCellFrame(self.cells.t1_p1_took,  x_afterLabel + m.wNarrow, m.t1_row1, m.wNarrow, m.leftRowH)
//    
//    -- Team 1, player 2 (bottom row)
//    self:setCellFrame(self.cells.t1_p2_bid,   x_afterLabel,             m.t1_row2, m.wNarrow, m.leftRowH)
//    self:setCellFrame(self.cells.t1_p2_took,  x_afterLabel + m.wNarrow, m.t1_row2, m.wNarrow, m.leftRowH)
//    self:setCellFrame(self.cells.t1_hearts,   x_heartsCol,              m.t1_row2, m.wHearts, m.leftRowH)
//    self:setCellFrame(self.cells.t1_qs,       x_qsCol,                  m.t1_row2, m.wHearts, m.leftRowH)
//    self:setCellFrame(self.cells.t1_moon,     x_moonCol,                m.t1_row2, m.wHearts, m.leftRowH)
//    
//    -- Team 2, player 1 (top row)
//    self:setCellFrame(self.cells.t2_p1_bid,   x_afterLabel,             m.t2_row1, m.wNarrow, m.leftRowH)
//    self:setCellFrame(self.cells.t2_p1_took,  x_afterLabel + m.wNarrow, m.t2_row1, m.wNarrow, m.leftRowH)
//    
//    -- Team 2, player 2 (bottom row)
//    self:setCellFrame(self.cells.t2_p2_bid,   x_afterLabel,             m.t2_row2, m.wNarrow, m.leftRowH)
//    self:setCellFrame(self.cells.t2_p2_took,  x_afterLabel + m.wNarrow, m.t2_row2, m.wNarrow, m.leftRowH)
//    self:setCellFrame(self.cells.t2_hearts,   x_heartsCol,              m.t2_row2, m.wHearts, m.leftRowH)
//    self:setCellFrame(self.cells.t2_qs,       x_qsCol,                  m.t2_row2, m.wHearts, m.leftRowH)
//    self:setCellFrame(self.cells.t2_moon,     x_moonCol,                m.t2_row2, m.wHearts, m.leftRowH)
//    
//    self:_applyNumberFontSize()
//end
//
//-- Toggle LP (used by ScoreSheets while dragging)
//function ScoreTable:setLongPressEnabled(on)
//    self.longPressEnabled = (on ~= false)
//    if not self.longPressEnabled then
//        for _, s in pairs(self.lp) do
//            s._pressed, s._start, s._fired = false, nil, false
//        end
//    end
//end
//
//-- Simple inline confirm modal for clearing a hand
//function ScoreTable:_promptClearHand()
//    self._confirm.visible = true
//end
//
//-- hit-test helper for confirm buttons
//local function _pointInRect(px,py, r)
//    return px>=r.x and px<=r.x+r.w and py>=r.y and py<=r.y+r.h
//end
//
//function ScoreTable:_clearPlayer(teamIndex, playerIndex)
//    if teamIndex == 1 and playerIndex == 1 then
//        self:_resetCellToUnset(self.cells.t1_p1_bid)
//        self:_resetCellToUnset(self.cells.t1_p1_took)
//        self:_resetCellToUnset(self.cells.t1_hearts)
//        self.cells.t1_qs.value   = false
//        self.cells.t1_moon.value = false
//        
//    elseif teamIndex == 1 and playerIndex == 2 then
//        self:_resetCellToUnset(self.cells.t1_p2_bid)
//        self:_resetCellToUnset(self.cells.t1_p2_took)
//        self:_resetCellToUnset(self.cells.t1_hearts)
//        self.cells.t1_qs.value   = false
//        self.cells.t1_moon.value = false
//        
//    elseif teamIndex == 2 and playerIndex == 1 then
//        self:_resetCellToUnset(self.cells.t2_p1_bid)
//        self:_resetCellToUnset(self.cells.t2_p1_took)
//        self:_resetCellToUnset(self.cells.t2_hearts)
//        self.cells.t2_qs.value   = false
//        self.cells.t2_moon.value = false
//        
//    else -- team 2, player 2
//        self:_resetCellToUnset(self.cells.t2_p2_bid)
//        self:_resetCellToUnset(self.cells.t2_p2_took)
//        self:_resetCellToUnset(self.cells.t2_hearts)
//        self.cells.t2_qs.value   = false
//        self.cells.t2_moon.value = false
//    end
//end
//
//function ScoreTable:_resetHeaderLP()
//    local s = self.lp and self.lp.headerTeam
//    if s then
//        s._pressed = false
//        s._start   = nil
//        s._fired   = false
//    end
//end
//
//function ScoreTable:_clearEntireHand()
//    self:_resetCellToUnset(self.cells.t1_p1_bid)
//    self:_resetCellToUnset(self.cells.t1_p1_took)
//    self:_resetCellToUnset(self.cells.t1_p2_bid)
//    self:_resetCellToUnset(self.cells.t1_p2_took)
//    self:_resetCellToUnset(self.cells.t2_p1_bid)
//    self:_resetCellToUnset(self.cells.t2_p1_took)
//    self:_resetCellToUnset(self.cells.t2_p2_bid)
//    self:_resetCellToUnset(self.cells.t2_p2_took)
//    
//    self:_resetCellToUnset(self.cells.t1_hearts)
//    self:_resetCellToUnset(self.cells.t2_hearts)
//    
//    self.cells.t1_qs.value=false; self.cells.t1_moon.value=false
//    self.cells.t2_qs.value=false; self.cells.t2_moon.value=false
//end
//
//function ScoreTable:setCellFrame(cell, x, y, w, h)
//    cell.x, cell.y, cell.w, cell.h = x, y, w, h
//    if cell.sensor then
//        cell.sensor:setParent{ parent = cell, xywhMode = CORNER }
//    end
//end
//
//-- put near your other helpers in ScoreTable
//
//function ScoreTable:_resetCellToUnset(cell)
//    if cell.unset then
//        cell:unset()
//    else
//        cell.value  = 0
//        cell.hasSet = false
//    end
//end
//
//function ScoreTable:_applyNumberFontSize()
//    for _, c in pairs(self.cells) do
//        if c.set then        -- only incrementing cells have :set()
//            c.fontSize = self.numberFontSize
//        end
//    end
//end
//
//function ScoreTable:syncBack()
//    local t = self.teams
//    
//    local function fromCell(numCell)  -- returns number or nil
//        return (numCell and numCell.hasSet) and numCell.value or nil
//    end
//    local function fromCheck(checkCell) -- booleans default to false unless explicitly true
//        return (checkCell and checkCell.value == true) or false
//    end
//    
//    -- Team 1
//    t[1].players[1].bid  = fromCell(self.cells.t1_p1_bid)
//    t[1].players[1].took = fromCell(self.cells.t1_p1_took)
//    t[1].players[2].bid  = fromCell(self.cells.t1_p2_bid)
//    t[1].players[2].took = fromCell(self.cells.t1_p2_took)
//    t[1].hearts          = fromCell(self.cells.t1_hearts)
//    t[1].queensSpades    = fromCheck(self.cells.t1_qs)
//    t[1].moonShot        = fromCheck(self.cells.t1_moon)
//    
//    -- Team 2
//    t[2].players[1].bid  = fromCell(self.cells.t2_p1_bid)
//    t[2].players[1].took = fromCell(self.cells.t2_p1_took)
//    t[2].players[2].bid  = fromCell(self.cells.t2_p2_bid)
//    t[2].players[2].took = fromCell(self.cells.t2_p2_took)
//    t[2].hearts          = fromCell(self.cells.t2_hearts)
//    t[2].queensSpades    = fromCheck(self.cells.t2_qs)
//    t[2].moonShot        = fromCheck(self.cells.t2_moon)
//end
//
//-- readiness checkers for right-side gating
//function ScoreTable:_spadesReady(teamIndex)
//    local prefix = (teamIndex == 1) and "t1" or "t2"
//    local c = self.cells
//    
//    local p1_bid  = c[prefix.."_p1_bid"]
//    local p1_took = c[prefix.."_p1_took"]
//    local p2_bid  = c[prefix.."_p2_bid"]
//    local p2_took = c[prefix.."_p2_took"]
//    
//    local function bidReady(bidCell)
//        -- A bid of 0 (nil) counts as “entered” even if never touched.
//        -- Any positive bid must be explicitly entered (hasSet).
//        return (bidCell.value == 0) or bidCell.hasSet
//    end
//    
//    local function tookReady(tookCell)
//        -- Took must always be explicitly entered, even if 0.
//        return tookCell.hasSet == true
//    end
//    
//    return bidReady(p1_bid) and bidReady(p2_bid)
//    and tookReady(p1_took) and tookReady(p2_took)
//end
//
//function ScoreTable:_heartsReady(teamIndex)
//    return ScoreRules.heartsReady(self.teams[teamIndex])
//end
//
//-- draw a filled cell with border + centered label
//function ScoreTable:_cell(x,y,w,h, bg, txt, txtCol, fsz)
//    pushStyle()
//    fill(bg) ; stroke(Theme.gridLine) ; strokeWidth(1)
//    rectMode(CORNER) ; rect(x,y,w,h)
//    if txt then
//        fill(txtCol or Theme.textOnLight)
//        font("HelveticaNeue-Bold")
//        fontSize(fsz or (h*0.45))
//        textAlign(CENTER)
//        text(txt, x + w/2, y + h/2)
//    end
//    popStyle()
//end
//
//-- pre-skin all interactive cells (left side) with theme colors
//function ScoreTable:_skinInputs()
//    for _, c in pairs(self.cells) do
//        if c and c.set then
//            c.colBg        = Theme.cellBg
//            c.colBgPressed = Theme.cellBgPressed
//            c.colStroke    = Theme.gridLine
//            c.colText      = Theme.textAccentBlue
//            c.colTextUnset = Theme.textDisabled
//        elseif c and c.value ~= nil then -- checkbox
//            c.colBg        = Theme.cellBg
//            c.colBgPressed = Theme.cellBgPressed
//            c.colStroke    = Theme.gridLine
//            c.colTick      = Theme.checkboxTick
//        end
//    end
//end
//
//function ScoreTable:draw()
//    -- layout + skin + sync
//    self:layout()
//    self:_skinInputs()
//    self:syncBack()
//    ScoreRules.syncHeartsMoon(self.teams)
//    self:_syncHeartsCellsFromTeams()
//    
//    local m = self.metrics
//    local innerX, wName, wNarrow, wHearts, wScore, gapW =
//    m.innerX, m.wName, m.wNarrow, m.wHearts, m.wScore, m.gapW
//    
//    --------------------------------------------------------------------------
//    -- TOP HEADER (charcoal slab with orange section titles on BOTH sides)
//    --------------------------------------------------------------------------
//    -- widths for right-side groups
//    local handGroupW  = wScore * 3
//    local totalGroupW = wScore * 3
//    local grandGroupW = wScore * 1
//    
//    -- find a font that fits all header cells
//    local headerFont = math.min(
//    fitFontSize("TEAMS", m.wName-10,      m.leftHeaderH-8, 1),
//    fitFontSize("SPADES",      m.wNarrow*3-10,  m.leftHeaderH-8, 1),
//    fitFontSize("HEARTS",      m.wHearts*3-10,  m.leftHeaderH-8, 1),
//    fitFontSize("Hand\nScores",  handGroupW-10,  m.leftHeaderH-8, 2),
//    fitFontSize("Total\nScores", totalGroupW-10, m.leftHeaderH-8, 2),
//    fitFontSize("Grand\nTotal",  grandGroupW-10, m.leftHeaderH-8, 2)
//    )
//    
//    local x = innerX
//    -- LEFT section titles
//    self:_cell(x, m.headY, m.wName,     m.leftHeaderH, Theme.leftHeaderBg, "TEAMS", Theme.leftHeaderText, headerFont) ; x = x + m.wName
//    self:_cell(x, m.headY, m.wNarrow*3, m.leftHeaderH, Theme.leftHeaderBg, "SPADES",      Theme.leftHeaderText, headerFont) ; x = x + m.wNarrow*3
//    self:_cell(x, m.headY, m.wHearts*3, m.leftHeaderH, Theme.leftHeaderBg, "HEARTS",      Theme.leftHeaderText, headerFont) ; x = x + m.wHearts*3
//    if gapW > 0 then self:_cell(x, m.headY, gapW, m.leftHeaderH, Theme.leftHeaderBg, nil) ; x = x + gapW end
//    -- RIGHT group titles
//    self:_cell(x, m.headY, handGroupW,  m.leftHeaderH, Theme.leftHeaderBg, "HAND\nSCORES",  Theme.leftHeaderText, headerFont) ; x = x + handGroupW
//    self:_cell(x, m.headY, totalGroupW, m.leftHeaderH, Theme.leftHeaderBg, "TOTAL\nSCORES", Theme.leftHeaderText, headerFont) ; x = x + totalGroupW
//    self:_cell(x, m.headY, grandGroupW, m.leftHeaderH, Theme.leftHeaderBg, "GRAND\nTOTAL",  Theme.leftHeaderText, headerFont)
//    
//    --------------------------------------------------------------------------
//    -- LEFT TABLE (striped name rows + dark “chips” labels on BOTH rows)
//    --------------------------------------------------------------------------
//    local function nameStripe(i) return (i%2==1) and Theme.nameStripeLight or Theme.nameStripeDark end
//    local nameFS  = m.leftRowH * 0.42
//    local chipFS  = m.leftRowH * 0.32
//    
//    -- Names
//    self:_cell(innerX, m.t1_row1, m.wName, m.leftRowH, nameStripe(1), self.teams[1].players[1].name, Theme.textOnLight, nameFS)
//    self:_cell(innerX, m.t1_row2, m.wName, m.leftRowH, nameStripe(2), self.teams[1].players[2].name, Theme.textOnLight, nameFS)
//    self:_cell(innerX, m.t2_row1, m.wName, m.leftRowH, nameStripe(1), self.teams[2].players[1].name, Theme.textOnLight, nameFS)
//    self:_cell(innerX, m.t2_row2, m.wName, m.leftRowH, nameStripe(2), self.teams[2].players[2].name, Theme.textOnLight, nameFS)
//    
//    -- Chips helper (now on BOTH rows)
//    local function chipsRow(y)
//        -- bid/took chip
//        self:_cell(innerX + m.wName, y, m.wNarrow, m.leftRowH, Theme.leftHeaderBg, "bid/took", Theme.textSecondary, chipFS)
//        -- hearts chips
//        local xh = innerX + m.wName + m.wNarrow*3
//        self:_cell(xh,               y, m.wHearts, m.leftRowH, Theme.leftHeaderBg, "hearts", Theme.textSecondary, chipFS)
//        self:_cell(xh + m.wHearts,   y, m.wHearts, m.leftRowH, Theme.leftHeaderBg, "queen",  Theme.textSecondary, chipFS)
//        self:_cell(xh + m.wHearts*2, y, m.wHearts, m.leftHeaderH, Theme.leftHeaderBg, "moon",   Theme.textSecondary, chipFS)
//    end
//    chipsRow(m.t1_row1)
//    chipsRow(m.t1_row2)
//    chipsRow(m.t2_row1)
//    chipsRow(m.t2_row2)
//    
//    -- Interactive cells (already themed in _skinInputs)
//    -- T1
//    self.cells.t1_p1_bid:draw()   ; self.cells.t1_p1_took:draw()
//    self.cells.t1_p2_bid:draw()   ; self.cells.t1_p2_took:draw()
//    self.cells.t1_hearts:draw()   ; self.cells.t1_qs:draw() ; self.cells.t1_moon:draw()
//    -- T2
//    self.cells.t2_p1_bid:draw()   ; self.cells.t2_p1_took:draw()
//    self.cells.t2_p2_bid:draw()   ; self.cells.t2_p2_took:draw()
//    self.cells.t2_hearts:draw()   ; self.cells.t2_qs:draw() ; self.cells.t2_moon:draw()
//    
//    --------------------------------------------------------------------------
//    -- RIGHT TABLE (mini-headers per team row + colored value blocks)
//    --------------------------------------------------------------------------
//    local rX = innerX + m.leftW + m.gapW
//    local rh1Y, rv1Y = m.t1_row1, m.t1_row2
//    local rh2Y, rv2Y = m.t2_row1, m.t2_row2
//    
//    local labelsRight = {
//        "SPADES","HEARTS","BAGS",      -- hand scores
//        "SPADES","HEARTS","BAGS",      -- TOTALS  (Spades Total, Hearts Total, All Bags)
//        "GAME\nTOTAL"
//    }
//    local miniHeaderFont = m.rightRowH * 0.28
//    local colBg = {
//        Theme.rightSpadesScoreBg,
//        Theme.rightHeartsScoreBg,
//        Theme.rightHandScoreBg,
//        Theme.rightAllBagsBg,
//        Theme.rightSpadesTotalBg,
//        Theme.rightHeartsTotalBg,
//        Theme.rightGameTotalBg
//    }
//    
//    local function drawMiniHeaderRow(y)
//        local xx = rX
//        for i=1, #labelsRight do
//            self:_cell(xx, y, m.wScore, m.rightRowH, Theme.rightMiniHeaderBg, labelsRight[i], Theme.rightMiniHeaderTxt, miniHeaderFont)
//            xx = xx + m.wScore
//        end
//    end
//    
//    -- ScoreTable.lua  (inside rightValsForTeam)
//    
//    local function rightValsForTeam(ti)
//        local team   = self.teams[ti]
//        local hHand  = ScoreRules.heartsHand(team)
//        local sReady = self:_spadesReady(ti)
//        local hReady = ScoreRules.heartsReady(team)
//        
//        local spadesScore, handBags = nil, nil
//        if sReady then
//            local sHand = ScoreRules.spadesHand(team)
//            spadesScore = sHand.handScore
//            handBags    = sHand.handBags
//        end
//        
//        local function fmt(x) return (x == nil) and "--" or tostring(x) end
//        return {
//            fmt(spadesScore),                      -- hand Spades
//            fmt(hHand.handScore),                  -- hand Hearts
//            fmt(handBags),                         -- hand Bags
//            sReady and fmt(team.spadesTotal) or "--", -- TOTAL Spades (ready with spades)
//            hReady and fmt(team.heartsTotal) or "--", -- TOTAL Hearts (ready with hearts)
//            sReady and fmt(team.allBags)     or "--", -- TOTAL Bags   (ready with spades)
//            (sReady or hReady) and fmt(team.gameTotal) or "--", -- GRAND TOTAL (partial ok)
//        }
//    end
//    
//    local numberFS = self.numberFontSize
//    local function drawValuesRow(y, teamIndex)
//        local vals = rightValsForTeam(teamIndex)
//        local xx = rX
//        for i=1, #vals do
//            self:_cell(xx, y, m.wScore, m.rightRowH, colBg[i], vals[i], Theme.rightNumberTxt, numberFS)
//            xx = xx + m.wScore
//        end
//    end
//    
//    drawMiniHeaderRow(rh1Y) ; drawValuesRow(rv1Y, 1)
//    drawMiniHeaderRow(rh2Y) ; drawValuesRow(rv2Y, 2)
//    
//    -- === Long-press (header only, gated & with confirm) ===
//    if self.longPressEnabled ~= false and not self._confirm.visible then
//        local s = self.lp.headerTeam
//        if s._pressed and not s._fired and s._start
//        and (ElapsedTime - s._start) >= self._lpTH then
//            s._fired = true
//            self:_promptClearHand()
//            -- Do NOT call _resetHeaderLP() here.
//            -- Let the finger end event and/or dialog dismissal do the reset.
//        end
//    end
//    
//    -- === Confirm overlay ===
//    if self._confirm and self._confirm.visible then
//        local m = self.metrics
//        local W = m.leftW + m.gapW + m.rightW
//        local H = m.tablesH
//        local modalW, modalH = math.min(W*0.7, 520), math.min(m.leftRowH*3.2, 220)
//        local modalX = m.innerX + (W - modalW)/2
//        local modalY = m.innerY + (H - modalH)/2
//        
//        -- 1) (Re)position sensors to current geometry
//        self._confirm.backdrop:setParent{
//            parent = { x = m.innerX, y = m.innerY, w = W, h = H }, xywhMode = CORNER
//        }
//        -- make sure the backdrop actually intercepts touches
//        self._confirm.backdrop.doNotInterceptTouches = false
//        
//        local pad = 16
//        local bw, bh, gap = (modalW - pad*2 - 12)/2, m.leftRowH*0.9, 12
//        local by  = modalY + pad
//        local bx1 = modalX + pad
//        local bx2 = bx1 + bw + gap
//        self._confirm.btnNo:setParent {
//            parent = { x = bx1, y = by, w = bw, h = bh }, xywhMode = CORNER
//        }
//        self._confirm.btnYes:setParent{
//            parent = { x = bx2, y = by, w = bw, h = bh }, xywhMode = CORNER
//        }
//        
//        -- 2) Draw overlay
//        pushStyle()
//        noStroke()
//        fill(0, 0, 0, 150)
//        rectMode(CORNER)
//        -- draw the dimmer in absolute screen space
//        pushMatrix()
//        resetMatrix()
//        rect(0, 0, WIDTH, HEIGHT)
//        popMatrix()
//        
//        fill(255)
//        stroke(60) ; strokeWidth(2)
//        rect(modalX, modalY, modalW, modalH, 12)
//        
//        local msg = "Clear all data entered in this hand?"
//        fill(0)
//        fontSize(m.leftRowH*0.34)
//        textAlign(CENTER)
//        text(msg, modalX + modalW/2, modalY + modalH - pad - m.leftRowH*0.6)
//        
//        -- NO button
//        fill(240) ; stroke(120)
//        rect(bx1, by, bw, bh, 10)
//        fill(30) ; fontSize(m.leftRowH*0.36)
//        text("No", bx1 + bw/2, by + bh/2)
//        
//        -- YES button
//        fill(40,160,255) ; stroke(20,120,220)
//        rect(bx2, by, bw, bh, 10)
//        fill(255)
//        text("Yes", bx2 + bw/2, by + bh/2)
//        popStyle()
//    end
//end
//
//function ScoreTable:touched(t)
//    
//    -- If confirm is up, it captures all touches
//    if self._confirm and self._confirm.visible then
//        -- Let buttons try first (so their taps are seen), then backdrop
//        if self._confirm.btnYes:touched(t)   then return true end
//        if self._confirm.btnNo:touched(t)    then return true end
//        if self._confirm.backdrop:touched(t) then return true end
//        return true
//    end
//    
//    -- snapshot BEFORE values to see what changed
//    local prev_t1_moon = self.cells.t1_moon.value
//    local prev_t2_moon = self.cells.t2_moon.value
//    
//    -- pass the event to all cells/sensors
//    for _, c in pairs(self.cells) do
//        if c and c.touched then c:touched(t) end
//    end
//    for _, s in pairs(self.lp) do
//        if s and s.touched then s:touched(t) end
//    end
//    
//    -- detect which moon checkbox actually toggled this touch
//    local t1_changed = (self.cells.t1_moon.value ~= prev_t1_moon)
//    local t2_changed = (self.cells.t2_moon.value ~= prev_t2_moon)
//    
//    if t1_changed and self.cells.t1_moon.value == true then
//        -- user turned ON team 1 moon -> force team 2 OFF
//        self.cells.t2_moon.value = false
//    elseif t2_changed and self.cells.t2_moon.value == true then
//        -- user turned ON team 2 moon -> force team 1 OFF
//        self.cells.t1_moon.value = false
//    end
//end
//
//-- After rules normalize the teams, push just the HEARTS-related fields
//-- back into the left-table cells so the UI reflects the forced state.
//function ScoreTable:_syncHeartsCellsFromTeams()
//    local t1, t2 = self.teams[1], self.teams[2]
//    
//    -- Only push back when rule normalization forced a concrete value (non-nil)
//    if self.cells.t1_hearts.set and (t1.hearts ~= nil) then self.cells.t1_hearts:set(t1.hearts) end
//    if self.cells.t2_hearts.set and (t2.hearts ~= nil) then self.cells.t2_hearts:set(t2.hearts) end
//    
//    self.cells.t1_qs.value   = (t1.queensSpades == true)
//    self.cells.t1_moon.value = (t1.moonShot     == true)
//    self.cells.t2_qs.value   = (t2.queensSpades == true)
//    self.cells.t2_moon.value = (t2.moonShot     == true)
//end
//
//
