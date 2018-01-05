//
//  CircleAndPinView.swift
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

@objc protocol CircleAndPinDelegate {
    @objc optional func acceptObject(_ withID: CInt)
    @objc optional func fixObject(_ withID: CInt)
    @objc optional func removeObject(_ withID: CInt)
    @objc optional func objectMoved(withID: CInt, newPosition: CirclePosition)
    @objc optional func pinTapped(_ withID: CInt)
    @objc optional func invokeMoleMenu(_ withID: CInt)
}

/**
 *  For construction of segmented menu when moles are being edited/added
 */
enum CalloutSegments: Int {
    case fix
    case ok
    case cancel
    
    func toString() -> String {
        switch self {
        case .fix:
            return "Fix"
        case .ok:
            return "OK"
        case .cancel:
            return "Cancel"
        }
    }
    
    static let existingMole = [fix, ok]
    static let newObject = [cancel, fix, ok]
}

/**
 *  CircleAndPin types determine the look and interaction capabilities of the pin
 
    - reviewPin: For use with Zone Review display. 
        * Look: Pin only.
        * Behavior: tapping brings up bubble menu with mole name, stats, and sandwich menu.
    - cameraPin: For use in augmented-reality camera capture
        * Look: Pin only, no circle.
        * Behavior: none.
    - coinPin: For use in coin-detection on TapCoin
        * Look: red circle only
        * Behavior: tapping brings up `newObject` segmented menu.
    - newMoleUncertainPin: For use with TapMoles and DragMoles
        * Look: Pin, blue circle, question mark (TODO: semi-transparent pin)
        * Behavior: tapping brings up `newObject` segmented menu. Draggable.
    - newMolePin:
        * Look: Pin plus blue circle.
        * Behavior: tapping brings up `newObject` segmented menu. Draggable.
    - existingMoleUncertainPin:
        * Look: Pin plus blue circle.
        * Behavior: tapping brings up `existingMole` segmented menu. Draggable.
    - existingMolePin:
        * Look: Pin plus blue circle.
        * Behavior: tapping brings up `existingMole` segmented menu. Draggable.
    - calibrationPin:
        * Look: red circle
        * Behavior: tapping brings up `existingMole` segmented menu. Fixed.
 */
enum CircleAndPinType {
    case removedReviewPin
    case reviewPin
    case cameraPin
    case coinPin
    case newMoleUncertainPin
    case newMolePin
    case existingMoleUncertainPin
    case existingMolePin
    case calibrationPin
}

@objc
class CircleAndPinView: UIView {
    
    // MARK: Public properties
    var moleName: String? {
        didSet {
            updateMoleNameInCallout()
        }
    }
    var moleDetails: String?
    var objectID: Int?
    var circleColor: UIColor = UXConstants.mmBlue {
        didSet {
            if circleView != nil {
                circleView.circleColor = self.circleColor
                circleView.redrawCircle()
            }
        }
    }
    
    // MARK: Private properties
    fileprivate var circlePosition: CirclePosition!
    fileprivate var circleView: CircleView!
    fileprivate var dragEnabled: Bool = false
    fileprivate var panGestureRecognizer: UIPanGestureRecognizer!
    fileprivate let pinHeight: CGFloat = 30
    fileprivate let pinWidth: CGFloat = 21
    fileprivate let pinImageView = UIImageView()
    fileprivate var pinType: CircleAndPinType!
    fileprivate var showCircle: Bool = true
    fileprivate var showPin: Bool = true
    fileprivate var showQuestionMark: Bool = false
    fileprivate var tapEnabled: Bool = false
    fileprivate var tapGestureRecognizer: UITapGestureRecognizer!
    fileprivate let questionHeight: CGFloat = 26
    fileprivate let questionWidth: CGFloat = 26
    fileprivate var questionMarkView: UIImageView?
    
    fileprivate var delegate: CircleAndPinDelegate!
    
    fileprivate var calloutView: SMCalloutView?
    fileprivate var menuChoices: [CalloutSegments] = []

    fileprivate var moleMenu: SMCalloutView?

    
    // TODO: Turn plethora of show properties into bit-field enum
    // Non-trivial: see https://stackoverflow.com/questions/24112347/declaring-and-using-a-bit-field-enum-in-swift
    
    init(circlePosition: CirclePosition,
         parentView: UIView,
         delegate: CircleAndPinDelegate? = nil,
         pinType: CircleAndPinType) {
        
        super.init(frame: UIScreen.main.bounds)

        self.circlePosition = circlePosition
        self.delegate = delegate
        self.pinType = pinType
    
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(recognizer:)))
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(recognizer:)))
        
        self.backgroundColor = UIColor.clear
        
        configureLookAndBehavior(pinType)       // must do AFTER creating gesture recognizers
        
        // Add subviews before calling reLayoutSubviews()
        
        let pinRect = CGRect(x: 0, y: 0, width: pinWidth, height: pinHeight)
        pinImageView.bounds = pinRect
        pinImageView.contentMode = .scaleAspectFit
        pinImageView.image = UIImage(named: "molepinNoSpace")
//        pinImageView.alpha = 0.2  -- testing
        addSubview(pinImageView)

        let questionRect = showQuestionMark
            ? CGRect(x: 0, y: 0, width: questionWidth, height: questionHeight)
            : .zero
        questionMarkView = UIImageView()
        questionMarkView!.frame = questionRect
        questionMarkView!.contentMode = .scaleAspectFit
        questionMarkView!.image = UIImage(named: "questionMark")
        if showQuestionMark {
            addSubview(questionMarkView!)
        }
 
        let tempPosition = CirclePosition(rect: circlePosition.toCGRect())
        tempPosition.center = CGPoint(x: tempPosition.radius, y: tempPosition.radius)
        circleView = CircleView(fixableCircle: tempPosition)
        circleView.circleColor = self.circleColor
        addSubview(circleView)
        
        parentView.addSubview(self)
        
        moveToCirclePosition(circlePosition: circlePosition)
        
        // For now, it's just a way to test the code to create the SMCallout style menu
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(recognizer:)))
        self.addGestureRecognizer(longPressGestureRecognizer)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configureLookAndBehavior(_ forType: CircleAndPinType) {
        switch (forType) {
        case .removedReviewPin:
            self.showCircle = false
            self.showPin = true
            self.showQuestionMark = false
            self.tapEnabled = true
            self.dragEnabled = false
            self.pinImageView.alpha = 0.5
            break
        case .reviewPin:
            self.showCircle = false
            self.showPin = true
            self.showQuestionMark = false
            self.tapEnabled = true
            self.dragEnabled = false
            break
        case .cameraPin:
            self.showCircle = true
            self.showPin = false
            self.showQuestionMark = false
            self.tapEnabled = false
            self.dragEnabled = false
            break
        case .coinPin:
            self.showCircle = true
            self.circleColor = UXConstants.mmRed
            self.showPin = false
            self.showQuestionMark = false
            self.tapEnabled = true
            self.dragEnabled = false
            break
        case .newMoleUncertainPin:
            self.showCircle = true
            self.circleColor = UXConstants.mmBlue
            self.showPin = true
            self.showQuestionMark = true
            self.tapEnabled = true
            self.dragEnabled = true
            break
        case .newMolePin:
            self.showCircle = true
            self.circleColor = UXConstants.mmBlue
            self.showPin = true
            self.showQuestionMark = false
            self.tapEnabled = true
            self.dragEnabled = true
            break
        case .existingMoleUncertainPin:
            self.showCircle = true
            self.circleColor = UXConstants.mmBlue
            self.showPin = true
            self.showQuestionMark = true
            self.tapEnabled = true
            self.dragEnabled = true
            break
        case .existingMolePin:
            self.showCircle = true
            self.circleColor = UXConstants.mmBlue
            self.showPin = true
            self.showQuestionMark = false
            self.tapEnabled = true
            self.dragEnabled = true
            break
        case .calibrationPin:
            self.showCircle = true
            self.circleColor = UXConstants.mmRed
            self.showPin = false
            self.showQuestionMark = false
            self.tapEnabled = true
            self.dragEnabled = false
            break
        }

        if tapEnabled {
            addGestureRecognizer(tapGestureRecognizer)
        } else {
            removeGestureRecognizer(tapGestureRecognizer)
        }
        if dragEnabled {
            addGestureRecognizer(panGestureRecognizer)
        } else {
            removeGestureRecognizer(panGestureRecognizer)
        }
    }
    
    func currentPosition() -> CirclePosition {
        return self.circlePosition
    }
    
    func moveTo(newMolePosition: CGPoint) {
        // Move to new point relative to ???
        // Moves virtual center (of the mole) which is either the bottom of the
        // pin, when no circle is displayed, or the center of the circle
        
        var frameCenter = self.center
        let oldMolePosition = self.circlePosition.center
        frameCenter.x += newMolePosition.x - oldMolePosition.x
        frameCenter.y += newMolePosition.y - oldMolePosition.y
        
        self.center = frameCenter
        self.setNeedsDisplay()
    }
    
    func moveToCirclePosition(circlePosition: CirclePosition) {
        // Called when first created or when mole changes size
        // Calculate bounds rect sizes
        
        self.circlePosition = circlePosition
        
        let newCircleRect = circlePosition.toCGRect()
        let pinRect = pinImageView.bounds
        let questionRect = showQuestionMark
            ? CGRect(x: 0, y: 0, width: questionWidth, height: questionHeight)
            : .zero
        
        var maxWidth = newCircleRect.size.width
        if pinRect.size.width > maxWidth  {maxWidth = pinRect.size.width}
        if questionRect.size.width > maxWidth  {maxWidth = questionRect.size.width}
        
        var totalHeight:CGFloat = 0
        if showCircle { totalHeight += newCircleRect.size.height }
        if showPin { totalHeight += pinRect.size.height }
        if showQuestionMark { totalHeight += questionRect.size.height }
        
        // Calculate actual cumulative frame rect using circlePostion origin as the anchor
        let yOffset = totalHeight - (showCircle ? circlePosition.radius : 0)
        let xOffset = maxWidth / 2.0
        
        let newFrame = CGRect(x: circlePosition.center.x - xOffset,
                              y: circlePosition.center.y - yOffset,
                              width: maxWidth,
                              height: totalHeight)
        
        // Now reposition all the subviews
        self.frame = newFrame
        print(self.frame.debugDescription)
        
        let frameCenterX = newFrame.size.width / 2.0
        var boundsRect = CGRect.zero
        var runningY:CGFloat = 0.0
        
        // Set view bounds (relative to this View's frame)
        if showQuestionMark {
            boundsRect.origin.x = frameCenterX - (questionRect.width/2.0)
            boundsRect.origin.y = runningY
            boundsRect.size = questionRect.size
            questionMarkView?.frame = boundsRect
            runningY += questionRect.size.height
        } else {
            self.questionMarkView?.isHidden = true
        }
        
        if showPin {
            self.pinImageView.isHidden = false
            boundsRect.origin.x = frameCenterX - (pinRect.width/2.0)
            boundsRect.origin.y = runningY
            boundsRect.size = pinRect.size
            pinImageView.frame = boundsRect
            runningY += pinRect.size.height
        } else {
            self.pinImageView.isHidden = true
        }
        
        if showCircle {
            self.circleView.isHidden = false
            boundsRect.origin.x = frameCenterX - (newCircleRect.width/2.0)
            boundsRect.origin.y = runningY
            boundsRect.size = newCircleRect.size
            circleView.frame = boundsRect
            circleView.resizeCircleLayer(boundsRect.size)  // force redraw
        } else {
            self.circleView.isHidden = true
        }
    }
    
    func relayoutPin() {
        moveToCirclePosition(circlePosition: self.circlePosition)
    }
    
    func displayQuestionMark(display: Bool) {
        if display != showQuestionMark {
            showQuestionMark = display
            relayoutPin()
        }
    }

    func displayCircle(display: Bool) {
        if display != showCircle {
            showCircle = display
            relayoutPin()
        }
    }
    
    func displayPin(display: Bool) {
        if display != showPin {
            showPin = display
            relayoutPin()
        }
    }
    
    func getCirclePosition() -> CirclePosition {
        return self.circlePosition
    }
    
    func handleTap(recognizer: UITapGestureRecognizer) {
//        print("CircleAndPinView handleTap")
        //showPinMenu()
        if objectID != nil {
            delegate.pinTapped!(CInt(objectID!))
        }
    }
    
    func handleLongPress(recognizer: UILongPressGestureRecognizer) {
        print("long press here")
    }

    @objc private func handlePan(recognizer: UIPanGestureRecognizer) {
        let piece = self
        self.adjustAnchorPoint(gestureRecognizer: recognizer)
        
        if recognizer.state == .began || recognizer.state == .changed {
            // Get the distance moved since the last call to this method.
            let translation = recognizer.translation(in: self.superview)
            
            // Set the translation point to zero so that the translation distance
            // is only the change since the last call to this method.
            self.center = CGPoint(x: ((self.center.x) + translation.x),
                                    y: ((self.center.y) + translation.y))
            recognizer.setTranslation(CGPoint.zero, in: piece.superview)
            self.circlePosition.center.x += translation.x
            self.circlePosition.center.y += translation.y
        } else if recognizer.state == .ended {
            if delegate != nil {
                if self.objectID != nil {
                    delegate.objectMoved!(withID: CInt(self.objectID!), newPosition: self.circlePosition)
                }
            }
        }
    }
    
    private func adjustAnchorPoint(gestureRecognizer : UIGestureRecognizer) {
        if gestureRecognizer.state == .began {
            let view = circleView
            let midpoint = CGPoint(x: circleView!.bounds.size.width/2.0, y: view!.bounds.height/2.0)
            let locationInView = midpoint
            var locationInSuperview = gestureRecognizer.location(in: self)
            
            // Need to also add in the superview's offsets
            let sview = circleView.superview
            locationInSuperview.x += (sview?.bounds.origin.x)!
            locationInSuperview.y += (sview?.bounds.origin.y)!
            
            // Move the anchor point to the touch point and change the position of the view
            view?.layer.anchorPoint = CGPoint(x: (locationInView.x / (view?.bounds.size.width)!),
                                              y: (locationInView.y / (view?.bounds.size.height)!))
            // removed centering on touch point because it wasn't as usable; fingers get
            // in the way of seeing what is being moved.
        }
    }
    
    @objc private func handleSegmentedControlPressed(sender: UISegmentedControl) {
        
        let calloutItem = menuChoices[sender.selectedSegmentIndex]
        
        switch calloutItem {
            
        case CalloutSegments.fix:
//            print("handleSegmentedControlPressed fix")
            calloutView?.dismissCallout(animated: true)
            calloutView = nil
            if self.objectID != nil {
                // Too quickly calling the Fix screen is disconcerting.
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .milliseconds(300)) {
                    if let fixer = self.delegate {
                        fixer.fixObject!(CInt(self.objectID!))
                    }
                }
            }
            break
        case CalloutSegments.ok:
//            print("handleSegmentedControlPressed ok")
            calloutView?.dismissCallout(animated: true)
            calloutView = nil
            if self.objectID != nil {
                if let fixer = delegate {
                    fixer.acceptObject!(CInt(objectID!))
                }
            }
            break
        case CalloutSegments.cancel:
//            print("handleSegmentedControlPressed cancel")
            calloutView?.dismissCallout(animated: true)
            calloutView = nil
            if self.objectID != nil {
                if let fixer = delegate {
                    fixer.removeObject!(CInt(objectID!))
                }
            }
            break
        default:
            fatalError()
        }
    }
    
    func showPinMenu(_ doDisplay: Bool = true) {
        switch (self.pinType!) {
        case .removedReviewPin:
            showMoleMenu(doDisplay)
            break
        case .reviewPin:
            showMoleMenu(doDisplay)
            break
        case .cameraPin:
            print("Error: should not trigger ")
            break
        case .coinPin:
            showSegmentedMenu(doDisplay, menuChoices: CalloutSegments.newObject)
            break
        case .newMoleUncertainPin:
            showSegmentedMenu(doDisplay, menuChoices: CalloutSegments.newObject)
            break
        case .newMolePin:
            showSegmentedMenu(doDisplay, menuChoices: CalloutSegments.newObject)
            break
        case .existingMoleUncertainPin:
            showSegmentedMenu(doDisplay, menuChoices: CalloutSegments.existingMole)
            break
        case .existingMolePin:
            showSegmentedMenu(doDisplay, menuChoices: CalloutSegments.existingMole)
            break
        case .calibrationPin:
            showSegmentedMenu(doDisplay, menuChoices: CalloutSegments.existingMole)
            break
        }
    }
    
    private func showSegmentedMenu(_ doDisplay: Bool = true, menuChoices: [CalloutSegments]) {
        self.menuChoices = menuChoices
        
        if doDisplay == false {
            if calloutView != nil {
                calloutView!.dismissCallout(animated: true)
                calloutView = nil
            }
            return
        }

        guard calloutView == nil, let callout = SMCalloutView.platform() else { return }
        self.superview!.addSubview(callout)

        let titleFont : UIFont = UIFont.systemFont(ofSize: 16)
        
        let attributes = [
            NSFontAttributeName : titleFont
        ]

        let segControl = UISegmentedControl(items: nil)
        segControl.setTitleTextAttributes(attributes, for: .normal)
        for (index, item) in menuChoices.enumerated() {
            segControl.insertSegment(withTitle: item.toString(), at: index, animated: false)
        }
        segControl.isMomentary = true
        segControl.layer.cornerRadius = 4.0
        segControl.clipsToBounds = true
        
        segControl.addTarget(self, action: #selector(handleSegmentedControlPressed(sender:)), for: .valueChanged)
        
        callout.contentView = segControl
        callout.contentView.backgroundColor = UIColor.white
        
        callout.calloutOffset = CGPoint(x: 0, y: 20)    // 27 is the margin they create by default; this leaves a 7pt gap
        callout.permittedArrowDirection = .any
        callout.presentCallout(
            from: self.frame,
            in: self.superview!,
            constrainedTo: self.superview!,
            animated: true
        )

        callout.backgroundView.removeFromSuperview()
        
        calloutView = callout
    }
    
    private func updateMoleNameInCallout() {
        if calloutView != nil {
            calloutView!.title = moleName
            // Can't figure out how to force a redraw while displayed; instead "bounce" the callout
            showMoleMenu(false)
            showMoleMenu(true)
        }
    }

    // Translated from MolePin.m
    private func showMoleMenu(_ doDisplay: Bool = true) {
        if doDisplay == false {
            if calloutView != nil {
                calloutView!.dismissCallout(animated: true)
                calloutView = nil
            }
            return
        }

        guard calloutView == nil, let callout = SMCalloutView.platform() else { return }
        
        let menuButton = UIButton(type: .custom)
        menuButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        let menuButtonImage = UIImage(named: "molePinMenu")
        menuButton.setBackgroundImage(menuButtonImage, for: .normal)
        menuButton.addTarget(self, action: #selector(menuButtonPressed), for: .touchUpInside)
        
        calloutView = callout
        calloutView!.delegate = self
        if moleName != nil {
            calloutView!.title = moleName
        } else {
            calloutView!.title = "Moley McMoleface"
            // FIXME: remove before shipping and replace with error handling
        }
        if moleDetails != nil {
            calloutView!.subtitle = moleDetails
        } else {
            calloutView!.subtitle = "measurement n/a"
        }
        calloutView!.leftAccessoryView = menuButton
        
        //self.superview!.addSubview(callout)
        calloutView!.presentCallout(from: self.frame, in: self.superview, constrainedTo: self.superview, animated: true)
        
    }
    
    func menuButtonPressed() {
        guard objectID != nil, delegate.invokeMoleMenu != nil else { return }
        delegate.invokeMoleMenu!(CInt(objectID!))
    }
    
}

extension CircleAndPinView: SMCalloutViewDelegate {
    func calloutViewClicked(_ calloutView: SMCalloutView) {
        self.showPinMenu(false)
    }
    
}
