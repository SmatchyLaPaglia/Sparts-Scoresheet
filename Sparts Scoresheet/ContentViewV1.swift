
//  ContentView.swift
//  Sparts Scoresheet
//
//  Created by Jesse Wonder Clark on 8/18/25.
//

import SwiftUI

@main
struct Sparts_ScoresheetApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// MARK: - Rules

enum Sparts {
    static let spadesPointsPerBid = 10
    static let heartValue = 4
    static let queenPenalty = 13 * heartValue // 52
    static let bagPenaltyThreshold = 10
    static let bagPenalty = -100
    static let nilSuccess = 100
    static let nilFail = -100
    static let heartsFullHand = 13 * heartValue + queenPenalty // 104
}

// MARK: - Models

struct PlayerInput: Identifiable, Hashable {
    let id = UUID()
    var name: String
    // Spades
    var spadesBid: Int = 0       // 0…13 (nil == 0)
    var spadesTook: Int = 0      // 0…13
    // Hearts lane (negative)
    var heartsTaken: Int = 0     // 0…13
    var tookQueenDiamond: Bool = false
}

struct Hand: Identifiable, Hashable {
    let id = UUID()
    // Players are fixed seats: [0,1] = Team A, [2,3] = Team B
    var players: [PlayerInput]
    // Team-level flags
    var teamAShotMoon: Bool = false
    var teamBShotMoon: Bool = false
    // Computed after scoring
    var result: HandResult = .empty
}

struct HandResult: Hashable {
    var spadesA: Int = 0
    var spadesB: Int = 0
    var heartsA: Int = 0
    var heartsB: Int = 0
    var netA: Int { spadesA - heartsA }
    var netB: Int { spadesB - heartsB }
    var handBagsA: Int = 0
    var handBagsB: Int = 0
    static let empty = HandResult()
}

struct Totals {
    var spadesA = 0
    var heartsA = 0
    var spadesB = 0
    var heartsB = 0
    var allBagsA = 0
    var allBagsB = 0

    var gameA: Int { spadesA - heartsA }
    var gameB: Int { spadesB - heartsB }
}


// MARK: - Scoring

struct SpartsScorer {
    // Returns (points, handBags, newAllBags)
    static func scoreSpadesHand(
        bids: (Int, Int),  // team players in seating order
        took: (Int, Int),
        allBagsBefore: Int
    ) -> (points: Int, handBags: Int, newAllBags: Int) {

        // Separate nil vs non-nil tricks
        let nonNilTook =
            (bids.0 > 0 ? took.0 : 0) +
            (bids.1 > 0 ? took.1 : 0)

        let nilTricks =
            (bids.0 == 0 ? took.0 : 0) +
            (bids.1 == 0 ? took.1 : 0)

        let teamBid = bids.0 + bids.1

        var points = 0
        var handBags = 0
        var bags = allBagsBefore
        var bagPenaltyApplied = 0

        // Base made/set (only non-nil tricks can satisfy bid)
        if nonNilTook >= teamBid {
            points = Sparts.spadesPointsPerBid * teamBid
            handBags = nilTricks + max(0, nonNilTook - teamBid) // nil tricks always bag
        } else {
            points = -Sparts.spadesPointsPerBid * teamBid       // set
            handBags = nilTricks                                // when set, only nil tricks bag
        }

        // Apply bags to running, with –100 per 10
        bags += handBags
        while bags >= Sparts.bagPenaltyThreshold {
            points += Sparts.bagPenalty
            bagPenaltyApplied += Sparts.bagPenalty
            bags -= Sparts.bagPenaltyThreshold
        }

        // Per-player nil bonuses/penalties
        if bids.0 == 0 { points += (took.0 == 0) ? Sparts.nilSuccess : Sparts.nilFail }
        if bids.1 == 0 { points += (took.1 == 0) ? Sparts.nilSuccess : Sparts.nilFail }

        return (points, handBags, bags)
    }

    // Hearts penalty for a team, with moon handling
    static func scoreHearts(
        heartsCount: Int, tookQueen: Bool, shotMoon: Bool
    ) -> Int {
        if shotMoon {
            // Shooter’s team gets 0; the UI should add 104 to the other team instead.
            return 0
        }
        return (heartsCount * Sparts.heartValue) + (tookQueen ? Sparts.queenPenalty : 0)
    }

    // Score a single Hand, returning HandResult and updated cumulative bags
    static func scoreHand(_ hand: Hand, allBagsBeforeA: Int, allBagsBeforeB: Int) -> (HandResult, newAllBagsA: Int, newAllBagsB: Int) {
        let p = hand.players
        precondition(p.count == 4, "Expected 4 players")

        // Team A (players 0,1)
        let bidsA = (p[0].spadesBid, p[1].spadesBid)
        let tookA = (p[0].spadesTook, p[1].spadesTook)
        let (spA, hbA, newAllA) = scoreSpadesHand(bids: bidsA, took: tookA, allBagsBefore: allBagsBeforeA)

        // Team B (players 2,3)
        let bidsB = (p[2].spadesBid, p[3].spadesBid)
        let tookB = (p[2].spadesTook, p[3].spadesTook)
        let (spB, hbB, newAllB) = scoreSpadesHand(bids: bidsB, took: tookB, allBagsBefore: allBagsBeforeB)

        // Hearts tallies
        let heartsA = p[0].heartsTaken + p[1].heartsTaken
        let heartsB = p[2].heartsTaken + p[3].heartsTaken
        let qA = p[0].tookQueenDiamond || p[1].tookQueenDiamond
        let qB = p[2].tookQueenDiamond || p[3].tookQueenDiamond

        var hA = scoreHearts(heartsCount: heartsA, tookQueen: qA, shotMoon: hand.teamAShotMoon)
        var hB = scoreHearts(heartsCount: heartsB, tookQueen: qB, shotMoon: hand.teamBShotMoon)

        // Moon redistribution (team-based, mutually exclusive in UI)
        if hand.teamAShotMoon { hB += Sparts.heartsFullHand } // +104 to other team
        if hand.teamBShotMoon { hA += Sparts.heartsFullHand }

        let result = HandResult(spadesA: spA, spadesB: spB, heartsA: hA, heartsB: hB, handBagsA: hbA, handBagsB: hbB)
        return (result, newAllBagsA: newAllA, newAllBagsB: newAllB)
    }
}

// MARK: - ViewModel

@MainActor
final class GameVM: ObservableObject {
    @Published var hands: [Hand]
    @Published private(set) var totals = Totals()

    init() {
        hands = [
            Hand(players: [
                PlayerInput(name: "Lecia"),
                PlayerInput(name: "Arthur"),
                PlayerInput(name: "Elena"),
                PlayerInput(name: "Jesse")
            ])
        ]
        recompute()
    }

    func addHand() {
        let last = hands.last?.players.map { PlayerInput(name: $0.name) } ?? [
            PlayerInput(name: "P1"), PlayerInput(name: "P2"), PlayerInput(name: "P3"), PlayerInput(name: "P4")
        ]
        hands.append(Hand(players: last))
        recompute()
    }

    func removeHand(_ hand: Hand) {
        if let idx = hands.firstIndex(where: { $0.id == hand.id }) {
            hands.remove(at: idx)
            if hands.isEmpty { addHand() }
            recompute()
        }
    }

    func recompute() {
        var running = Totals()
        for i in hands.indices {
            let (res, newAllA, newAllB) = SpartsScorer.scoreHand(hands[i], allBagsBeforeA: running.allBagsA, allBagsBeforeB: running.allBagsB)
            hands[i].result = res
            running.spadesA += res.spadesA
            running.spadesB += res.spadesB
            running.heartsA += res.heartsA
            running.heartsB += res.heartsB
            running.allBagsA = newAllA
            running.allBagsB = newAllB
        }
        totals = running
    }

    var gameEndsFlagA: Bool { totals.spadesA >= 600 || totals.heartsA >= 600 }
    var gameEndsFlagB: Bool { totals.spadesB >= 600 || totals.heartsB >= 600 }
}

// MARK: - UI

struct ContentView: View {
    @StateObject private var vm = GameVM()

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    header
                    totalsView
                    controls
                    Spacer()
                }
                .frame(width: geo.size.width * 0.28)

                Divider()

                ScrollView {
                    VStack(spacing: 16) {
                        ForEach($vm.hands) { $hand in
                            HandCard(hand: $hand) {
                                vm.removeHand(hand)
                            }
                            .onChange(of: hand) {
                                vm.recompute()
                            }                        }
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 12)
                }
            }
            .padding()
        }
        .navigationBarHidden(true)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Sparts Scorekeeper")
                .font(.largeTitle).bold()
            Text("Teams: A = Players 1 & 2 • B = Players 3 & 4")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var totalsView: some View {
        VStack(alignment: .leading, spacing: 10) {
            GroupBox("Running Totals") {
                VStack(alignment: .leading, spacing: 8) {
                    totalRow(team: "Team A", sp: vm.totals.spadesA, ht: vm.totals.heartsA, bags: vm.totals.allBagsA, game: vm.totals.gameA, ends: vm.gameEndsFlagA)
                    totalRow(team: "Team B", sp: vm.totals.spadesB, ht: vm.totals.heartsB, bags: vm.totals.allBagsB, game: vm.totals.gameB, ends: vm.gameEndsFlagB)
                }
                .font(.body.monospaced())
            }
        }
    }

    private func totalRow(team: String, sp: Int, ht: Int, bags: Int, game: Int, ends: Bool) -> some View {
        HStack {
            Text(team).frame(width: 70, alignment: .leading)
            Text("Spades: \(sp)")
            Text("Hearts: \(ht)")
            Text("Bags: \(bags)")
            Text("Game: \(game)").bold()
            if ends {
                Text("• END ≥600").foregroundStyle(.red).bold()
            }
        }
    }

    private var controls: some View {
        HStack {
            Button {
                vm.addHand()
            } label: {
                Label("Add Hand", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.return)

            Button(role: .destructive) {
                if let first = vm.hands.first {
                    vm.hands = [Hand(players: first.players.map { PlayerInput(name: $0.name) })]
                    vm.recompute()
                }
            } label: {
                Label("Reset Game", systemImage: "arrow.counterclockwise")
            }
            .buttonStyle(.bordered)
        }
    }
}

struct HandCard: View {
    @Binding var hand: Hand
    var onRemove: () -> Void

    private let numRange = Array(0...13)

    var body: some View {
        GroupBox {
            VStack(spacing: 12) {
                // Team flags (moon) - mutually exclusive
                HStack {
                    Toggle("Team A shot the moon", isOn:
                        Binding(get: { hand.teamAShotMoon },
                                set: { newValue in
                                    hand.teamAShotMoon = newValue
                                    if newValue { hand.teamBShotMoon = false }
                                })
                    )
                    Toggle("Team B shot the moon", isOn:
                        Binding(get: { hand.teamBShotMoon },
                                set: { newValue in
                                    hand.teamBShotMoon = newValue
                                    if newValue { hand.teamAShotMoon = false }
                                })
                    )
                    Spacer()
                    Button(role: .destructive, action: onRemove) {
                        Label("Remove Hand", systemImage: "trash")
                    }
                }

                // Grid headers
                Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
                    GridRow {
                        Text("Player").bold()
                        Text("Spades Bid").bold()
                        Text("Spades Took").bold()
                        Text("Hearts").bold()
                        Text("Q♦").bold()
                    }
                    ForEach(0..<4, id: \.self) { i in
                        GridRow {
                            TextField("Name", text: $hand.players[i].name)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 140)

                            picker($hand.players[i].spadesBid)
                            picker($hand.players[i].spadesTook)
                            picker($hand.players[i].heartsTaken)
                            Toggle("", isOn: $hand.players[i].tookQueenDiamond)
                                .labelsHidden()
                                .frame(width: 60)
                        }
                    }
                }

                Divider()

                // Per-hand computed summary
                HStack(spacing: 24) {
                    VStack(alignment: .leading) {
                        Text("Team A (P1 + P2)").font(.headline)
                        stat("Spades", hand.result.spadesA)
                        stat("Hearts", hand.result.heartsA)
                        stat("Net", hand.result.netA, bold: true)
                        stat("Hand Bags", hand.result.handBagsA)
                    }
                    VStack(alignment: .leading) {
                        Text("Team B (P3 + P4)").font(.headline)
                        stat("Spades", hand.result.spadesB)
                        stat("Hearts", hand.result.heartsB)
                        stat("Net", hand.result.netB, bold: true)
                        stat("Hand Bags", hand.result.handBagsB)
                    }
                    Spacer()
                }
            }
            .padding(.top, 4)
        } label: {
            Text("Hand").font(.headline)
        }
    }

    @ViewBuilder private func picker(_ binding: Binding<Int>) -> some View {
        Picker("", selection: binding) {
            ForEach(numRange, id: \.self) { v in
                Text("\(v)").tag(v)
            }
        }
        .pickerStyle(.menu)     // dropdown feel
        .frame(width: 110)
        .labelsHidden()
    }

    @ViewBuilder private func stat(_ title: String, _ value: Int, bold: Bool = false) -> some View {
        HStack {
            Text("\(title):")
                .foregroundStyle(.secondary)
            (bold ? Text("\(value)").bold() : Text("\(value)"))
        }
        .font(.body.monospaced())
    }
}

// MARK: - App (Landscape Lock via AppDelegate)

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        [.landscapeLeft, .landscapeRight]
    }
}

//@main
//struct SpartsApp: App {
//    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
//
//    var body: some Scene {
//        WindowGroup {
//            ContentView()
//        }
//    }
//}


#Preview {
    ContentView()
}
