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
    private var contentWidth: CGFloat    { leftTotalWidth + interTableGap + rightTotalWidth }

    // A conservative estimated content height (title + header + rows + gaps)
    // You can tweak these numbers if your rows change height later.
    private var estimatedContentHeight: CGFloat {
        let title: CGFloat = 44
        let leftTable: CGFloat = 40 /*header*/ + (rowH * 2) // two rows (labels + inputs)
        let rightTable: CGFloat = 40 /*header*/ + (56 * 2)  // two team rows at 56
        let tallestTables: CGFloat = max(leftTable, rightTable)
        let gaps: CGFloat = 24 /*title-to-tables*/ + 20 /*bottom padding*/
        return title + tallestTables + gaps
    }

    var body: some View {
        GeometryReader { geo in
            // Leave a little padding around the content so it doesn’t hug the edges
            let horizontalPadding: CGFloat = 24
            let verticalPadding: CGFloat = 24

            // Scale factors to fit width and height; clamp to <= 1 so we never upscale
            let sx = (geo.size.width  - (horizontalPadding * 2)) / max(contentWidth, 1)
            let sy = (geo.size.height - (verticalPadding * 2)) / max(estimatedContentHeight, 1)
            let s  = min(sx, sy, 1)

            ZStack {
                Color(.systemBackground)

                VStack(spacing: 24) {
                    Text("Card Game Scoresheet")
                        .font(.title.bold())
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // fixed design width while unscaled; keeps your HStacks aligned
                    HStack(alignment: .top, spacing: interTableGap) {
                        playerInfoTable
                        teamScoresTable
                    }
                    .frame(width: contentWidth, alignment: .topLeading)
                }
                .frame(width: contentWidth, height: estimatedContentHeight, alignment: .topLeading)
                .scaleEffect(s, anchor: .topLeading)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, verticalPadding)
            }
            .ignoresSafeArea() // show full-bleed if you like
        }
    }


    // MARK: - Left: Player Information Table

    private var playerInfoTable: some View {
        VStack(spacing: 0) {
            // Header: Team Member | Spades | Hearts
            HStack(spacing: 0) {
                Cell(width: wName, height: rowH) { Text("TEAM\nMEMBER").font(.caption.weight(.semibold)).multilineTextAlignment(.center) }
                Cell(width: wNarrow*2, height: rowH) { Text("SPADES").font(.caption.weight(.semibold)) }
                Cell(width: wNarrow*3, height: rowH) { Text("HEARTS").font(.caption.weight(.semibold)) }
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
                Cell(width: wTeam,  height: rowH) { Text("TEAM").font(.caption.weight(.semibold)) }
                Cell(width: wScore, height: rowH) { Text("Spades\nScore").multilineTextAlignment(.center).font(.caption.weight(.semibold)) }
                Cell(width: wScore, height: rowH) { Text("Hearts\nScore").multilineTextAlignment(.center).font(.caption.weight(.semibold)) }
                Cell(width: wScore, height: rowH) { Text("Hand\nScore").multilineTextAlignment(.center).font(.caption.weight(.semibold)) }
                Cell(width: wScore, height: rowH) { Text("Hand\nBags").multilineTextAlignment(.center).font(.caption.weight(.semibold)) }
                Cell(width: wScore, height: rowH) { Text("All\nBags").multilineTextAlignment(.center).font(.caption.weight(.semibold)) }
                Cell(width: wScore, height: rowH) { Text("Spades\nTotal").multilineTextAlignment(.center).font(.caption.weight(.semibold)) }
                Cell(width: wScore, height: rowH) { Text("Hearts\nTotal").multilineTextAlignment(.center).font(.caption.weight(.semibold)) }
                Cell(width: wScore, height: rowH) { Text("Game\nTotal").multilineTextAlignment(.center).font(.caption.weight(.semibold)) }
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
                    Cell(width: wScore, height: 56) { Text("\(team.data.spadesTotal)").font(.headline).monospacedDigit() }
                    Cell(width: wScore, height: 56) { Text("\(team.data.heartsTotal)").font(.headline).monospacedDigit() }
                    Cell(width: wScore, height: 56) { Text("\(team.data.gameTotal)").font(.headline).monospacedDigit() }
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
