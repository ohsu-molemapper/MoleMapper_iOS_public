//
//  TranslateUtils.swift
//  MoleMapper
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
//
//  Helper functions wrapped in a class to translate from on-screen locations to
//  image coordinates.
//

import Foundation

/**
 TranslatPoint is a set of static methods for translating to and from various frames of reference.
 The two most important frame of references are the Point coordinates in the UIImage representation
 of the captured camera image and the actual pixel-based full resolution JPEG image. Other important
 frames are the (potentially) scaled image inside a UIImageView where points relative to the View are
 different from points relative to the unscaled image.
 */
@objc(TranslateUtils)
class TranslateUtils : NSObject {
    // Note: use of "static" or "class" modifier makes the method a class method. However "class"
    // modifiers allow subclassing. No plans to subclass at this point.
    
    static let coinDiametersInMillemeters: [Int:Float] = [0:0, 1:19.05, 5:21.21, 10:17.91, 25: 24.26]
    
    /**
     mmPerSomething takes a diameter (either pixels or points, doesn't matter)
     and translates it into mm/something. The caller can use this to size moles.
     
     Parameters:
     - diameter: Float representing the number of "somethings" for the coin diameter
     - coinDenomination: value of the coin that was measured
     
     Returns: the ratio mm/something
     */
    static func mmPerSomething(diameter: Float, coinDenomiation: Int) -> Float {
        guard diameter > 0, coinDiametersInMillemeters.index(forKey: coinDenomiation) != nil
            else { return 0.0 }
        return coinDiametersInMillemeters[coinDenomiation]! / diameter
    }
    
    static func translateImageViewPointToImagePoint(imageView: UIImageView, point: CGPoint) -> CGPoint? {
        guard imageView.contentMode == .scaleAspectFit, let image = imageView.image else { return nil }
        
        let imageSize = image.size
        let viewFrame = imageView.frame
        
        let yOffset = (viewFrame.size.height - imageSize.height) / 2.0
        let xOffset = (viewFrame.size.width - imageSize.width) / 2.0
        
        // What would we need to multiply the image by to fit into
        // the frame in an aspectFit kind of way?
        let yScale = viewFrame.size.height / imageSize.height
        let xScale = viewFrame.size.width / imageSize.width
        let scale = min(yScale, xScale)
        
        var translatedPoint = point
        translatedPoint.x -= xOffset
        translatedPoint.y -= yOffset
        translatedPoint.x /= scale
        translatedPoint.y /= scale
        
        return translatedPoint
    }
    
    /**
     calcClippingRect calculates the location of the best clipping rect that will fit inside the
     bounds of the image given the initial location and retaining the clipping rect size.
     
     Parameters:
     - objectPosition: the initial center relative to the image passed (i.e. scaled correctly)
     - image: the image to be clipped. The orientation is consulted to correctly determine both the
        boundaries and whether to rotate the coordinates or not.
     - clippingSize: the desired size of the clipped image (scaled for the image)
     
     Returns: a CGRect relative to the .up (landscape) representation of the image.
    */
    static func calcClippingRect(objectPosition: CirclePosition, image: UIImage, clippingSize: CGSize) -> CGRect {
        let halfWidth = clippingSize.width / 2
        let halfHeight = clippingSize.height / 2
        var left: CGFloat = 0.0
        var right: CGFloat = 0.0
        var top: CGFloat = 0.0
        var bottom: CGFloat = 0.0
        var imageSize = image.size
        var adjustedClippingSize = clippingSize
        
        if image.imageOrientation == .up {
            left = objectPosition.center.x - halfWidth + 0.5        // center of pixel
            right = objectPosition.center.x + halfWidth - 0.5
            top = objectPosition.center.y - halfHeight + 0.5
            bottom = objectPosition.center.y + halfHeight - 0.5
        } else if image.imageOrientation == .right {
            left = objectPosition.center.y - halfHeight + 0.5        // center of pixel
            right = objectPosition.center.y + halfHeight - 0.5
            let newX = image.size.width - objectPosition.center.x
            top = newX - halfWidth + 0.5
            bottom = newX + halfWidth - 0.5
            imageSize.width = image.size.height
            imageSize.height = image.size.width
            adjustedClippingSize.width = clippingSize.height
            adjustedClippingSize.height = clippingSize.width
        } else {
            fatalError("Unexpected orientation in calcClippingRect")
        }
        adjustedClippingSize.width = floor(adjustedClippingSize.width)
        adjustedClippingSize.height = floor(adjustedClippingSize.height)
        
        // Only need to fix left and top (right and bottom are not used in final CGRect construction
        if left < 0 {
            left = 0
        }
        if right > imageSize.width {
            left = imageSize.width - adjustedClippingSize.width
        }
        if top < 0 {
            top = 0
        }
        if bottom > imageSize.height {
            top = imageSize.height - adjustedClippingSize.height
        }
        left = floor(left)
        top = floor(top)
        
        return CGRect(x: left, y: top, width: adjustedClippingSize.width, height: adjustedClippingSize.height)
    }
    
    /**
     translateDisplayCircleToJpegCircle translates a CirclePosition object from the display frame of reference to the JPEG
     image frame of reference.
     
     Parameters:
     - objectPosition: a CirclePosition relative to the display frame of reference
     - displaySize: size of display frame of reference (e.g. size of displayPhoto)
     - jpegSize: size of the JPEG image
     
     Returns: a CirclePosition object in the same location but relative to the JPEG image
    */
    static func translateDisplayCircleToJpegCircle(objectPosition: CirclePosition, displaySize: CGSize, jpegSize: CGSize) -> CirclePosition {
        let hscale = jpegSize.width / displaySize.width
        let vscale = jpegSize.height / displaySize.height
        var imageCenter = CGPoint(x: 0, y: 0)
        var imageRadius = CGFloat(1.0)
        if (round(hscale * 10) == round(vscale * 10)) {
            imageCenter.x = objectPosition.center.x / displaySize.width * jpegSize.width
            imageCenter.y = objectPosition.center.y / displaySize.height * jpegSize.height
            imageRadius = objectPosition.radius * hscale
        } else {
            print("Error in translateDisplayCircleToJpegCircle: orientations are wrong or scaling is off")
        }
        return CirclePosition(center: imageCenter, radius: imageRadius)
    }
    
    /**
        squaredDistance returns the *almost* Euclidean distance
 
        The final sqrt is not performed since it's not useful when you're
        simply comparing two distances (two points will always be closer
        or further apart whether the actual distance is compared or the
        squared distance is compared.)
     
        Parameters:
        - pt1: Point in some 2D space
        - pt1: Second point in some 2D space
     
        Returns: squared distance between the two points
     */
    static func squaredDistance(pt1: CGPoint, pt2: CGPoint) -> CGFloat {
        let delta_x = pt1.x - pt2.x
        let delta_y = pt1.y - pt2.y
        return (delta_x * delta_x + delta_y * delta_y)
    }
    
    
    /**
     calculateNavigationInnerFrameSize returns the frame of a window contained within
     a UINavigationController (at some level) compensating for the fact that transparent
     navigation bars work differently from opaque navigation bars.
     
     Parameters:
     - navigationViewController: The containing navigation view controller (or nil).
     
     Returns: CGRect with proper frame to fit where it belongs
     */
    static func calculateNavigationInnerFrameSize(navigationViewController: UINavigationController?) -> CGRect {
        var viewFrame = UIScreen.main.bounds
        
        if let vc = navigationViewController {
            viewFrame.size.height -= vc.navigationBar.bounds.size.height
            if vc.navigationBar.isTranslucent {
                // View gets tucked under the navigation bar; manually push below controller
                viewFrame.origin.y += vc.navigationBar.bounds.size.height
            } // else view automatically gets positioned below controller
        }
        // position below that statusBar always
        viewFrame.origin.y += UIApplication.shared.statusBarFrame.size.height
        viewFrame.size.height -= UIApplication.shared.statusBarFrame.size.height
        
        return viewFrame
    }
    /**
     cropMoleInImage specifically crops the image to 2X the mole's diameter taking into account edges.
     
     Parameters:
     - sourceImage: UIImage of the image to extract/crop the mole image from
     - moleLocation: CirclePosition of the mole to extract relative to the image passed (assumes portrait or ".right" orientation)
     - rotate90: Bool to specify if the cropped image should be rotated (generally, yes)
     - rescaleTo: CGFloat containing the edge length (moles are extracted as square images). 320 is a good size.
    */
    static func cropMoleInImage(sourceImage: UIImage, moleLocation: CirclePosition, rotate90: Bool = true, rescaleTo: CGFloat = 320) -> UIImage? {
        // multiply radius * 4 to provide some context around the actual mole image. Otherwise, it may be too small.
        let clippingRect = TranslateUtils.calcClippingRect(objectPosition: moleLocation,
                                                           image: sourceImage,
                                                           clippingSize: CGSize(width: moleLocation.radius * 4,
                                                                                height: moleLocation.radius * 4))
        let clippedImage = UIImage(cgImage: (sourceImage.cgImage?.cropping(to: clippingRect))!)
        var rotationAngle = Foundation.Measurement<UnitAngle>(value: 90.0, unit: .degrees)
        if rotate90 == false {
            rotationAngle = Foundation.Measurement<UnitAngle>(value: 0.0, unit: .degrees)
        }
        let transformedImage = TranslateUtils.rotateAndScaleImage(image: clippedImage,
                                                                  degrees: rotationAngle,
                                                                  newSize: CGSize(width: rescaleTo, height: rescaleTo))
        return transformedImage
        
    }

    /**
        viewTapPositionToImagePosition translates a point relative to a view captured by a tap gesture
        and translates it into a position in a UIImage that is presumed to be displayed in AspectFit.
     
        Parameters:
        - position: A CGPoint relative to the upper left corner of the view.
        - imageView: a UIImageView (derived) object that contains the displayed image
     
        Returns: a CGPoint relative to the upper left corner of the image.

    */
    static func viewTapPositionToImagePosition(position: CGPoint, imageView: UIImageView?) -> CGPoint {
        guard let view = imageView, let image = imageView?.image else { return CGPoint.zero }
        let imageSize = image.size
        let viewSize = view.frame.size
        let verticalPadding = (viewSize.height - imageSize.height) / 2.0
        let horizontalPadding = (viewSize.width - imageSize.width) / 2.0
        let widthScale = viewSize.width / imageSize.width
        let heightScale = viewSize.height / imageSize.height
        let scaleFactor = min(heightScale, widthScale)          // zero with AspectFit but prep'ing for alternatives
        
        var translatedPoint = CGPoint()
        translatedPoint.x = (position.x - horizontalPadding) * scaleFactor
        translatedPoint.y = (position.y - verticalPadding) * scaleFactor
        return translatedPoint
    }
    
    static func viewToImageTranslation(_ location: CGPoint, imageSize: CGSize, parentView: UIView) -> CGPoint  {
        let viewSize = parentView.frame.size
        let verticalPadding = (viewSize.height - imageSize.height) / 2.0
        let horizontalPadding = (viewSize.width - imageSize.width) / 2.0
        
        var translatedCenter = CGPoint()
        translatedCenter.x = location.x - horizontalPadding
        translatedCenter.y = location.y - verticalPadding
        return translatedCenter
    }
    
    static func imageToViewTranslation(_ location: CGPoint, imageSize: CGSize, parentView: UIView) -> CGPoint {
        let viewSize = parentView.frame.size
        let verticalPadding = (viewSize.height - imageSize.height) / 2.0
        let horizontalPadding = (viewSize.width - imageSize.width) / 2.0
        
        var translatedCenter = CGPoint()
        translatedCenter.x = location.x + horizontalPadding
        translatedCenter.y = location.y + verticalPadding
        return translatedCenter
    }
    
    static func viewToImageCircleTranslation(_ position: CirclePosition, imageSize: CGSize, parentView: UIView) -> CirclePosition  {
        let viewSize = parentView.frame.size
        let verticalPadding = (viewSize.height - imageSize.height) / 2.0
        let horizontalPadding = (viewSize.width - imageSize.width) / 2.0
        let widthScale = viewSize.width / imageSize.width
        let heightScale = viewSize.height / imageSize.height
        let scaleFactor = min(heightScale, widthScale)
        
        var translatedCenter = position.center
        translatedCenter.x -= horizontalPadding
        translatedCenter.y -= verticalPadding
        translatedCenter.x *= scaleFactor
        translatedCenter.y *= scaleFactor
        return CirclePosition(center: translatedCenter, radius: position.radius * scaleFactor)
    }
    
    static func imageToViewCircleTranslation(_ position: CirclePosition, imageSize: CGSize, parentView: UIView) -> CirclePosition {
        let viewSize = parentView.frame.size
        let verticalPadding = (viewSize.height - imageSize.height) / 2.0
        let horizontalPadding = (viewSize.width - imageSize.width) / 2.0
        let widthScale = viewSize.width / imageSize.width
        let heightScale = viewSize.height / imageSize.height
        let scaleFactor = min(heightScale, widthScale)
        
        var translatedCenter = position.center
        translatedCenter.x += horizontalPadding
        translatedCenter.y += verticalPadding
        translatedCenter.x /= scaleFactor
        translatedCenter.y /= scaleFactor
        return CirclePosition(center: translatedCenter, radius: position.radius / scaleFactor)
    }
    
    // Pruned code from: https://stackoverflow.com/questions/27092354/rotating-uiimage-in-swift
    static func rotateAndScaleImage(image: UIImage, degrees: Foundation.Measurement<UnitAngle>, newSize: CGSize) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        
        let rotationInRadians = CGFloat(degrees.converted(to: .radians).value)
        var drawRect = CGRect(origin: CGPoint.zero, size: newSize)
        
        // if image size (in the future) is not square or rotation is not some multiple of 90-degrees
        // this code will be needed (to deal with resulting enclosing rectangle being larger / different
        // from original rectangle

        let formatter = UIGraphicsImageRendererFormat()
        formatter.scale = 1.0       // 1 pixel per point (lowest resolution, saves space, is still better than previous)
        let renderer = UIGraphicsImageRenderer(size: newSize, format: formatter)
        return renderer.image { renderContext in
            renderContext.cgContext.translateBy(x: drawRect.midX, y: drawRect.midY) // Shift transform center to middle prior to rotation
            renderContext.cgContext.rotate(by: rotationInRadians)
            renderContext.cgContext.scaleBy(x: 1.0, y: -1.0)                // flip on (what will be the) vertical axis
            drawRect.origin.x -= drawRect.size.width / 2            // compensate for translation
            drawRect.origin.y -= drawRect.size.height / 2
            renderContext.cgContext.draw(cgImage, in: drawRect)
        }
    }
    
    // Was needed to compensate for landscape storage of images normally addressed in portrait mode
    // but that seems to no longer be the case.
    static func rotatePoint(portraitPoint: CGPoint, imageSize: CGSize) -> CGPoint {
        var landscapePoint = portraitPoint
        let newY = imageSize.width - landscapePoint.x
        landscapePoint.x = landscapePoint.y
        landscapePoint.y = newY
        return landscapePoint
    }
    
    
}
