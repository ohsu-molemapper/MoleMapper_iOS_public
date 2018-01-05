//
// CalibrationCoinViewController.swift
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

import UIKit
import AVFoundation

@objc class CalibrationCoinViewController: MoleMapperPhotoController {
    
    var calibrationCoinView: CalibrationCoinView?

    override func loadView() {
        super.loadView()
        let previewView = super.getPreviewView()
        previewView.frame.origin.y = 0              // wee little hack to use this inside a navigation controller
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        calibrationCoinView = CalibrationCoinView(parentView: self.view, capturingDelegate: self)
    }
    
    // MARK: Change look of scene
    func getCurrentCoinCenter() -> CGPoint {
        let coinPosition = calibrationCoinView?.getCoinPosition()
        return coinPosition?.center ?? CGPoint.zero
    }
    
    func changeCoinPosition(phonePosition: PhonePosition) {
        calibrationCoinView?.changeCoinPosition(phonePosition: phonePosition)
    }
   
    func changeInstructions(instructions: String) {
        calibrationCoinView?.changeInstructions(instructions: instructions)     // the short-hand Swift way
    }
    
    func tapTap(tapGesture: UITapGestureRecognizer) {
        print("Tap Tap")
    }
    
}

extension CalibrationCoinViewController: CalibrationCoinViewDelegate {
    func captureCoinImage(tapGesture: UITapGestureRecognizer) {
        focusAndExposeTap(gestureRecognizer: tapGesture)
    }
}
