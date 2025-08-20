import SwiftUI

// MARK: - Models

struct Player: Identifiable, Hashable {
    let id: Int
    var name: String
    var bid: Int
    var took: Int
    var spades: Int
}

struct TeamData: Identifiable, Hashable {
    let id: Int
    var name: String
    var hearts: Int
    var queensSpades: Bool
    var moonShot: Bool
    var spadesScore: Int
    var heartsScore: Int
    var handScore: Int
    var handBags: Int
    var allBags: Int
    var spadesTotal: Int
    var heartsTotal: Int
    var gameTotal: Int
}

struct Team: Identifiable, Hashable {
    let id: Int
    var players: [Player]
    var data: TeamData
}

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

struct AutoFitText: View {
    let text: String
    var weight: Font.Weight = .semibold
    var design: Font.Design = .default
    var alignment: TextAlignment = .center
    var lines: Int = 1
    var padding: CGFloat = 0
    var minScale: CGFloat = 0.7
    var baselineFactor: CGFloat = 0.84
    var fixedPointSize: CGFloat? = nil

    var body: some View {
        GeometryReader { geo in
            let size: CGFloat = {
                if let fixed = fixedPointSize { return fixed }
                let perLine = max((geo.size.height - padding * 2) / CGFloat(max(lines,1)), 1)
                return perLine * baselineFactor
            }()
            Text(text)
                .font(.system(size: size, weight: weight, design: design))
                .multilineTextAlignment(alignment)
                .lineLimit(lines)
                .minimumScaleFactor(minScale)
                .frame(width: geo.size.width, height: geo.size.height)
                .padding(.horizontal, padding)
        }
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

struct FromRN_SeparateTables: View {
    @State private var layout = LayoutPercents()

    @State private var teams: [Team] = [
        Team(
            id: 1,
            players: [
                Player(id: 1, name: "Lecia",  bid: 4, took: 4, spades: 0),
                Player(id: 2, name: "Arthur", bid: 2, took: 2, spades: 5)
            ],
            data: TeamData(id: 1, name: "Team 1",
                           hearts: 0, queensSpades: true, moonShot: false,
                           spadesScore: 60, heartsScore: 72, handScore: -12,
                           handBags: 0, allBags: 0, spadesTotal: 60, heartsTotal: 72, gameTotal: -12)
        ),
        Team(
            id: 2,
            players: [
                Player(id: 3, name: "Elena", bid: 4, took: 7, spades: 0),
                Player(id: 4, name: "Jesse", bid: 0, took: 0, spades: 8)
            ],
            data: TeamData(id: 2, name: "Team 2",
                           hearts: 0, queensSpades: false, moonShot: false,
                           spadesScore: 0, heartsScore: 0, handScore: 0,
                           handBags: 0, allBags: 0, spadesTotal: 0, heartsTotal: 0, gameTotal: 0)
        )
    ]

    private let nums = Array(0...13)

    var body: some View {
        GeometryReader { geo in
            // 1) Safe area
            let safeW = max(geo.size.width,  1)
            let safeH = max(geo.size.height, 1)

            // 2) Overall working box (percent of safe area)
            let overallW = safeW * (layout.overallWidthPercent  / 100)
            let overallH = safeH * (layout.overallHeightPercent / 100)

            // 3) Inner content area
            let innerPad = layout.overallInnerPadding
            let innerW = max(overallW - innerPad * 2, 1)
            let innerH = max(overallH - innerPad * 2, 1)

            // 4) Table widths & heights (all percent-driven)
            let leftW   = innerW * (layout.leftTableWidthAsPercent   / 100)
            let gapW    = innerW * (layout.gapBetweenTablesAsPercent / 100)
            let rightW  = innerW * (layout.rightTableWidthAsPercent  / 100)

            let tablesH = innerH * (layout.tablesHeightPercent / 100)

            // 5) Per-table metrics
            let L = LeftMetrics(leftWidth: leftW, leftHeight: tablesH)
            let R = RightMetrics(rightWidth: rightW, rightHeight: tablesH, pairedWith: L.rowH)

            ZStack {
                Color(.systemBackground)

                // Outer box to visualize the total working area
                ZStack {
                    RoundedRectangle(cornerRadius: 14).fill(Color(.systemGray6))
                    RoundedRectangle(cornerRadius: 14).stroke(Color.gray.opacity(0.5), lineWidth: 1)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Card Game Scoresheet")
                            .font(.title.bold())

                        HStack(alignment: .top, spacing: gapW) {
                            playerInfoTable(L: L)
                                .frame(width: leftW,  height: tablesH, alignment: .topLeading)

                            teamScoresTable(R: R)
                                .frame(width: rightW, height: tablesH, alignment: .topLeading)
                        }
                    }
                    .padding(innerPad)
                }
                .frame(width: overallW, height: overallH)
            }
            .frame(width: safeW, height: safeH)
        }
    }

    // MARK: - Left Table

    private func playerInfoTable(L: LeftMetrics) -> some View {
        VStack(spacing: 0) {
            // Header: TEAM MEMBER | SPADES(3) | HEARTS(3)
            HStack(spacing: 0) {
                Cell(width: L.wName, height: L.rowH) {
                    AutoFitText(text: "TEAM\nMEMBER", lines: 2, minScale: 1, fixedPointSize: L.headerPointSize)
                }
                Cell(width: L.wNarrow * 3, height: L.rowH) {
                    AutoFitText(text: "SPADES", lines: 1, minScale: 1, fixedPointSize: L.headerPointSize)
                }
                Cell(width: L.wHearts * 3, height: L.rowH) {
                    AutoFitText(text: "HEARTS", lines: 1, minScale: 1, fixedPointSize: L.headerPointSize)
                }
            }

            // >>> Minimal change: gap between header and data rows <<<
            Color.clear.frame(height: 6)

            ForEach($teams) { $team in
                // Labels row
                HStack(spacing: 0) {
                    Cell(width: L.wName, height: L.rowH, alignment: .leading) {
                        TextField("Name", text: $team.players[0].name)
                            .textFieldStyle(.plain).font(.subheadline)
                    }
                    Cell(width: L.wNarrow, height: L.rowH) { Text("bid/took").font(.caption).foregroundStyle(.secondary) }
                    Cell(width: L.wNarrow, height: L.rowH) {
                        Picker("", selection: $team.players[0].bid) {
                            ForEach(nums, id: \.self) { Text("\($0)").tag($0) }
                        }.pickerStyle(.menu)
                    }
                    Cell(width: L.wNarrow, height: L.rowH) {
                        Picker("", selection: $team.players[0].took) {
                            ForEach(nums, id: \.self) { Text("\($0)").tag($0) }
                        }.pickerStyle(.menu)
                    }
                    Cell(width: L.wHearts, height: L.rowH) { Text("hearts").font(.caption).foregroundStyle(.secondary) }
                    Cell(width: L.wHearts, height: L.rowH) { Text("queen").font(.caption).foregroundStyle(.secondary) }
                    Cell(width: L.wHearts, height: L.rowH) { Text("moon").font(.caption).foregroundStyle(.secondary) }
                }

                // Inputs row
                HStack(spacing: 0) {
                    Cell(width: L.wName, height: L.rowH, alignment: .leading) {
                        TextField("Name", text: $team.players[1].name)
                            .textFieldStyle(.plain).font(.subheadline)
                    }
                    Cell(width: L.wNarrow, height: L.rowH) { Text("bid/took").font(.caption).foregroundStyle(.secondary) }
                    Cell(width: L.wNarrow, height: L.rowH) {
                        Picker("", selection: $team.players[1].bid) {
                            ForEach(nums, id: \.self) { Text("\($0)").tag($0) }
                        }.pickerStyle(.menu)
                    }
                    Cell(width: L.wNarrow, height: L.rowH) {
                        Picker("", selection: $team.players[1].took) {
                            ForEach(nums, id: \.self) { Text("\($0)").tag($0) }
                        }.pickerStyle(.menu)
                    }
                    Cell(width: L.wHearts, height: L.rowH) {
                        Picker("", selection: $team.data.hearts) {
                            ForEach(nums, id: \.self) { Text("\($0)").tag($0) }
                        }.pickerStyle(.menu)
                    }
                    Cell(width: L.wHearts, height: L.rowH) { CheckBox(isOn: $team.data.queensSpades) }
                    Cell(width: L.wHearts, height: L.rowH) { CheckBox(isOn: $team.data.moonShot) }
                }
            }
        }
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.gray.opacity(0.6), lineWidth: 1))
    }

    // MARK: - Right Table

    private func teamScoresTable(R: RightMetrics) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Cell(width: R.wScore, height: R.rowHHeader) { AutoFitText(text: "Spades\nScore", lines: 2, minScale: 1) }
                Cell(width: R.wScore, height: R.rowHHeader) { AutoFitText(text: "Hearts\nScore", lines: 2, minScale: 1) }
                Cell(width: R.wScore, height: R.rowHHeader) { AutoFitText(text: "Hand\nScore",   lines: 2, minScale: 1) }
                Cell(width: R.wScore, height: R.rowHHeader) { AutoFitText(text: "Hand\nBags",    lines: 2, minScale: 1) }
                Cell(width: R.wScore, height: R.rowHHeader) { AutoFitText(text: "All\nBags",     lines: 2, minScale: 1) }
                Cell(width: R.wScore, height: R.rowHHeader) { AutoFitText(text: "Spades\nTotal", lines: 2, minScale: 1) }
                Cell(width: R.wScore, height: R.rowHHeader) { AutoFitText(text: "Hearts\nTotal", lines: 2, minScale: 1) }
                Cell(width: R.wScore, height: R.rowHHeader) { AutoFitText(text: "Game\nTotal",   lines: 2, minScale: 1) }
            }

            // >>> Minimal change: gap between header and data rows <<<
            Color.clear.frame(height: 6)

            ForEach($teams) { $team in
                HStack(spacing: 0) {
                    Cell(width: R.wScore, height: R.rowHData) { numberField($team.data.spadesScore, cellHeight: R.rowHData) }
                    Cell(width: R.wScore, height: R.rowHData) { numberField($team.data.heartsScore, cellHeight: R.rowHData) }
                    Cell(width: R.wScore, height: R.rowHData) { numberField($team.data.handScore,  cellHeight: R.rowHData) }
                    Cell(width: R.wScore, height: R.rowHData) { numberField($team.data.handBags,   cellHeight: R.rowHData) }
                    Cell(width: R.wScore, height: R.rowHData) { numberField($team.data.allBags,    cellHeight: R.rowHData) }

                    Cell(width: R.wScore, height: R.rowHData) { AutoFitText(text: "\(team.data.spadesTotal)", weight: .bold, lines: 1, minScale: 1, fixedPointSize: R.totalsPointSize) }
                    Cell(width: R.wScore, height: R.rowHData) { AutoFitText(text: "\(team.data.heartsTotal)", weight: .bold, lines: 1, minScale: 1, fixedPointSize: R.totalsPointSize) }
                    Cell(width: R.wScore, height: R.rowHData) { AutoFitText(text: "\(team.data.gameTotal)",   weight: .bold, lines: 1, minScale: 1, fixedPointSize: R.totalsPointSize) }
                }
            }
        }
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.gray.opacity(0.6), lineWidth: 1))
    }

    // MARK: - Small helper

    private func numberField(_ binding: Binding<Int>, cellHeight: CGFloat) -> some View {
        TextField("", value: binding, format: .number)
            .textFieldStyle(.roundedBorder)
            .font(.system(size: cellHeight * 0.35))   // scales with cell height
            .frame(width: 48)
            .multilineTextAlignment(.center)
            .monospacedDigit()
            .keyboardType(.numberPad)
    }
}

// MARK: - Preview

#Preview { FromRN_SeparateTables() }
