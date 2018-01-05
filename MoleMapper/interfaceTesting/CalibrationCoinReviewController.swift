//
// CalibrationCoinReviewController.swift
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



class CalibrationCoinReviewController: UIViewController, UIScrollViewDelegate  {

    weak var delegate: (CalibrationCoinReviewDelegate & CalibrationReviewAutosizedViewProtocol)?
    
    convenience init(delegate: (CalibrationCoinReviewDelegate & CalibrationReviewAutosizedViewProtocol)) {
        self.init()
        
        self.delegate = delegate
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func loadView() {
/*
         From the ever helpful Apple API Reference:
         https://developer.apple.com/reference/uikit/uinavigationcontroller
         Note: Because the content view underlaps the navigation bar in iOS 7 and later, you must consider that space when designing your view controller content.
 */
        self.automaticallyAdjustsScrollViewInsets = false   // needed to prevent a strange bug (?) with how subviews of the scrollview are offset

        let viewFrame = self.parent?.view.bounds ?? TranslateUtils.calculateNavigationInnerFrameSize(navigationViewController: self.navigationController)

        let calibrationReviewView = CalibrationReviewView(frame: viewFrame)
        self.view = calibrationReviewView
        if delegate != nil {
            calibrationReviewView.delegate = delegate
        }
    }
    

    func loadImageData(imageDataSet: [CalibrationData]) {
        let calibrationReviewView = self.view as! CalibrationReviewView?
        if calibrationReviewView != nil {
            calibrationReviewView?.loadImageData(imageDataSet: imageDataSet)
        } else {
            print("Error: loadImages called but view not set yet in CalibrationCoinReviewController")
        }
    }

    func updateCirclePosition(circlePosition: CirclePosition, viewIndex: Int) {
        let calibrationReviewView = self.view as! CalibrationReviewView?
        calibrationReviewView?.updateCirclePosition(circlePosition: circlePosition, viewIndex: viewIndex)
    }

}
