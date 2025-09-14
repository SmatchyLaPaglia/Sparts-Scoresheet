//
//  Theme.swift
//  Sparts Scoresheet
//
//  Created by Jesse Macbook Clark on 8/24/25.
//

// Theme.swift
import SwiftUI

enum Theme {
    static let bgApp           = Color.black
    static let gridLine        = Color(red: 0.125, green: 0.125, blue: 0.125)
    static let cellBg          = Color.white
    static let cellBgPressed   = Color(red: 0.91, green: 0.94, blue: 0.996)
    static let textPrimary     = Color(red: 240/255.0, green: 240/255.0, blue: 240/255.0)
    static let textSecondary   = Color(red: 180/255.0, green: 180/255.0, blue: 180/255.0)
    static let textOnLight     = Color.black
    static let textDisabled    = Color.gray.opacity(0.6)
    static let textAccentBlue  = Color(red: 0.24, green: 0.63, blue: 1.0)

//    static let leftHeaderBg    = Color(red: 0.215, green: 0.215, blue: 0.215)
    static let leftHeaderBg    = Color(red: 0.385, green: 0.385, blue: 0.385)

    static let leftHeaderText  = Color.orange

    static let nameStripeLight = Color(red: 0.933, green: 0.933, blue: 0.933)
    static let nameStripeDark  = Color(red: 0.863, green: 0.922, blue: 0.882)

    static let rightMiniHeaderBg  = leftHeaderBg
    static let rightMiniHeaderTxt = leftHeaderText
    static let rightNumberTxt     = Color.white

    static let rightSpadesScoreBg = Color(red: 0.0, green: 0.52, blue: 0.55)
    static let rightHeartsScoreBg = Color(red: 0.0, green: 0.57, blue: 0.57)
    static let rightHandScoreBg   = Color(red: 0.0, green: 0.45, blue: 0.50)
    static let rightAllBagsBg     = Color(red: 0.0, green: 0.39, blue: 0.75)
    static let rightSpadesTotalBg = Color(red: 0.0, green: 0.43, blue: 0.75)
    static let rightHeartsTotalBg = Color(red: 0.0, green: 0.31, blue: 0.75)
    static let rightGameTotalBg   = Color(red: 0.63, green: 0.16, blue: 0.47)

    static let resetAllBg      = Color(red: 0.35, green: 0.35, blue: 0.39) // fixed “Reset All”
    static let newHandBg       = Color(red: 0.16, green: 0.63, blue: 1.0)  // fixed “New Hand”
    static let checkboxTick = Color(red: 0.0, green: 0.6, blue: 0.0) // adjust as needed
}
