//
//  SpartsApp.swift
//  Sparts Scoresheet
//
//  Created by Jesse Macbook Clark on 8/24/25.
//


// SpartsApp.swift
import SwiftUI

@main
struct SpartsApp: App {
    var body: some Scene {
        WindowGroup {
            let teams = [
                Teams(players: [Player(bid: 0, took: 0), Player(bid: 0, took: 0)], hearts: 0, queensSpades: false, moonShot: false),
                Teams(players: [Player(bid: 0, took: 0), Player(bid: 0, took: 0)], hearts: 0, queensSpades: false, moonShot: false)
            ]
            return ScoreTable(teams: teams)        }
    }
}

// MARK: - Preview
#Preview {
    let teams = [
        Teams(players: [Player(bid: 0, took: 0), Player(bid: 0, took: 0)], hearts: 0, queensSpades: false, moonShot: false),
        Teams(players: [Player(bid: 0, took: 0), Player(bid: 0, took: 0)], hearts: 0, queensSpades: false, moonShot: false)
    ]
    return ScoreTable(teams: teams)}
