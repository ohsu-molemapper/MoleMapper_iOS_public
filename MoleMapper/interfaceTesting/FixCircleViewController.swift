//
//  FixCircleViewController.swift
//  MoleMapper
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

@objc protocol FixCircleDelegate {
    func updateObject(objectPosition: CirclePosition)
}

class FixCircleViewController: UIViewController {
    fileprivate var fixableData: FixableData
    fileprivate weak var delegate: FixCircleDelegate!
    fileprivate var circleColor: UIColor = UXConstants.mmBlue

    /**
    init with FixableData and delegate
    Parameters:
    - fixableData: a FixableData object; all FixableData objects have a position that 
        is relative to the image also contained in the FixableData object.
    - delegate: a FixCircleDelegate.
    */
    init(fixableData: FixableData, delegate: FixCircleDelegate) {
        self.fixableData = fixableData
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        var frame = self.parent?.view.bounds
        if frame == nil {
            frame = UIScreen.main.bounds
        }
        
        let fixCircleView = FixCircleView(frame: frame!,
                                          fixableData: fixableData,
                                          delegate: self)
        view = fixCircleView
        fixCircleView.circleColor = self.circleColor
    }

    func fixCircleView() -> FixCircleView? {
        return isViewLoaded ? view as? FixCircleView : nil
    }
    
    func setCircleColor(_ newColor: UIColor) {
        self.circleColor = newColor
        if let circleview = fixCircleView() {
            circleview.circleColor = self.circleColor
        }
    }
    
}

// MARK: FixCircleDelegate

extension FixCircleViewController: FixCircleDelegate {
    /**
     updateObject passes fixableData object up the chain   
     Parameters:
     - objectPosition: a CirclePosition that contains the revised coordinates of the object
            relative to the image in the originally passed FixableData object.
    */
    func updateObject(objectPosition: CirclePosition) {
        delegate.updateObject(objectPosition: objectPosition)
    }
}

