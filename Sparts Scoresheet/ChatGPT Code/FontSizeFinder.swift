//
//  FontSizeFinder.swift
//  Sparts Scoresheet
//
//  Created by Jesse Macbook Clark on 9/4/25.
//

import SwiftUI
import UIKit

struct HeaderSpec {
    let text: String
    let maxWidth: CGFloat
    let maxHeight: CGFloat
    let maxLines: Int
}

/// Core fitter: find the largest font size in [minSize, maxSize] that fits the box and line cap.
private func maxFontSizeThatFits(
    _ spec: HeaderSpec,
    baseFont: UIFont,                 // weight/family comes from here
    minSize: CGFloat = 6,
    maxSize: CGFloat = 96
) -> CGFloat {
    var lo = minSize
    var hi = maxSize
    var best: CGFloat = minSize
    
    // paragraph style for wrapping and center alignment
    let para = NSMutableParagraphStyle()
    para.lineBreakMode = .byWordWrapping
    para.alignment = .center
    
    // binary search on font size
    for _ in 0..<18 {
        let mid = (lo + hi) * 0.5
        let testFont = baseFont.withSize(mid)
        let lineHeight = testFont.lineHeight
        
        let attr: [NSAttributedString.Key: Any] = [
            .font: testFont,
            .paragraphStyle: para
        ]
        // unconstrained height; width constrained to the cell
        let bounds = (spec.text as NSString).boundingRect(
            with: CGSize(width: spec.maxWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attr,
            context: nil
        ).integral
        
        // how many lines are we actually using?
        let usedLines = Int(ceil(bounds.height / max(lineHeight, 0.0001)))
        
        let fitsWidth  = bounds.width  <= spec.maxWidth + 0.5
        let fitsHeight = bounds.height <= spec.maxHeight + 0.5
        let fitsLines  = usedLines <= spec.maxLines
        
        if fitsWidth && fitsHeight && fitsLines {
            best = mid
            lo = mid // try larger
        } else {
            hi = mid // too big
        }
    }
    return floor(best)
}

/// Public API: compute one unified header font size that fits every header spec.
func unifiedHeaderFontSize(
    specs: [HeaderSpec],
    baseFont: UIFont = .systemFont(ofSize: 64, weight: .semibold),
    minSize: CGFloat = 6,
    maxSize: CGFloat = 96
) -> CGFloat {
    guard !specs.isEmpty else { return minSize }
    return specs
        .map { maxFontSizeThatFits($0, baseFont: baseFont, minSize: minSize, maxSize: maxSize) }
        .min() ?? minSize
}
