//
//  Incrementing Number Cell.swift
//  Sparts Scoresheet
//
//  Created by Jesse Macbook Clark on 8/24/25.
//

// IncrementingCellView.swift
import SwiftUI

struct IncrementingCellView: View {
    // nil means unset -> draws “--”
    @Binding var value: Int?
    var min: Int = 0
    var max: Int = 13
    var wrap: Bool = true

    // pixels per step
    var stepPx: CGFloat = 22

    @State private var isPressed = false
    @State private var accum: CGFloat = 0

    private func step(_ delta: Int) {
        guard let v = value else {
            // first step picks an endpoint in the step direction
            value = (delta > 0) ? min : max
            return
        }
        let nv = v + delta
        if nv > max || nv < min {
            // boundary -> unset
            value = nil
        } else {
            value = nv
        }
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(isPressed ? Theme.cellBgPressed : Theme.cellBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Theme.gridLine, lineWidth: isPressed ? 2 : 1)
                    )
                Text(value.map(String.init) ?? "--")
                    .font(.system(size: Swift.max(12, geo.size.height * 0.45), weight: .regular, design: .default))
                    .foregroundStyle(value == nil ? Theme.textDisabled : Theme.textAccentBlue)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { g in
                        isPressed = true
                        accum += g.translation.width - (g.predictedEndTranslation.width - g.translation.width)
                        // Convert new delta (only the incremental piece) to steps
                        // Simpler: re-read translation each frame and compute steps from accum.
                        let stepsF = accum / stepPx
                        if abs(stepsF) >= 1 {
                            let steps = Int(stepsF.rounded(.towardZero))
                            let dir = steps.signum()
                            for _ in 0..<abs(steps) { step(dir) }
                            accum -= CGFloat(steps) * stepPx
                        }
                    }
                    .onEnded { _ in
                        isPressed = false
                        accum = 0
                    }
            )
            .simultaneousGesture(
                TapGesture().onEnded { step(1) }
            )
        }
        .frame(minHeight: 36)
    }
}
