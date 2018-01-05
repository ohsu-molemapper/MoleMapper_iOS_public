//
// CalibrationReviewAutosizedView.swift
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

protocol CalibrationReviewAutosizedViewProtocol: class {
    func fixCalibrationCoin(sender: CalibrationReviewAutosizedView)
}

class CalibrationReviewAutosizedView: UIView {

    fileprivate var image: UIImage!     // Need to keep copy to pass to "Fix" system
    fileprivate var coinPosition: CirclePosition?
    fileprivate var circleAndPinView: CircleAndPinView?
    var delegate: CalibrationReviewAutosizedViewProtocol?

    private var imageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.imageView.contentMode = .scaleAspectFit
        self.addSubview(imageView)
        self.backgroundColor = .black
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(onTap(recognizer:)))
        addGestureRecognizer(tapRecognizer)

        print("CalibrationReviewAutosizedView view size: \(self.frame)")
        imageView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    convenience init(frame: CGRect, image: UIImage, coinPosition: CirclePosition) {
        self.init(frame: frame)
        self.image = image
        self.imageView.image = image
        addCoin(coinPosition)
    }
    
    func setImage(image: UIImage) {
        self.image = image
        self.imageView.image = image
        
        self.setNeedsDisplay()
    }
    
    func onTap(recognizer: UITapGestureRecognizer) {
        circleAndPinView?.showPinMenu(true)
    }
    

    /**
    position is relative to image
    */
    func addCoin(_ position: CirclePosition) {
        let translatedCircle = TranslateUtils.imageToViewCircleTranslation(position, imageSize: image.size, parentView: self)

        coinPosition = translatedCircle // for later (relative to image)
        
        circleAndPinView = CircleAndPinView(circlePosition: translatedCircle, parentView: self, delegate: self,
                                            pinType: CircleAndPinType.calibrationPin)
        circleAndPinView!.showPinMenu()
        circleAndPinView!.objectID = 0           // object ID of some kind is needed: TODO add to initialization code
    }
    
    /**
    newPosition is relative to Image
    */
    func updateCoin(newPosition: CirclePosition) {
        // Called by ViewController to push changes downstream (from Fix)
        let translatedCenter = TranslateUtils.imageToViewTranslation(newPosition.center, imageSize: image.size, parentView: self)
        let translatedCircle = CirclePosition(center: translatedCenter, radius: newPosition.radius)
        if circleAndPinView != nil {
            circleAndPinView!.moveToCirclePosition(circlePosition: translatedCircle)
        }
    }

}
extension CalibrationReviewAutosizedView: CircleAndPinDelegate {
    func acceptObject(_ withID: CInt) {
        print("acceptObject")
        
    }
    
    func fixObject(_ withID: CInt) {
        print("fixObject")
        if coinPosition != nil {
            self.delegate?.fixCalibrationCoin(sender: self)
        }
    }
    
    func removeObject(_ withID: CInt) {
        // shouldn't be called?
        print("removeObject")
    }
    
    func pinTapped(_ withID: CInt) {
        print("pinTapped")
    }
    
}

