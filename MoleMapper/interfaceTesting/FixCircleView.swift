//
//  FixCircleView.swift
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

class FixCircleView: UIView, UIScrollViewDelegate {

    var circleColor: UIColor {
        didSet {
            if circleView != nil {
                circleView.circleColor = self.circleColor
                circleView.redrawCircle()
            }
        }
    }

    private let controlMargin: CGFloat = 15
    private let controlSize: CGFloat = 44
    private let maximumZoomScale: CGFloat = 10
    private let minimumZoomScale: CGFloat = 0.25
    private let scrollIncrement: CGFloat = 0.5
    private var cumulativeZoom: CGFloat = 1.0

    private var circleView: CircleView!
    private let imageView = UIImageView()
    private let scrollView = UIScrollView()
    
    private weak var delegate: FixCircleDelegate!
    private weak var fixableData: FixableData!

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(frame: CGRect,
         fixableData: FixableData,
         delegate: FixCircleDelegate) {
        
        circleColor = UXConstants.mmBlue
        super.init(frame: frame)
        
        self.delegate = delegate
        self.fixableData = fixableData
        
        let image = fixableData.fixableImage

        scrollView.delegate = self
        scrollView.contentSize = image.size
        scrollView.isScrollEnabled = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        zoomLock(true)
        addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }

        scrollView.addSubview(imageView)
        imageView.contentMode = .scaleAspectFit
        imageView.image = image
        imageView.frame = frame
        
        let minusButton = UIButton()
        minusButton.contentMode = .scaleAspectFill
        minusButton.setImage(UIImage(named: "mapMinus"), for: .normal)
        minusButton.addTarget(self, action: #selector(minusButtonTapped), for: .touchUpInside)
        addSubview(minusButton)
        minusButton.snp.makeConstraints { make in
            make.bottom.equalTo(self.snp.bottomMargin).offset(-controlMargin)
            make.trailing.equalTo(self).offset(-controlMargin)
            make.width.equalTo(controlSize)
            make.height.equalTo(controlSize)
        }

        let plusButton = UIButton()
        plusButton.contentMode = .scaleAspectFill
        plusButton.addTarget(self, action: #selector(plusButtonTapped), for: .touchUpInside)
        plusButton.setImage(UIImage(named: "mapPlus"), for: .normal)
        addSubview(plusButton)
        plusButton.snp.makeConstraints { make in
            make.bottom.equalTo(minusButton.snp.top).offset(-2)
            make.height.equalTo(controlSize)
            make.width.equalTo(controlSize)
            make.trailing.equalTo(minusButton)
        }
        let centerButton = UIButton()
        centerButton.contentMode = .scaleAspectFill
        centerButton.addTarget(self, action: #selector(centerButtonTapped), for: .touchUpInside)
        centerButton.setImage(UIImage(named: "mapTarget"), for: .normal)
        
        addSubview(centerButton)
        centerButton.snp.makeConstraints { make in
            make.bottom.equalTo(plusButton.snp.top).offset(-controlMargin)
            make.trailing.equalTo(plusButton)
            make.width.equalTo(controlSize)
            make.height.equalTo(controlSize)
        }

        let retranslatedCenter = TranslateUtils.imageToViewTranslation(fixableData.fixableCircle.center, imageSize: image.size, parentView: imageView)
        let newViewPosition = CirclePosition(center: retranslatedCenter, radius: fixableData.fixableCircle.radius)    // Need to scale radius if ever the photo is scaled

        circleView = CircleView(fixableCircle: newViewPosition)
        scrollView.addSubview(circleView)

        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panCircle(recognizer:)))
        addGestureRecognizer(panRecognizer)
        
        let pinchRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(pinchCircle(gestureRecognizer:)))
        addGestureRecognizer(pinchRecognizer)
        
        DispatchQueue.main.async {
            self.centerImageOnCircle(animated: false)
        }
    }
    
    func panCircle(recognizer: UIPanGestureRecognizer) {
        // Move the anchor point of the view's layer to the touch point
        // so that moving the view becomes simpler.
        let piece = circleView
        self.adjustAnchorPoint(gestureRecognizer: recognizer)
        
        if recognizer.state == .began || recognizer.state == .changed {
            // Get the distance moved since the last call to this method.
            let translation = recognizer.translation(in: piece?.superview)
            
            // Set the translation point to zero so that the translation distance
            // is only the change since the last call to this method.
            piece?.center = CGPoint(x: ((piece?.center.x)! + translation.x),
                                    y: ((piece?.center.y)! + translation.y))
            recognizer.setTranslation(CGPoint.zero, in: piece?.superview)
        } else if recognizer.state == .ended {
            if delegate != nil {
                // Convert View coordinates to Image coordinates
                let fixedCircle = CirclePosition(rect: getUnscaledCircleRect())
                delegate.updateObject(objectPosition: fixedCircle)
            }
        }
    }
    
    func pinchCircle(gestureRecognizer: UIPinchGestureRecognizer) {
        if gestureRecognizer.state == .began || gestureRecognizer.state == .changed {
            circleView?.rescaleCircleLayer(gestureRecognizer.scale)
            // Set the scale factor to 1.0 to avoid exponential growth
            gestureRecognizer.scale = 1.0
        } else if gestureRecognizer.state == .ended {
            if delegate != nil {
                let fixedCircle = CirclePosition(rect: getUnscaledCircleRect())
//                fixedCircle.center = TranslateUtils.viewToImageTranslation(fixedCircle.center,
//                                                                           imageSize: fixableData.fixableImage.size,
//                                                                           parentView: self.imageView)
                delegate!.updateObject(objectPosition: fixedCircle)
            }
        }
    }
    
    func adjustAnchorPoint(gestureRecognizer : UIGestureRecognizer) {
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
    
    func centerButtonTapped() {
        centerImageOnCircle(animated: true)
    }
    
    func minusButtonTapped() {
        zoomImage(zoomIn: false)
    }
    
    func plusButtonTapped() {
        zoomImage(zoomIn: true)
    }
    
    
    func centerImageOnCircle(animated: Bool) {
        let circleViewFrame = circleView.frame
        let centerX = circleViewFrame.origin.x + circleViewFrame.size.width/2
        let centerY = circleViewFrame.origin.y + circleViewFrame.size.height/2
        
        let newOrigin = CGPoint(
            x: (centerX - scrollView.frame.size.width/2),
            y: (centerY - scrollView.frame.size.height/2)
        )
        
        scrollView.setContentOffset(newOrigin, animated: animated)
    }
    
    /**
     getwhatever compensates for scaling and translation before calculating
     the position of the new circle relative to the image
    */
    func getUnscaledCircleRect() -> CGRect {
        
        let scaleFactor = scrollView.zoomScale
        guard scaleFactor > 0 else { return CGRect.zero }
        
        
        let viewSize = imageView.frame.size     // May be scaled by scrollView

        var imageSize = fixableData.fixableImage.size
        imageSize.width *= scaleFactor
        imageSize.height *= scaleFactor
        let verticalPadding = (viewSize.height - imageSize.height) / 2.0
        let horizontalPadding = (viewSize.width - imageSize.width) / 2.0
        
        let scaledX = circleView.frame.origin.x - horizontalPadding     // translate before scaling
        let scaledY = circleView.frame.origin.y - verticalPadding
        let scaledWidth = circleView.frame.size.width
        let scaledHeight = circleView.frame.size.height
        
        return CGRect(
            x: scaledX/scaleFactor,
            y: scaledY/scaleFactor,
            width: scaledWidth/scaleFactor,
            height: scaledHeight/scaleFactor
        )
    }
    
    func zoomImage(zoomIn: Bool) {

        zoomLock(false)

        let oldZoomScale = scrollView.zoomScale
        
        scrollView.zoomScale = zoomIn
            ? oldZoomScale + scrollIncrement
            : oldZoomScale - scrollIncrement
        
        let scaleFactor = scrollView.zoomScale/oldZoomScale
        
        let oldX = circleView.frame.origin.x
        let oldY = circleView.frame.origin.y
        let oldWidth = circleView.frame.size.width
        let oldHeight = circleView.frame.size.height
        
        circleView.frame = CGRect(
            x: oldX*scaleFactor,
            y: oldY*scaleFactor,
            width: oldWidth*scaleFactor,
            height: oldHeight*scaleFactor
        )
        circleView.bounds.size = circleView.frame.size
        circleView.rescaleCircleLayer(1.0)
        zoomLock(true)
    }

    func zoomLock(_ lock: Bool) {
        if lock {
            scrollView.maximumZoomScale = 1
            scrollView.minimumZoomScale = 1
        } else {
            scrollView.maximumZoomScale = maximumZoomScale
            scrollView.minimumZoomScale = minimumZoomScale
        }
    }
    
    /**
    getCirclePosition returns the current object position relative to the View coordinate system
    Parameters:
    - none
 
    Returns: a CirclePosition who's center is relative to the View coordinate system.
    */
    func getCirclePosition() -> CirclePosition {
        // TODO: is this enough to place the circle? Do we also need to scale by scrollView.zoomScale?
        return CirclePosition(rect: circleView.frame)
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return scrollView.subviews[0]
    }

}
