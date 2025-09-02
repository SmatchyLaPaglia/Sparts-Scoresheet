//
//  Models.swift
//  Sparts Scoresheet
//
//  Created by Jesse Macbook Clark on 8/24/25.
//

// Models.swift
import SwiftUI

struct Player: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var bid: Int?   // nil = unset
    var took: Int?  // nil = unset
}

struct Team: Identifiable, Hashable {
    let id = UUID()
    var players: [Player]      // [2]
    // Hearts section
    var hearts: Int?           // 0...13, nil=unset
    var queenSpades: Bool
    var moonShot: Bool
    // Running totals (visual placeholders for now)
    var spadesTotal: Int = 0
    var heartsTotal: Int = 0
    var gameTotal: Int = 0
    var allBags: Int = 0
}

struct Hand: Identifiable, Hashable {
    let id = UUID()
    var teams: [Team]          // [2]
}

final class ScoreSheetsVM: ObservableObject {
    @Published var hands: [Hand]

    init() {
        let t1 = Team(
            players: [Player(name: "A", bid: nil, took: nil),
                      Player(name: "B", bid: nil, took: nil)],
            hearts: nil, queenSpades: false, moonShot: false
        )
        let t2 = Team(
            players: [Player(name: "C", bid: nil, took: nil),
                      Player(name: "D", bid: nil, took: nil)],
            hearts: nil, queenSpades: false, moonShot: false
        )
        self.hands = [Hand(teams: [t1, t2])]
    }

    func addHand() {
        guard let last = hands.last else { return }
        // carry names, keep running totals, clear per-hand inputs
        func newTeam(from prev: Team) -> Team {
            var t = prev
            t.players = [
                Player(name: prev.players[0].name, bid: nil, took: nil),
                Player(name: prev.players[1].name, bid: nil, took: nil)
            ]
            t.hearts = nil; t.queenSpades = false; t.moonShot = false
            // keep totals (visual only now)
            return t
        }
        hands.append(Hand(teams: [newTeam(from: last.teams[0]), newTeam(from: last.teams[1])]))
    }

    func resetAll() {
        guard let first = hands.first else { return }
        func fresh(from t: Team) -> Team {
            Team(
                players: [
                    Player(name: t.players[0].name, bid: nil, took: nil),
                    Player(name: t.players[1].name, bid: nil, took: nil)
                ],
                hearts: nil, queenSpades: false, moonShot: false,
                spadesTotal: 0, heartsTotal: 0, gameTotal: 0, allBags: 0
            )
        }
        hands = [Hand(teams: [fresh(from: first.teams[0]), fresh(from: first.teams[1])])]
    }
}
