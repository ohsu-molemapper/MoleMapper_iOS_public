//
// CalibrationCoinView.swift
// MoleMapper
//
// Copyright (c) 2017, OHSU. All rights reserved.
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
//  Based in large part on https://www.youtube.com/watch?v=Zv4cJf5qdu0
//


import UIKit
import AVFoundation
import SnapKit


protocol CalibrationCoinViewDelegate: class {
    func captureCoinImage(tapGesture: UITapGestureRecognizer)
}

enum PhonePosition {
    case close
    case midpoint
    case far
}

class CalibrationCoinView: UIView, UIGestureRecognizerDelegate {
    // Private properties
    private let text = UILabel()
    private let textBackdrop = UIView()
    private var circleView = CalibrationCircleView()
    private weak var parentView: UIView!
    private weak var capturingDelegate: CalibrationCoinViewDelegate!

   
    // Camera properties
//    let captureSession = AVCaptureSession()
    var previewLayer:CALayer!
    
    // Public properties
    var phonePosition = PhonePosition.close
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    convenience init(parentView: UIView, capturingDelegate: CalibrationCoinViewDelegate) {
        self.init(frame: parentView.frame)
        print("\(parentView.frame)")
        
        self.capturingDelegate = capturingDelegate
        self.parentView = parentView
        
        self.parentView.addSubview(textBackdrop)
        self.parentView.addSubview(text)
        self.parentView.addSubview(circleView)
        
        text.text = ""
        text.textColor = .darkText
        text.font = text.font.withSize(17.0)        // Magic Number Alert TODO: Guidelines
        text.numberOfLines = 0
        text.textAlignment = .center
        
        // slight gray background to stand out against a white background
        textBackdrop.backgroundColor = UIColor(colorLiteralRed: 0.9, green: 0.9, blue: 0.9, alpha: 0.8)
        textBackdrop.layer.cornerRadius = 5.0
        
        self.backgroundColor = UIColor.black
        
        let textGestureRecognizer = UITapGestureRecognizer(target: self,
                                                       action: #selector(self.handleTap(tapGesture: )))
        let circleGestureRecognizer = UITapGestureRecognizer(target: self,
                                                       action: #selector(self.handleTap(tapGesture: )))
        let backdropGestureRecognizer = UITapGestureRecognizer(target: self,
                                                       action: #selector(self.handleTap(tapGesture: )))
        textBackdrop.addGestureRecognizer(backdropGestureRecognizer)
        circleView.addGestureRecognizer(circleGestureRecognizer)
        text.isUserInteractionEnabled = true        // UILabels are false by default
        text.addGestureRecognizer(textGestureRecognizer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func handleTap(tapGesture: UITapGestureRecognizer) {
        capturingDelegate.captureCoinImage(tapGesture: tapGesture)
    }
    
    // MARK: - new methods
    /**
    getCoinPosition returns current coin position model relative to View
    */
    func getCoinPosition() -> CirclePosition {
        var radius = CGFloat(0.0)
        let parentViewWidth = self.bounds.width
        switch phonePosition {
        case .close:
            radius = parentViewWidth / CGFloat(7.5)
        case .midpoint:
            radius = parentViewWidth / CGFloat(9.0)
        case .far:
            radius = parentViewWidth / CGFloat(10.0)
        }
        return CirclePosition(center: CGPoint(x: self.center.x, y: self.center.y - radius * 2), radius: radius)
    }
    
    func layoutWidgets() {

        // Setup circle widget
        // TODO: place coin in the middle of the remaining space between the photo top and text screen
        
        self.circleView.repositionCircle(position: getCoinPosition())
        
        // Text backdrop
        self.textBackdrop.snp.remakeConstraints { (make) in
            make.centerX.equalTo(self.parentView.snp.centerX)
            make.bottom.equalTo(self.parentView.snp.bottom).offset(-20)
            make.top.equalTo(self.parentView.snp.centerY).offset(20)
            make.width.equalTo(self.parentView.snp.width).offset(-20)
        }
        
        // Text
        // TODO: try to do this using insets instead
        self.text.snp.remakeConstraints { (make) in
            make.left.equalTo(self.textBackdrop.snp.left).offset(10)
            make.right.equalTo(self.textBackdrop.snp.right).offset(-10)
            make.top.equalTo(self.textBackdrop.snp.top).offset(10)
            make.bottom.equalTo(self.textBackdrop.snp.bottom).offset(-10)
        }
    }

    // MARK: - Change visible properties
    
    func changeCoinPosition(phonePosition: PhonePosition) {
        self.phonePosition = phonePosition
        layoutWidgets()
    }
    
    func changeInstructions(instructions: String) {
        self.text.text = instructions
    }

}
