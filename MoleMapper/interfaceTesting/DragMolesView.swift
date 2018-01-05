//
//  DragMolesView.swift
//  MoleMapper
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

protocol DragMolesUpdateDelegate {
    func updateMoleMeasurement(_ temporaryID: Int, withPosition: CirclePosition)
    // Tell container to create new mole (or placeholder)
    func addNewMoleMeasurement(position: CirclePosition) -> Int
    // Undo the earlier add
    func removeNewMoleMeasurement(_ temporaryID: Int)
    // Tell container to fix the mole's position
    func fixMole(_ withNumericID: Int)
}

protocol DragMolesDataSource {
    var initialMeasurementPositions: [Int:CirclePosition] { get }
}

class DragMolesView: UIView {
    fileprivate var imageView = UIImageView()
    fileprivate weak var image: UIImage!
    fileprivate var molePins: [Int:CircleAndPinView] = [:]          // widgets
    fileprivate var molePositionsRelativeToView: [Int:CirclePosition] = [:]       // locations relative to View
    fileprivate var initialMeasurementPositions: [Int:CirclePosition] = [:]                // locations relative to image
    fileprivate var idToUUID: [Int:String?] = [:]
    fileprivate var delegate: DragMolesUpdateDelegate!
    fileprivate var dataSource: DragMolesDataSource!
    
    init(frame: CGRect, image: UIImage,  dataSource: DragMolesDataSource, delegate: DragMolesUpdateDelegate) {
        super.init(frame: frame)
        
        self.image = image
        self.delegate = delegate
        self.dataSource = dataSource
        
        imageView.contentMode = .scaleAspectFit
        imageView.image = image
        imageView.frame = frame
        self.addSubview(imageView)
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(onTap(recognizer:)))
        addGestureRecognizer(tapRecognizer)
        
        initPins()
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func initPins() {
        // TODO: For each pin, see if we find a blob underneath that's roughly the right place and size.
        // "roughly" is defined as within the 40 pts or the diameter (whichever is larger) of the center and
        // between 80 - 120% of the original mole size
        
        for (numericID, position) in dataSource.initialMeasurementPositions {
            let fixableData = FixableData(fixableImage: self.image, fixableCircle: position)
            if let fixedCircle = AutoEncircle.autoEncircleMole(fixableData) {
                var tooFar: Bool = false
                
                let sqrDistance = TranslateUtils.squaredDistance(pt1: fixedCircle.center, pt2: position.center)
                let testDistance: CGFloat = (20 > fixedCircle.radius) ? 20.0 : fixedCircle.radius
                if sqrDistance > (testDistance * testDistance) {
                    // Too far, not in right place
                    tooFar =  true
                }
                if (fixedCircle.radius < (position.radius * 0.8)) || (fixedCircle.radius > (position.radius * 1.2)) {
                    tooFar = true
                }
                var pinType = CircleAndPinType.existingMolePin
                if tooFar {
                    pinType = CircleAndPinType.existingMoleUncertainPin
                }

                // TODO Test for margins here. For now, just see how we're doing
                let newPosition = TranslateUtils.imageToViewCircleTranslation(fixedCircle, imageSize: image.size, parentView: imageView)
                let newPin = CircleAndPinView(circlePosition: newPosition, parentView: self, delegate: self, pinType: pinType)
                self.addSubview(newPin)
                newPin.objectID = numericID
//                idToUUID[lastID] = moleMeasurement.moleMeasurementID!
                molePins[numericID] = newPin
                molePositionsRelativeToView[numericID] = newPosition
                let translatedPosition = TranslateUtils.viewToImageCircleTranslation(newPosition, imageSize: image.size, parentView: imageView)
                delegate.updateMoleMeasurement(numericID, withPosition: translatedPosition)
            }
        }
    }

    // Test some location (relative to view coordinates) against displayed moles
    func hitTest(_ location: CGPoint, _ radius: CGFloat) -> Int {
        var idTouched = -1
        for (nID, molePosition) in molePositionsRelativeToView {
            let thresholdDistance = molePosition.radius + radius
            let actualDistanceSquared = TranslateUtils.squaredDistance(pt1: molePosition.center, pt2: location)
            if actualDistanceSquared < (thresholdDistance * thresholdDistance) {
                idTouched = nID
            }
        }
        return idTouched
    }
    
    func onTap(recognizer: UITapGestureRecognizer) {
        let location = recognizer.location(in: self)
        let position = CirclePosition(center: location, radius: 15)
        // First, see if we're really close to another mole before adding it.
        // Since we don't have the actual diameter of the new mole yet,
        // "really close" is defined as the center of the new mole being
        // within 20 points of the edge of another mole.
        // == This only turns out to be partally good enough. It's a great first filter to prevent
        // obvious mis-touches, but if the autoEncircleMole (in addMole) gets "pulled" on top
        // of an existing mole, this test won't cover that condition.
        let idTouched = hitTest(position.center, position.radius)
        if idTouched < 0 {
            addMole(position)
        } else {
            showPinMenu(forID: idTouched)
        }
    }
    
    /**
     addMole is called by onTap which is called by a tap recognizer. Transformation
     from view coordinates to image coordinates must be performed before storing
     in a FixableData structure.
     
     Parameters:
     - position: CirclePosition relative to parent view's coordinate system
    */
    func addMole(_ position: CirclePosition) {
        let translatedCircle = TranslateUtils.viewToImageCircleTranslation(position, imageSize: image.size, parentView: imageView)
        
        let fixableData = FixableData(fixableImage: self.image, fixableCircle: translatedCircle)
        
        var viewPosition = position
        var imgPosition = translatedCircle
        if let fixedCircle = AutoEncircle.autoEncircleMole(fixableData) {
            imgPosition = fixedCircle
            viewPosition = TranslateUtils.imageToViewCircleTranslation(fixedCircle, imageSize: image.size, parentView: imageView)
        }
        
        // Need to test to make sure we didn't land on top of an existing mole
        let idTouched = hitTest(viewPosition.center, viewPosition.radius)
        if idTouched < 0 {
            let newID = delegate.addNewMoleMeasurement(position: imgPosition)
            
            let circleAndPinView = CircleAndPinView(circlePosition: viewPosition, parentView: self, delegate: self,
                                                    pinType: CircleAndPinType.newMolePin)
            circleAndPinView.objectID = newID
            
            molePins[newID] = circleAndPinView                                // local list of View objects associated with temp ID
            molePositionsRelativeToView[newID] = viewPosition
            self.showPinMenu(forID: newID)                           // close others and show this one
        } else {
//            showPinMenu(forID: idTouched)
            // This is better: it allows users to add a mole even if we don't "see" it with auto-encircle. They at least
            // have the opportunity to then fix it (because we'll obviously just use the default radius)
            let newID = delegate.addNewMoleMeasurement(position: translatedCircle)
            
            let circleAndPinView = CircleAndPinView(circlePosition: position, parentView: self, delegate: self,
                                                    pinType: CircleAndPinType.newMolePin)
            circleAndPinView.objectID = newID
            
            molePins[newID] = circleAndPinView                                // local list of View objects associated with temp ID
            molePositionsRelativeToView[newID] = position
            self.showPinMenu(forID: newID)                           // close others and show this one
        }
    }
    
    func updateMole(moleID: Int, newPosition: CirclePosition) {
        // Called by ViewController to push changes downstream (from Fix)
        let translatedPosition = TranslateUtils.imageToViewCircleTranslation(newPosition, imageSize: image.size, parentView: imageView)
        if let circleAndPinView = molePins[moleID] {
            circleAndPinView.displayQuestionMark(display: false)
            circleAndPinView.moveToCirclePosition(circlePosition: translatedPosition)
            molePositionsRelativeToView[moleID] = translatedPosition
        }
    }
    
    func showPinMenu(forID: Int) {
        // Hide all other pins
        for (moleID, pinView) in molePins {
            if moleID != forID {
                pinView.showPinMenu(false)
            }
        }
        // Show this pin
        molePins[forID]?.showPinMenu()
    }
}

extension DragMolesView: CircleAndPinDelegate {
    func acceptObject(_ withID: CInt) {
        // remove question mark...
        let moleID = Int(withID)
        if let circleAndPinView = molePins[moleID] {
            circleAndPinView.displayQuestionMark(display: false)
        }
    }
    
    func fixObject(_ withID: CInt) {
        delegate.fixMole(Int(withID))
    }
    
    func removeObject(_ withID: CInt) {
        let moleID = Int(withID)
        if let circleAndPinView = molePins[moleID] {
            circleAndPinView.showPinMenu(false)
            circleAndPinView.removeFromSuperview()
            molePins.removeValue(forKey: moleID)
            molePositionsRelativeToView.removeValue(forKey: moleID)
//            delegate.removeMole(withID: moleID)  -- these are only for "added now" moles; this is not the mechanism for deleting existing moles
            delegate.removeNewMoleMeasurement(moleID)
        }
    }
    
    // TODO: check to make sure this follows the new paradigm of what positions are relative to at what point
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
        
        var correctedPosition = newPosition     // default if no corrections
        if let fixedCircle = AutoEncircle.autoEncircleMole(fixableData) {
            // Local copy position is relative to view coordinates
            correctedPosition = TranslateUtils.imageToViewCircleTranslation(fixedCircle, imageSize: image.size, parentView: imageView)
            // external copy is relative to image
            delegate.updateMoleMeasurement(Int(withID), withPosition: fixedCircle)
        }
        // TODO: test to make sure circle didn't go way off...
        if let associatedPin = self.molePins[Int(withID)] {
            associatedPin.moveToCirclePosition(circlePosition: correctedPosition)
        }
        showPinMenu(forID: Int(withID))
    }
    
    func pinTapped(_ withID: CInt) {
        showPinMenu(forID: Int(withID))
    }

}

