import SwiftUI

// MARK: - Small UI Helpers

private struct Cell: View {
    let width: CGFloat
    let height: CGFloat
    let alignment: Alignment
    let content: AnyView

    init(width: CGFloat, height: CGFloat = 40, alignment: Alignment = .center, @ViewBuilder content: () -> some View) {
        self.width = width
        self.height = height
        self.alignment = alignment
        self.content = AnyView(content())
    }

    var body: some View {
        ZStack(alignment: alignment) {
            Rectangle().fill(Color(.systemBackground))
            content.padding(.horizontal, 6)
        }
        .frame(width: width, height: height)
        .overlay(Rectangle().stroke(.black, lineWidth: 1))
    }
}

private struct CheckBox: View {
    @Binding var isOn: Bool
    var body: some View {
        Button { isOn.toggle() } label: {
            Image(systemName: isOn ? "checkmark.square.fill" : "square")
                .imageScale(.medium)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Checkbox")
        .accessibilityValue(isOn ? "Checked" : "Unchecked")
    }
}


// MARK: - Percent-Driven Layout

/// Everything derives from these percents.
private struct LayoutPercents {
    var overallWidthPercent:  CGFloat = 100   // of safe area
    var overallHeightPercent: CGFloat = 88    // of safe area
    var overallInnerPadding: CGFloat = 8      // points inside the big rounded box

    var leftTableWidthAsPercent:   CGFloat = 44
    var gapBetweenTablesAsPercent: CGFloat = 2
    var rightTableWidthAsPercent:  CGFloat { max(0, 100 - leftTableWidthAsPercent - gapBetweenTablesAsPercent) }

    var tablesHeightPercent: CGFloat = 80     // both tables use the same percent of box height
}

/// Left table metrics expressed as absolute points, derived from percents.
private struct LeftMetrics {
    // Column *fractions* of the left table’s width (sum = 1.0)
    // Name 120, 3×Narrow(80), 3×Hearts(80) -> total 600 baseline
    static let nameFrac:   CGFloat = 120/600
    static let narrowFrac: CGFloat =  80/600
    static let heartsFrac: CGFloat =  80/600

    let wName: CGFloat
    let wNarrow: CGFloat
    let wHearts: CGFloat
    let rowH: CGFloat
    let headerPointSize: CGFloat

    init(leftWidth: CGFloat, leftHeight: CGFloat, rowsBelowHeader: CGFloat = 4) {
        wName   = leftWidth * Self.nameFrac
        wNarrow = leftWidth * Self.narrowFrac
        wHearts = leftWidth * Self.heartsFrac

        // header + 4 rows (two players x 2 rows each)
        rowH = max(28, leftHeight / (1 + rowsBelowHeader))
        headerPointSize = (rowH / 2) * 0.84   // 2 lines in some headers
    }
}

/// Right table metrics in points, derived from percents.
private struct RightMetrics {
    // 8 equal score columns
    let wScore: CGFloat
    let rowHHeader: CGFloat
    let rowHData: CGFloat
    let totalsPointSize: CGFloat

    init(rightWidth: CGFloat, rightHeight: CGFloat, pairedWith leftRowH: CGFloat) {
        wScore = rightWidth / 8
        rowHHeader = leftRowH
        rowHData   = leftRowH * 2       // align to two left rows
        totalsPointSize = leftRowH * 0.80
    }
}

// MARK: - Main View

struct FusedTables: View {
    // --- Data (same as before) ---
    @State private var teams: [Team] = [
        Team(
            id: 1,
            players: [
                Player(id: 1, name: "Lecia",  bid: 4, took: 4, spades: 0),
                Player(id: 2, name: "Arthur", bid: 2, took: 2, spades: 5)
            ],
            data: TeamData(
                id: 1, name: "Team 1",
                hearts: 0, queensSpades: true, moonShot: false,
                spadesScore: 60, heartsScore: 72, handScore: -12,
                handBags: 0, allBags: 0,
                spadesTotal: 60, heartsTotal: 72, gameTotal: -12
            )
        ),
        Team(
            id: 2,
            players: [
                Player(id: 3, name: "Elena", bid: 4, took: 7, spades: 0),
                Player(id: 4, name: "Jesse", bid: 0, took: 0, spades: 8)
            ],
            data: TeamData(
                id: 2, name: "Team 2",
                hearts: 0, queensSpades: false, moonShot: false,
                spadesScore: 0, heartsScore: 0, handScore: 0,
                handBags: 0, allBags: 0,
                spadesTotal: 0, heartsTotal: 0, gameTotal: 0
            )
        )
    ]

    private let nums = Array(0...13)

    // --- Column design widths (logical design units) ---
    private let wName:   CGFloat = 120
    private let wNarrow: CGFloat = 80   // bid/took
    private let wHearts: CGFloat = 80   // hearts / queen / moon
    private let wScore:  CGFloat = 80   // each right-side numeric/total column

    private let rowH: CGFloat = 40
    private let rightRowH: CGFloat = 80   // one tall right row = two left rows

    // Left design total (TEAM + (bid,took) + (hearts,queen,moon))
    private var leftDesignW: CGFloat { wName + (2 * wNarrow) + (3 * wHearts) }  // 520
    // Right design total (8 score columns)
    private var rightDesignW: CGFloat { 8 * wScore }                            // 640

    // --- Percent controls (simple, explicit) ---
    @State private var leftTableWidthAsPercent:   CGFloat = 44   // of the inner working width
    @State private var gapBetweenTablesAsPercent: CGFloat = 0    // set >0 if you want a gutter
    // rightTableWidthAsPercent is derived:
    private func rightPercent(_ left: CGFloat, _ gap: CGFloat) -> CGFloat { max(0, 100 - left - gap) }

    // --- Overall bounding box (the big rounded container) ---
    @State private var overallWidthPercent:  CGFloat = 100
    @State private var overallHeightPercent: CGFloat = 88
    @State private var overallInnerPadding: CGFloat = 8

    // Auto-fit header labels
    private func header(text: String, width: CGFloat, height: CGFloat, lines: Int = 1) -> some View {
        Cell(width: width, height: height) {
            AutoFitText(text: text, lines: lines)
        }
    }

    var body: some View {
        GeometryReader { geo in
            // Safe-area canvas
            let safeW = max(geo.size.width, 1)
            let safeH = max(geo.size.height, 1)

            // Overall working area (the big rounded box)
            let overallW = safeW * (overallWidthPercent  / 100)
            let overallH = safeH * (overallHeightPercent / 100)

            // Inner region (inside the rounded box padding)
            let innerPad = overallInnerPadding
            let innerW   = max(overallW - innerPad * 2, 1)
            let innerH   = max(overallH - innerPad * 2, 1)

            // Split inner width into left, gap, right by percent
            let leftWPercent  = leftTableWidthAsPercent
            let gapWPercent   = gapBetweenTablesAsPercent
            let rightWPercent = rightPercent(leftWPercent, gapWPercent)

            let leftW   = innerW * (leftWPercent  / 100)
            let gapW    = innerW * (gapWPercent   / 100)
            let rightW  = innerW * (rightWPercent / 100)

            // Compute actual pixel widths per column group by scaling design widths
            let sxLeft  = leftW  / leftDesignW
            let sxRight = rightW / rightDesignW

            // Actual column widths (no scaleEffect; we size Cells directly)
            let wNameA    = wName   * sxLeft
            let wBidA     = wNarrow * sxLeft
            let wTookA    = wNarrow * sxLeft
            let wHeartsA  = wHearts * sxLeft   // numeric hearts
            let wQueenA   = wHearts * sxLeft   // checkbox
            let wMoonA    = wHearts * sxLeft   // checkbox

            let wScoreA   = wScore  * sxRight  // each right column

            // Row heights (make both sides equal per row)
            let headerH   = max(rowH * sxLeft, rowH * sxRight)
            let teamRowH  = max((rowH * 2) * sxLeft, rightRowH * sxRight)

            ZStack {
                Color(.systemBackground)

                // Big bounding box
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(.systemGray6))
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(.gray.opacity(0.5), lineWidth: 1)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Card Game Scoresheet")
                            .font(.title.bold())

                        // Unified table
                        VStack(spacing: 0) {
                            // ===== HEADER ROW =====
                            HStack(spacing: 0) {
                                // Left group headers
                                header(text: "TEAM MEMBER", width: wNameA, height: headerH, lines: 2)
                                header(text: "SPADES",       width: (wBidA + wTookA), height: headerH)
                                header(text: "HEARTS",       width: (wHeartsA + wQueenA + wMoonA), height: headerH)

                                // Gap (optional) – visually it will look like a faint seam
                                if gapW > 0 {
                                    Rectangle()
                                        .fill(Color.clear)
                                        .frame(width: gapW, height: headerH)
                                }

                                // Right group headers (8 cols)
                                header(text: "Spades\nScore", width: wScoreA, height: headerH, lines: 2)
                                header(text: "Hearts\nScore", width: wScoreA, height: headerH, lines: 2)
                                header(text: "Hand\nScore",   width: wScoreA, height: headerH, lines: 2)
                                header(text: "Hand\nBags",    width: wScoreA, height: headerH, lines: 2)
                                header(text: "All\nBags",     width: wScoreA, height: headerH, lines: 2)
                                header(text: "Spades\nTotal", width: wScoreA, height: headerH, lines: 2)
                                header(text: "Hearts\nTotal", width: wScoreA, height: headerH, lines: 2)
                                header(text: "Game\nTotal",   width: wScoreA, height: headerH, lines: 2)
                            }

                            // ===== TEAM ROWS (Team 1 & Team 2) =====
                            ForEach($teams) { $team in
                                HStack(spacing: 0) {
                                    // ----- LEFT: two player lines (bid/took/hearts/queen/moon) -----
                                    VStack(spacing: 0) {
                                        // Player 1 line
                                        HStack(spacing: 0) {
                                            Cell(width: wNameA, height: teamRowH/2, alignment: .leading) {
                                                TextField("Name", text: $team.players[0].name)
                                                    .textFieldStyle(.plain)
                                                    .font(.subheadline)
                                            }
                                            // bid/took label and pickers
                                            Cell(width: wBidA, height: teamRowH/2) { Text("bid/took").font(.caption).foregroundStyle(.secondary) }
                                            Cell(width: wTookA, height: teamRowH/2) {
                                                Picker("", selection: $team.players[0].took) {
                                                    ForEach(nums, id: \.self) { Text("\($0)").tag($0) }
                                                }.pickerStyle(.menu)
                                            }
                                            // hearts label, queen label, moon label cells (top line shows labels)
                                            Cell(width: wHeartsA, height: teamRowH/2) { Text("hearts").font(.caption).foregroundStyle(.secondary) }
                                            Cell(width: wQueenA, height: teamRowH/2) { Text("queen").font(.caption).foregroundStyle(.secondary) }
                                            Cell(width: wMoonA,  height: teamRowH/2) { Text("moon").font(.caption).foregroundStyle(.secondary) }
                                        }

                                        // Player 2 line (actual inputs, including hearts, queen, moon)
                                        HStack(spacing: 0) {
                                            Cell(width: wNameA, height: teamRowH/2, alignment: .leading) {
                                                TextField("Name", text: $team.players[1].name)
                                                    .textFieldStyle(.plain)
                                                    .font(.subheadline)
                                            }

                                            // bid & took for player 2
                                            Cell(width: wBidA, height: teamRowH/2) {
                                                Picker("", selection: $team.players[1].bid) {
                                                    ForEach(nums, id: \.self) { Text("\($0)").tag($0) }
                                                }.pickerStyle(.menu)
                                            }
                                            Cell(width: wTookA, height: teamRowH/2) {
                                                Picker("", selection: $team.players[1].took) {
                                                    ForEach(nums, id: \.self) { Text("\($0)").tag($0) }
                                                }.pickerStyle(.menu)
                                            }

                                            // hearts numeric (team-level)
                                            Cell(width: wHeartsA, height: teamRowH/2) {
                                                Picker("", selection: $team.data.hearts) {
                                                    ForEach(nums, id: \.self) { Text("\($0)").tag($0) }
                                                }.pickerStyle(.menu)
                                            }
                                            // queen checkbox
                                            Cell(width: wQueenA, height: teamRowH/2) {
                                                CheckBox(isOn: $team.data.queensSpades)
                                            }
                                            // moon checkbox (now guaranteed visible)
                                            Cell(width: wMoonA, height: teamRowH/2) {
                                                CheckBox(isOn: $team.data.moonShot)
                                            }
                                        }
                                    }

                                    // Optional visual gap
                                    if gapW > 0 {
                                        Rectangle()
                                            .fill(Color.clear)
                                            .frame(width: gapW, height: teamRowH)
                                    }

                                    // ----- RIGHT: one tall line of 8 cells for the team -----
                                    HStack(spacing: 0) {
                                        Cell(width: wScoreA, height: teamRowH) { numberField($team.data.spadesScore) }
                                        Cell(width: wScoreA, height: teamRowH) { numberField($team.data.heartsScore) }
                                        Cell(width: wScoreA, height: teamRowH) { numberField($team.data.handScore)  }
                                        Cell(width: wScoreA, height: teamRowH) { numberField($team.data.handBags)   }
                                        Cell(width: wScoreA, height: teamRowH) { numberField($team.data.allBags)    }
                                        Cell(width: wScoreA, height: teamRowH) { AutoFitText(text: "\(team.data.spadesTotal)", weight: .bold) }
                                        Cell(width: wScoreA, height: teamRowH) { AutoFitText(text: "\(team.data.heartsTotal)", weight: .bold) }
                                        Cell(width: wScoreA, height: teamRowH) { AutoFitText(text: "\(team.data.gameTotal)",   weight: .bold) }
                                    }
                                }
                            }
                        } // unified table
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.gray.opacity(0.6), lineWidth: 1))
                        .frame(width: innerW, height: min(innerH, headerH + 2*teamRowH), alignment: .topLeading) // 2 teams
                    }
                    .padding(innerPad)
                }
                .frame(width: overallW, height: overallH, alignment: .topLeading)
            }
            .frame(width: safeW, height: safeH)
        }
    }

    // Reuse your number field, scaled by row height
    private func numberField(_ binding: Binding<Int>) -> some View {
        TextField("", value: binding, format: .number)
            .textFieldStyle(.roundedBorder)
            .multilineTextAlignment(.center)
            .monospacedDigit()
            .keyboardType(.numberPad)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 6)
    }
}

// MARK: - Preview
#Preview { FusedTables() }

