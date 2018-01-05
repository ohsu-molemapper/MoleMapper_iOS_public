//
//  TapMolesViewEx.swift
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
import SnapKit

protocol TapMolesViewDelegate {
    // called by View
    func addMole(withID: Int, position: CirclePosition)             // Position relative to IMAGE
    func removeMole(withID: Int)
    func fixMole(withID: Int)
    // called by Controller
    func tapMolesDidTapDone()
    func tapMolesDidTapCancel()
}

class TapMolesViewEx: UIView {
//    private var calloutView: SMCalloutView?
    fileprivate var imageView = UIImageView()
    fileprivate weak var image: UIImage!
    fileprivate var molePins: [Int:CircleAndPinView] = [:]          // widgets
    fileprivate var molePositions: [Int:CirclePosition] = [:]       // locations relative to VIEW
    fileprivate var lastID: Int = 0
    fileprivate var delegate: TapMolesViewDelegate!

    init(frame: CGRect, image: UIImage, delegate: TapMolesViewDelegate) {
        super.init(frame: frame)
        
        self.delegate = delegate
        self.image = image

        imageView.contentMode = .scaleAspectFit
        imageView.image = image
        imageView.frame = frame
        self.addSubview(imageView)
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(onTap(recognizer:)))
        addGestureRecognizer(tapRecognizer)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func onTap(recognizer: UITapGestureRecognizer) {
        func calcSquaredEuclid(pt1: CGPoint, pt2: CGPoint) -> CGFloat {
            return (pt1.x - pt2.x) * (pt1.x - pt2.x) + (pt1.y - pt2.y) * (pt1.y - pt2.y)
        }
        
        let location = recognizer.location(in: self)
        let position = CirclePosition(center: location, radius: 30)
        // TODO:
        // First, see if we're really close to another mole before adding it.
        // Since we don't have the actual diameter of the new mole yet,
        // "really close" is defined as the center of the new mole being
        // within 20 points of the edge of another mole.
        let touchMargin: CGFloat = 20.0
        var touching = false
        for (_,molePosition) in molePositions {
            let thresholdDistance = molePosition.radius + touchMargin
            let actualDistanceSquared = calcSquaredEuclid(pt1: molePosition.center, pt2: location)
            if actualDistanceSquared < (thresholdDistance * thresholdDistance) {
                touching = true
            }
        }
        if !touching {
            addMole(position)
        }
    }
        
    /**
     addMole is called internally to add a mole annotation.
     
     Parameters:
     position: the position of the mole (center and radius) relative to the View coordinate system.
     */
    func addMole(_ position: CirclePosition) {
        var newViewPosition = position
        var imagePosition = position
        imagePosition.center = TranslateUtils.viewToImageTranslation(position.center, imageSize: image.size, parentView: imageView)
        let fixableData = FixableData(fixableImage: self.image,
                                      fixableCircle: imagePosition)
        
        if let fixedCircle = AutoEncircle.autoEncircleMole(fixableData) {
            imagePosition = fixedCircle
            let retranslatedCenter = TranslateUtils.imageToViewTranslation(fixedCircle.center, imageSize: image.size, parentView: imageView)
            newViewPosition = CirclePosition(center: retranslatedCenter, radius: fixedCircle.radius)    // Need to scale radius if ever the photo is scaled
        }

        let moleID = lastID
        lastID += 1
        
        let circleAndPinView = CircleAndPinView(circlePosition: newViewPosition, parentView: self, delegate: self,
                                                pinType: CircleAndPinType.newMolePin)
        circleAndPinView.objectID = moleID
        
        molePins[moleID] = circleAndPinView                                // local list of View objects associated with temp ID
        molePositions[moleID] = newViewPosition
        self.showPinMenu(forID: moleID)                           // close others and show this one
        delegate.addMole(withID: Int(moleID), position: imagePosition)    // parent list of positions associated with temp ID
    }
    
    /**
     updateMole is called (via this view's controller) by the Container controller to pass on
     changes requested by a fix operation.
     
     Parameters:
     - moleID: temporary Int ID associated with the mole being updated
     - newPosition: the position of the mole relative to the image's coordinate system.
     */
    func updateMole(moleID: Int, newPosition: CirclePosition) {
        let retranslatedCenter = TranslateUtils.imageToViewTranslation(newPosition.center, imageSize: image.size, parentView: imageView)
        let newViewPosition = CirclePosition(center: retranslatedCenter, radius: newPosition.radius)    // Need to scale radius if ever the photo is scaled
        if let circleAndPinView = molePins[moleID] {
            circleAndPinView.moveToCirclePosition(circlePosition: newViewPosition)
            molePositions[moleID] = newViewPosition
        }
        print("x")
    }
    
    func showPinMenu(forID: Int) {
        for (moleID, pinView) in molePins {
            if moleID != forID {
                pinView.showPinMenu(false)
            }
        }
        molePins[forID]?.showPinMenu()
    }
}

extension TapMolesViewEx: CircleAndPinDelegate {
    func acceptObject(_ withID: CInt) {
        // pass
    }
    
    func fixObject(_ withID: CInt) {
        delegate.fixMole(withID: Int(withID))
    }
    
    func removeObject(_ withID: CInt) {
        let moleID = Int(withID)
        if let circleAndPinView = molePins[moleID] {
            circleAndPinView.removeFromSuperview()
            molePins.removeValue(forKey: moleID)
            molePositions.removeValue(forKey: moleID)
            delegate.removeMole(withID: moleID)
        }        
    }
    
    func pinTapped(_ withID: CInt) {
        showPinMenu(forID: Int(withID))
    }
    
    /**
     objectMoved is called by CircleAndPin. Motion is relative to the View.
     
     Parameters:
     - withID: CInt containing temporary local id associated with a mole
     - newPosition: the new location the pin was moved to (relative to View)
     */
    func objectMoved(withID: CInt, newPosition: CirclePosition) {
        let translatedPosition = TranslateUtils.viewToImageCircleTranslation(newPosition, imageSize: image.size, parentView: imageView)
        let fixableData = FixableData(fixableImage: self.image,
                                      fixableCircle: translatedPosition)
        
//        var correctedPosition = newPosition     // default if no corrections
        if let fixedCircle = AutoEncircle.autoEncircleMole(fixableData) {
            // Local copy position is relative to view coordinates
//            correctedPosition = TranslateUtils.imageToViewCircleTranslation(fixedCircle, imageSize: image.size, parentView: imageView)
            // external copy is relative to image
            self.updateMole(moleID: Int(withID), newPosition: fixedCircle)
            delegate.addMole(withID: Int(withID), position: fixedCircle)
        } else {
            self.updateMole(moleID: Int(withID), newPosition: translatedPosition)
            delegate.addMole(withID: Int(withID), position: translatedPosition)
        }
//        showPinMenu(forID: Int(withID))
    }
    

}

