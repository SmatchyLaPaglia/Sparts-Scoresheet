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
    var players: [Player]    // exactly two
    var data: TeamData
}

// MARK: - Reusable Cell

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

// MARK: - AutoFitText (with optional fixed size)
// If fixedPointSize is provided, that exact size is used (uniform across siblings).
// Otherwise it derives size from the view's height and number of lines.
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
                let perLineHeight = max((geo.size.height - padding * 2) / CGFloat(max(lines,1)), 1)
                return perLineHeight * baselineFactor
            }()
            Text(text)
                .font(.system(size: size, weight: weight, design: design))
                .multilineTextAlignment(alignment)
                .lineLimit(lines)
                .minimumScaleFactor(minScale)
                .frame(width: geo.size.width, height: geo.size.height, alignment: .center)
                .padding(.horizontal, padding)
        }
    }
}




// MARK: - Main View

struct RNPort_SpartsView: View {
    // Seed with the values from your React example
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

    // Column widths (tuned to your React grid values)
    private let wName: CGFloat   = 120
    private let wNarrow: CGFloat = 80
    private let wHearts: CGFloat = 80  // numeric cell within "Hearts" column
    private let rowH: CGFloat    = 40

    // Right table widths
    private let wTeam: CGFloat   = 100
    private let wScore: CGFloat  = 80
    
    // Total widths for left and right tables (based on the fixed column widths above)
    private var leftTotalWidth: CGFloat  { wName + (2 * wNarrow) + (3 * wHearts) }   // 120 + 160 + 240 = 520
    private var rightTotalWidth: CGFloat { wTeam + (8 * wScore) }                    // 100 + 8*80 = 740
    private let interTableGap: CGFloat   = 24

    // One shared size for ALL headers so they stay uniform.
    // Derived from header row height assuming worst-case 2 lines.
    private var headerPointSize: CGFloat {
        (rowH / 2) * 0.84 // 0.84 ≈ SF's line-height fudge factor
    }

    
    // --- Percent controls (you can tweak live) ---
    @State private var leftTableWidthAsPercent:  CGFloat = 41   // % of usable screen width
    @State private var rightTableWidthAsPercent: CGFloat = 58   // % of usable screen width
    @State private var leftTableHeightAsPercent: CGFloat = 80   // % of usable screen height
    @State private var rightTableHeightAsPercent: CGFloat = 80  // % of usable screen height

    // Overall canvas (the big rounded box) as % of the safe area
    @State private var overallWidthPercent:  CGFloat = 100   // % of safe-area width
    @State private var overallHeightPercent: CGFloat = 88   // % of safe-area height
    @State private var overallInnerPadding: CGFloat = 6    // padding inside the big box

    var body: some View {
        GeometryReader { geo in
            // SAFE-AREA size
            let safeW = max(geo.size.width, 1)
            let safeH = max(geo.size.height, 1)

            // MAIN OVERALL BOUNDING BOX size (percent of safe area)
            let overallW = safeW * (overallWidthPercent  / 100)
            let overallH = safeH * (overallHeightPercent / 100)

            // Inner working area for the two tables
            let innerPad = overallInnerPadding
            let usableW = max(overallW - innerPad * 2, 1)
            let usableH = max(overallH - innerPad * 2, 1)

            // Percent-based target sizes for each table
            let leftW  = usableW * (leftTableWidthAsPercent  / 100)
            let rightW = usableW * (rightTableWidthAsPercent / 100)
            let leftH  = usableH * (leftTableHeightAsPercent / 100)
            let rightH = usableH * (rightTableHeightAsPercent / 100)

            // Design (unscaled) sizes
            let leftDesignW:  CGFloat = leftTotalWidth
            let rightDesignW: CGFloat = rightTotalWidth
            let leftDesignH:  CGFloat = (40 + rowH*2)
            let rightDesignH: CGFloat = (40 + 56*2)

            // Scale to fit percent boxes
            let leftScale  = min(leftW / leftDesignW,   leftH / leftDesignH)
            let rightScale = min(rightW / rightDesignW, rightH / rightDesignH)

            // Gap between the two tables
            let gap: CGFloat = 6

            ZStack {
                Color(.systemBackground) // page bg

                // MAIN OVERALL BOUNDING BOX (shows the total space you're allocating)
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(.systemGray6)) // light background
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)

                    VStack(spacing: 12) {
                        Text("Card Game Scoresheet")
                            .font(.title.bold())
                            .frame(maxWidth: .infinity, alignment: .leading)

                        // Tables region
                        HStack(alignment: .top, spacing: gap) {
                            // LEFT TABLE
                            playerInfoTable
                                .frame(width: leftDesignW, height: leftDesignH, alignment: .topLeading)
                                .scaleEffect(leftScale, anchor: .topLeading)
                                .frame(width: leftW, height: leftH, alignment: .topLeading)
                                .clipped()

                            // RIGHT TABLE
                            teamScoresTable
                                .frame(width: rightDesignW, height: rightDesignH, alignment: .topLeading)
                                .scaleEffect(rightScale, anchor: .topLeading)
                                .frame(width: rightW, height: rightH, alignment: .topLeading)
                                .clipped()
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 0)
                        .padding(.bottom, 4)
                    }
                    .padding(innerPad)
                }
                // Place the big box centered in the safe area (or change to .topLeading if you prefer)
                .frame(width: overallW, height: overallH, alignment: .center)
            }
            .frame(width: safeW, height: safeH, alignment: .center)
        }
    }




    // MARK: - Left: Player Information Table

    private var playerInfoTable: some View {
        VStack(spacing: 0) {
            // Header: Team Member | Spades | Hearts
            HStack(spacing: 0) {
                Cell(width: wName, height: rowH) {
                    AutoFitText(text: "TEAM\nMEMBER", lines: 2, minScale: 1, fixedPointSize: headerPointSize)
                }
                Cell(width: wNarrow*2, height: rowH) {
                    AutoFitText(text: "SPADES", lines: 1, minScale: 1, fixedPointSize: headerPointSize)
                }
                Cell(width: wNarrow*3, height: rowH) {
                    AutoFitText(text: "HEARTS", lines: 1, minScale: 1, fixedPointSize: headerPointSize)
                }
            }

            ForEach($teams) { $team in
                // First row (labels line) matching your React layout
                HStack(spacing: 0) {
                    Cell(width: wName, height: rowH, alignment: .leading) {
                        TextField("Name", text: $team.players[0].name)
                            .textFieldStyle(.plain)
                            .font(.subheadline)
                    }
                    // bid/took label
                    Cell(width: wNarrow, height: rowH) { Text("bid/took").font(.caption).foregroundStyle(.secondary) }
                    // bid picker
                    Cell(width: wNarrow, height: rowH) {
                        Picker("", selection: $team.players[0].bid) {
                            ForEach(nums, id: \.self) { Text("\($0)").tag($0) }
                        }.pickerStyle(.menu)  // menu style like a dropdown  :contentReference[oaicite:3]{index=3}
                    }
                    // took picker
                    Cell(width: wNarrow, height: rowH) {
                        Picker("", selection: $team.players[0].took) {
                            ForEach(nums, id: \.self) { Text("\($0)").tag($0) }
                        }.pickerStyle(.menu)
                    }
                    // "hearts" label
                    Cell(width: wHearts, height: rowH) { Text("hearts").font(.caption).foregroundStyle(.secondary) }
                    // "queen" label
                    Cell(width: wHearts, height: rowH) { Text("queen").font(.caption).foregroundStyle(.secondary) }
                    // "moon" label
                    Cell(width: wHearts, height: rowH) { Text("moon").font(.caption).foregroundStyle(.secondary) }
                }

                // Second row (inputs line)
                HStack(spacing: 0) {
                    Cell(width: wName, height: rowH, alignment: .leading) {
                        TextField("Name", text: $team.players[1].name)
                            .textFieldStyle(.plain)
                            .font(.subheadline)
                    }
                    // bid/took label
                    Cell(width: wNarrow, height: rowH) { Text("bid/took").font(.caption).foregroundStyle(.secondary) }
                    // bid picker
                    Cell(width: wNarrow, height: rowH) {
                        Picker("", selection: $team.players[1].bid) {
                            ForEach(nums, id: \.self) { Text("\($0)").tag($0) }
                        }.pickerStyle(.menu)
                    }
                    // took picker
                    Cell(width: wNarrow, height: rowH) {
                        Picker("", selection: $team.players[1].took) {
                            ForEach(nums, id: \.self) { Text("\($0)").tag($0) }
                        }.pickerStyle(.menu)
                    }
                    // hearts numeric (team-level in your RN code)
                    Cell(width: wHearts, height: rowH) {
                        Picker("", selection: $team.data.hearts) {
                            ForEach(nums, id: \.self) { Text("\($0)").tag($0) }
                        }.pickerStyle(.menu)
                    }
                    // queen checkbox
                    Cell(width: wHearts, height: rowH) {
                        Toggle("", isOn: $team.data.queensSpades).labelsHidden() //  :contentReference[oaicite:4]{index=4}
                    }
                    // moon checkbox (you can make these mutually exclusive across teams later)
                    Cell(width: wHearts, height: rowH) {
                        Toggle("", isOn: $team.data.moonShot).labelsHidden()
                    }
                }
            }
        }
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.gray.opacity(0.6), lineWidth: 1))
    }

    // MARK: - Right: Team Scores Table

    private var teamScoresTable: some View {
        VStack(spacing: 0) {
            // Header row
            HStack(spacing: 0) {
                Cell(width: wTeam,  height: rowH) { AutoFitText(text: "TEAM",          lines: 1, minScale: 1, fixedPointSize: headerPointSize) }
                Cell(width: wScore, height: rowH) { AutoFitText(text: "Spades\nScore",  lines: 2, minScale: 1, fixedPointSize: headerPointSize) }
                Cell(width: wScore, height: rowH) { AutoFitText(text: "Hearts\nScore",  lines: 2, minScale: 1, fixedPointSize: headerPointSize) }
                Cell(width: wScore, height: rowH) { AutoFitText(text: "Hand\nScore",    lines: 2, minScale: 1, fixedPointSize: headerPointSize) }
                Cell(width: wScore, height: rowH) { AutoFitText(text: "Hand\nBags",     lines: 2, minScale: 1, fixedPointSize: headerPointSize) }
                Cell(width: wScore, height: rowH) { AutoFitText(text: "All\nBags",      lines: 2, minScale: 1, fixedPointSize: headerPointSize) }
                Cell(width: wScore, height: rowH) { AutoFitText(text: "Spades\nTotal",  lines: 2, minScale: 1, fixedPointSize: headerPointSize) }
                Cell(width: wScore, height: rowH) { AutoFitText(text: "Hearts\nTotal",  lines: 2, minScale: 1, fixedPointSize: headerPointSize) }
                Cell(width: wScore, height: rowH) { AutoFitText(text: "Game\nTotal",    lines: 2, minScale: 1, fixedPointSize: headerPointSize) }

            }

            ForEach($teams) { $team in
                HStack(spacing: 0) {
                    // Team name + players list
                    Cell(width: wTeam, height: 56, alignment: .leading) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(team.data.name).font(.subheadline.weight(.semibold))
                            Text("\(team.players[0].name) + \(team.players[1].name)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Editable numeric TextFields for scores/bags
                    Cell(width: wScore, height: 56) { numberField($team.data.spadesScore) }
                    Cell(width: wScore, height: 56) { numberField($team.data.heartsScore) }
                    Cell(width: wScore, height: 56) { numberField($team.data.handScore)  }
                    Cell(width: wScore, height: 56) { numberField($team.data.handBags)   }
                    Cell(width: wScore, height: 56) { numberField($team.data.allBags)    }

                    // Totals as large labels (read-only styling for now)
                    Cell(width: wScore, height: 56) { AutoFitText(text: "\(team.data.spadesTotal)", weight: .bold, lines: 1, minScale: 0.6) }
                    Cell(width: wScore, height: 56) { AutoFitText(text: "\(team.data.heartsTotal)", weight: .bold, lines: 1, minScale: 0.6) }
                    Cell(width: wScore, height: 56) { AutoFitText(text: "\(team.data.gameTotal)",   weight: .bold, lines: 1, minScale: 0.6) }
                }
            }
        }
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.gray.opacity(0.6), lineWidth: 1))
    }

    // MARK: - Small helpers

    private func numberField(_ binding: Binding<Int>) -> some View {
        // Bind Int directly using the value-based TextField initializer.  :contentReference[oaicite:5]{index=5}
        TextField("", value: binding, format: .number)
            .textFieldStyle(.roundedBorder)  // visual affordance  :contentReference[oaicite:6]{index=6}
            .frame(width: 44)
            .multilineTextAlignment(.center)
            .monospacedDigit()
            .keyboardType(.numberPad)
    }
}

// MARK: - Preview

#Preview {
    RNPort_SpartsView()
}
