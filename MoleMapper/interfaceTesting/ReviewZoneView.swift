//
//  ReviewZoneView.swift
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

/*
    Placeholder classes; either replace with modified ZoneView* classes or integrate
    the ZoneView* classes into these classes.
 */

import UIKit

protocol ReviewZoneViewDelegate {
    func remeasureZoneCmd()
    func displayMoleMenuCmd(forID: Int)
}

class ReviewZoneView: UIView {

    private var imageView = UIImageView()
    fileprivate weak var image: UIImage!
    private var buttonView = UIButton()
    private var buttonBackground = UIView()
    
    fileprivate var molePins: [String:CircleAndPinView] = [:]             // widgets
    fileprivate var molePositions: [String:CirclePosition] = [:]       // locations
    fileprivate var tempIdToUUID: [Int:String] = [:]                         // int ids needed by CircleAndPin system
    fileprivate var delegate: ReviewZoneViewDelegate!
    fileprivate var moleMeasurements: [MoleMeasurement30]!
    
    convenience init(frame: CGRect, image: UIImage, moleMeasurements: [MoleMeasurement30], delegate: ReviewZoneViewDelegate) {
        self.init(frame: frame)
        
        self.delegate = delegate
        self.image = image
        self.moleMeasurements = moleMeasurements

        // Add image view
        imageView.contentMode = .scaleAspectFit
        imageView.image = image
        imageView.frame = frame
        self.addSubview(imageView)
        
        var currentID = 0
        
        // Add mole pins
        for (moleMeasurement) in moleMeasurements {
            var moleCenter = CGPoint(x: CGFloat(moleMeasurement.moleMeasurementX!),
                                     y: CGFloat(moleMeasurement.moleMeasurementY!))
            // Translate from image to screen
            moleCenter = TranslateUtils.imageToViewTranslation(moleCenter, imageSize: image.size, parentView: imageView)
            
            let newPosition = CirclePosition(center: moleCenter, radius: CGFloat(moleMeasurement.moleMeasurementDiameterInPoints!) / 2.0)
            var pinType = CircleAndPinType.reviewPin
            if moleMeasurement.whichMole!.moleWasRemoved {
                pinType = CircleAndPinType.removedReviewPin
            }
            let newPin = CircleAndPinView(circlePosition: newPosition, parentView: self, delegate: self, pinType: pinType)
            newPin.objectID = currentID
            
            newPin.moleName = moleMeasurement.whichMole?.moleName
            if let calculatedMeasurement = moleMeasurement.whichMole?.mostRecentMeasurement(true) {
                // date + size is too much info; stick with size
//                var dateString = calculatedMeasurement.date?.description ?? "Unknown date"
                var sizeString = "Size: n/a"
                if let moleSize = calculatedMeasurement.calculatedMoleDiameter {
                    if moleSize.floatValue > 0 {
                        let formatter = NumberFormatter()
                        formatter.maximumFractionDigits = 1
                        sizeString = "Size: " + (formatter.string(from: moleSize) ?? "bad")
                    }
                }
//                if let measurementDate = calculatedMeasurement.date {
//                    let dateFormatter = DateFormatter()
//                    dateFormatter.dateStyle = .medium
//                    dateFormatter.timeStyle = .short
//                    dateString = dateFormatter.string(from: measurementDate as Date)
//                    print(measurementDate.debugDescription)
//                }
                newPin.moleDetails = sizeString + " mm"
            } else {
                newPin.moleDetails = "not measured yet"
            }
            
            if let uuid = moleMeasurement.whichMole?.moleID {
                self.addSubview(newPin)
                molePins[uuid] = newPin
                molePositions[uuid] = newPosition
                tempIdToUUID[currentID] = uuid
                currentID += 1
            }
        }
        
        // Add button (first background then button)
#if OLD_TRANSPARENT_INSTRUCTION
        buttonBackground.backgroundColor = UIColor(colorLiteralRed: 1.0, green: 1.0, blue: 1.0, alpha: 0.8)
        buttonBackground.layer.cornerRadius = 10.0      // TODO: UX constant
        self.addSubview(buttonBackground)
        buttonView.titleLabel?.font = UIFont.systemFont(ofSize: 20.0)
        buttonView.setTitle("Tap to re-measure", for: .normal)
        buttonView.setTitleColor(UXConstants.mmBlue, for: .normal)
        self.addSubview(buttonView)
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(onTap(recognizer:)))
        buttonBackground.addGestureRecognizer(tapRecognizer)
        buttonView.addGestureRecognizer(tapRecognizer)
        
        // Arrange windows
        var buttonSize = UIScreen.main.bounds.size
        buttonSize.width -= (self.layoutMargins.left + self.layoutMargins.right)
        buttonSize = buttonView.sizeThatFits(buttonSize)
        
        var buttonBackgroundSize = buttonSize
        buttonBackgroundSize.width += 40
        buttonBackgroundSize.height += 20
        
        buttonBackground.snp.remakeConstraints { (make) in
            make.centerX.equalTo(self.snp.centerX)
            make.width.equalTo(buttonBackgroundSize.width)
            make.height.equalTo(buttonBackgroundSize.height)
            make.bottom.equalTo(self.snp.bottom).offset(-30)
        }
        buttonView.snp.remakeConstraints { (make) in
            make.center.equalTo(buttonBackground.snp.center)
            make.width.equalTo(buttonSize.width)
            make.height.equalTo(buttonSize.height)
        }
    
#else
        let snapButton = createRoundedButton(title: "Photograph zone")
        self.addSubview(snapButton)
        snapButton.snp.remakeConstraints({ (make) in
            make.centerX.equalTo(self.snp.centerX)
            make.height.equalTo(44)
            make.width.equalTo(146)
            make.bottom.equalTo(self.snp.bottom).offset(-30)
        })
#endif

    }
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // TODO: Copied from InstructionView.swift; similar to APCButton...consolidation is in order
    func createRoundedButton(title: String) -> UIButton {
        // Reverse-engineered RK task button
        let btn = UIButton(type: .custom)
        btn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 6, bottom: 0, right: 6)
        btn.addTarget(self, action: #selector(onTap(_:)), for: .touchUpInside)
        btn.addTarget(self, action: #selector(onPress(_:)), for: .touchDown)
        btn.setTitle(title, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        btn.backgroundColor = .white
        btn.setTitleColor(UXConstants.mmBlue, for: .normal)
        btn.setTitleColor(.white, for: .highlighted)
        btn.layer.cornerRadius = 5
        btn.layer.borderColor = UXConstants.mmBlue.cgColor
        btn.layer.borderWidth = 1
        btn.bounds.size = CGSize(width: 146, height: 44)
        return btn
    }
    
    func onPress(_ sender:Any) {
        if sender is UIButton {
            (sender as! UIButton).backgroundColor = UXConstants.mmBlue
        }
    }
    
    func onTap(_ sender: Any) {
        if sender is UIButton {
            (sender as! UIButton).backgroundColor = .white
        }
        self.delegate.remeasureZoneCmd()
    }
    
//    func onTap(recognizer: UITapGestureRecognizer) {
//        // trigger the new zone measurement sequence
//        self.delegate.remeasureZoneCmd()
//    }
    
    func showPinMenu(forID: Int) {
        let moleUUID = tempIdToUUID[forID]
        for (moleID, pinView) in molePins {
            if moleID != moleUUID {
                pinView.showPinMenu(false)
            }
        }
        molePins[moleUUID!]?.showPinMenu()
    }
    
    func changePinType(_ forID: Int, _ newType:CircleAndPinType) {
        // configureLookAndBehavior
        if let moleUUID = tempIdToUUID[forID] {
            if let pin = molePins[moleUUID] {
                pin.configureLookAndBehavior(newType)
            }
        }
    }
    
    func removePin(_ forID: Int) {
        if let moleUUID = tempIdToUUID[forID] {
            if let pin = molePins[moleUUID] {
                pin.showPinMenu(false)
                pin.removeFromSuperview()
                tempIdToUUID.removeValue(forKey: forID)
            }
        }
    }
    
    func updatePinTitle(_ newName:String, forID: Int) {
        if let moleUUID = tempIdToUUID[forID] {
            if let pin = molePins[moleUUID] {
                pin.moleName = newName
            }
        }
    }

}

extension ReviewZoneView: CircleAndPinDelegate {
    func acceptObject(_ withID: CInt) {
        // pass - no action in this context
    }
    
    func fixObject(_ withID: CInt) {
        // pass - no action in this context
        print("ReviewZoneView.fixObject delegate handler")
    }
    
    func removeObject(_ withID: CInt) {
        // pass - no action in this context
    }
    
    func pinTapped(_ withID: CInt) {
        showPinMenu(forID: Int(withID))
    }
    
    func invokeMoleMenu(_ withID: CInt) {
        // Bring up actual mole menu
        delegate.displayMoleMenuCmd(forID: Int(withID))
    }

}
