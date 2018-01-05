//
//  Draggable.swift
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

@objc protocol DraggableDelegate {
    func draggableTapped(sender: UITapGestureRecognizer)
}

class Draggable: UIView {
    
    let minSizeComparedToSuperview: CGFloat = 0.05
    let maxSizeComparedToSuperview: CGFloat = 1.00
    private let touchableAreaBuffer: CGFloat = 44
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        
        let frame = self.bounds.insetBy(
            dx: -touchableAreaBuffer,
            dy: -touchableAreaBuffer
        )
        
        return frame.contains(point)
    }
    
    func getScaleView() -> UIView? {
        return nil
    }

    func panCircle(recognizer: UIPanGestureRecognizer) {
        
        adjustAnchorPoint(gestureRecognizer: recognizer)
        
        if recognizer.state == .began || recognizer.state == .changed {
            let translation = recognizer.translation(in: superview)
            center = CGPoint(x: (center.x + translation.x), y: (center.y + translation.y))
            recognizer.setTranslation(CGPoint.zero, in: superview)
        } else if recognizer.state == .ended {
            donePanning()
        }
    }
    
    func donePanning() {}
    
    func pinchCircle(recognizer: UIPinchGestureRecognizer) {
        
        adjustAnchorPoint(gestureRecognizer: recognizer)
        
        if recognizer.state == .began || recognizer.state == .changed {
            
            var scale = recognizer.scale
            
            if scale > 1 && (frame.size.height > maxSizeComparedToSuperview * (superview?.bounds.size.height)!) {
                scale = 1
            }
            
            if scale < 1 && (frame.size.height < minSizeComparedToSuperview * (superview?.bounds.size.height)!) {
                scale = 1
            }
            
            if let circleView = getScaleView() as? CircleView {
                let oldRadius = CirclePosition(rect: circleView.frame).radius
                circleView.transform = circleView.transform.scaledBy(x: scale, y: scale)
                let newRadius = CirclePosition(rect: circleView.frame).radius
                resizeToCirclePosition(oldRadius: oldRadius, newRadius: newRadius)
            } else {
                transform = transform.scaledBy(x: scale, y: scale)
            }
            recognizer.scale = 1
        }
    }
    
    func adjustAnchorPoint(gestureRecognizer: UIGestureRecognizer) {
        if gestureRecognizer.state == .began {
            let locationInView = gestureRecognizer.location(in: self)
            let locationInSuperview = gestureRecognizer.location(in: superview)
            
            layer.anchorPoint = CGPoint(x: (locationInView.x / bounds.size.width), y: (locationInView.y / bounds.size.height))
            center = locationInSuperview
        }
    }

    func resizeToCirclePosition(oldRadius: CGFloat, newRadius: CGFloat) {
        fatalError()
    }

    static func convert(circleFrame: CGRect, imageView: UIImageView) -> CirclePosition {
        let scaleX = imageView.image!.size.width / imageView.frame.size.width
        let scaleY = imageView.image!.size.height / imageView.frame.size.height
        let scale = scaleX > scaleY ? scaleX : scaleY

        let adjusterX = (imageView.frame.size.width - imageView.image!.size.width/scale) / 2
        let adjusterY = (imageView.frame.size.height - imageView.image!.size.height/scale) / 2

        let fullSizeRect = CGRect(
            x: (circleFrame.origin.x - adjusterX) * scale,
            y: (circleFrame.origin.y - adjusterY) * scale,
            width: circleFrame.size.width * scale,
            height: circleFrame.size.height * scale
        )

        return CirclePosition(rect: fullSizeRect)
    }
}
