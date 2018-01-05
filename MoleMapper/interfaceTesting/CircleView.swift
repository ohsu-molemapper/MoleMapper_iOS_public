//
//  CircleView.swift
//  FixRewrite
//
// Copyright (c) 2016, 2017 OHSU. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
// 1.  Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
//
// 2.  Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation and/or
// other materials provided with the distribution.
//
// 3.  Neither the name of the copyright holder(s) nor the names of any contributors
// may be used to endorse or promote products derived from this software without
// specific prior written permission. No license is granted to the trademarks of
// the copyright holders even if such marks are included in this software.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//

import UIKit

@objc class CircleView: UIView {
    // Public Properties
    var circleColor: UIColor = UXConstants.mmBlue
    var borderWidth: CGFloat = 2.0

    private var circleLayer: CAShapeLayer?
    private var fixDelegate: FixCircleDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    convenience init(fixableCircle: CirclePosition, delegate: FixCircleDelegate? = nil) {
        let frame = fixableCircle.toCGRect()
        self.init(frame: frame)
        self.backgroundColor = UIColor.clear
        
        fixDelegate = delegate
        
        rescaleCircleLayer(1.0)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func redrawCircle() {
        let newCircleLayer = CAShapeLayer()
        newCircleLayer.path = UIBezierPath(ovalIn:bounds).cgPath
        newCircleLayer.strokeColor = circleColor.cgColor
        newCircleLayer.fillColor = UIColor.clear.cgColor
        newCircleLayer.lineWidth = borderWidth
        
        if let circleLayer = circleLayer {
            self.layer.replaceSublayer(circleLayer, with: newCircleLayer)
        } else {
            self.layer.addSublayer(newCircleLayer)
        }
        circleLayer = newCircleLayer
            self.setNeedsDisplay()
    }
    
    func resizeCircleLayer(_ newsize: CGSize) {
        // NOTE: setting bounds automatically sets frame adjusting around adjustPoint which defaults
        // to the center (where we want it)
        self.bounds.size.width = newsize.width
        self.bounds.size.height = newsize.height

        redrawCircle()
    }
    
    func rescaleCircleLayer(_ scale: CGFloat) {
        // rescale based on bounds
        // it's a circle so we only need to calculate one dimension
        let oldsize = self.bounds.size.width
        let newsize = oldsize * scale
        self.bounds.size.width = newsize
        self.bounds.size.height = newsize
        // NOTE: setting bounds automatically sets frame adjusting around adjustPoint which defaults
        // to the center (where we want it)

        redrawCircle()
    }
}
