//
//  OutlineView.swift
//  Scanner
//
//  Copyright © 2022 Ruvim Miksanskiy
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import UIKit

final class OutlineView: UIView {
    private var currentRect: CGRect = .zero
    private let outlineLayer = CAShapeLayer()

    override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
    }
}

extension OutlineView {
    // Initial setup
    private func setupView() {
        outlineLayer.lineWidth = 4
        outlineLayer.strokeColor = UIColor(named: "outlineColor")?.cgColor
        outlineLayer.fillColor = UIColor.clear.cgColor
        layer.addSublayer(outlineLayer)
    }
}

extension OutlineView {
    // Update outline position when metadata frame changes
    func updatePositionIfNeeded(frame: CGRect) {
        guard currentRect != frame else { return }
        currentRect = frame
        let animation = CABasicAnimation(keyPath: "path")
        animation.duration = 0.1
        animation.isAdditive = true
        outlineLayer.path = UIBezierPath(roundedRect: frame, cornerRadius: 10).cgPath
        outlineLayer.add(animation, forKey: nil)
        if outlineLayer.opacity == 0 {
            outlineLayer.opacity = 1
        }
    }
    
    // Hide outline layer
    func hideOutlineView() {
        outlineLayer.opacity = 0
    }
}
