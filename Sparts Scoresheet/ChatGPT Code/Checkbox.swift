//
//  Checkbox.swift
//  Sparts Scoresheet
//
//  Created by Jesse Macbook Clark on 8/24/25.
//

// CheckboxCellView.swift
import SwiftUI

struct CheckboxCellView: View {
    @Binding var isOn: Bool

    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Theme.cellBg)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.gridLine, lineWidth: 1))
                Image(systemName: isOn ? "checkmark.square.fill" : "square")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.black)
            }
        }
        .buttonStyle(.plain)
        .frame(minHeight: 36)
    }
}
