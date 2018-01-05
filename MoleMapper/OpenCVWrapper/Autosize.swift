//
//  Autosize.swift
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

//func autoEncloseCoin(_ fixableData: FixableData) -> CirclePosition {
//    return fixableData.fixableCircle
//}

// create as floats to add to EncircleParameters
enum BlobObjectTypes:Float {
    case darkCoin = 1.0
    case shinyCoin = 2.0
    case mole = 3.0
}

enum EncircleParameters {
    case adaptiveThresholdBlockSize
    case adaptiveThresholdOffset
    case adaptiveThresholdType
    case blurKernelSize
    case blurSigma
    case erodeKernelSize
    case dilateKernelSize
    case objectType
}

typealias EncircleParameterDictionary = [EncircleParameters: Float]

/*
 See: http://stackoverflow.com/questions/14332687/converting-uiimage-to-cvmat
 This will be because the UIImage is not actually portrait. All photos taken with the iPhone camera are landscape in their raw bitmap state, eg 3264 wide x 2488 high. A "portrait" photo is displayed as such by the orientation EXIF flag set in the image, which is honoured, for example, by the photo library app which swivels images according to this flag and the viewing orientation of the camera.
 
 The flag also affects how UIImage reports its width and height properties, transposing them from their bitmap values for images flagged as portrait.
 
 cv::Mat doesn't bother with any of that. This means that (i) when translating to cv::Mat a portrait image will have its size.width and size.height values transposed, and (ii) when translating back from cv::Mat you will have lost the orientation flag.
 */


@objc class AutoEncircle: NSObject {
    
    static let maxCoinRadius:CGFloat = 55
    static let minCoinRadius:CGFloat = 12
    
    static func paramsDebugOut(_ params: EncircleParameterDictionary) {
        if let val = params[.adaptiveThresholdBlockSize] {
            print("Adaptive Threshold Block Size: \t\(val)")
        }
        if let val = params[.adaptiveThresholdOffset] {
            print("Adaptive Threshold Offset:      \t\(val)")
        }
        if let val = params[.adaptiveThresholdType] {
            print("Adaptive Threshold Type:        \t\(val)")
        }
        if let val = params[.blurKernelSize] {
            print("Blur Kernel Size:               \t\(val)")
        }
        if let val = params[.blurSigma] {
            print("Blur Sigma:                     \t\(val)")
        }
        if let val = params[.erodeKernelSize] {
            print("Erode Kernel Size:              \t\(val)")
        }
        if let val = params[.dilateKernelSize] {
            print("Dilate Kernel Size:             \t\(val)")
        }
    }
    
    static func unprepImage(_ image: UIImage) -> UIImage {
        var newimage: UIImage!
        
        //        print("unprepImage size (before): \(image.size)")
        //        print("unprepImage orientation (before): \(image.imageOrientation.rawValue)")
        if image.imageOrientation != .right {
            newimage = UIImage(cgImage: image.cgImage!, scale: 1.0, orientation: .right)
        } else {
            if image.size.width > image.size.height {
                newimage = UIImage(cgImage: image.cgImage!, scale: 1.0, orientation: .up)
            } else {
                newimage = image
            }
        }
        //        print("unprepImage size (after): \(newimage.size)\n")
        return newimage
    }
    
    
    static func prepImage(_ image: UIImage) -> UIImage {
        var newimage: UIImage!
        
        //        print("prepImage size (before): \(image.size)")
        //        print("prepImage orientation (before): \(image.imageOrientation.rawValue)")
        //
        if image.imageOrientation != .up {
            newimage = UIImage(cgImage: image.cgImage!, scale: 1.0, orientation: .up)
        } else {
            if image.size.height > image.size.width {
                newimage = UIImage(cgImage: image.cgImage!, scale: 1.0, orientation: .right)
            } else {
                newimage = image
            }
        }
        //        print("prepImage size (after): \(newimage.size)\n")
        return newimage
    }
    
    static func tranformPortraitToLandscapeCoordinate(portraitPt: CGPoint, imageWidth: CGFloat) -> CGPoint {
        return CGPoint(x: portraitPt.y, y: (imageWidth - portraitPt.x))
    }
    
    static func tranformLandscapeToPortraitCoordinate(landscapePt: CGPoint, imageHeight: CGFloat) -> CGPoint {
        return CGPoint(x: (imageHeight - landscapePt.y), y: landscapePt.x)
    }
    
    static func getMoleParameters() -> EncircleParameterDictionary {
        var parameterSet = EncircleParameterDictionary()
        parameterSet[.adaptiveThresholdType] = 1.0
        parameterSet[.adaptiveThresholdBlockSize] = 39.0    // MUST BE ODD
        parameterSet[.adaptiveThresholdOffset] = 5.0
        parameterSet[.blurKernelSize] = 7.0
        parameterSet[.blurSigma] = 2.5
        parameterSet[.dilateKernelSize] = 9.0
        parameterSet[.erodeKernelSize] = 11.0
        parameterSet[.objectType] = BlobObjectTypes.mole.rawValue
        
        return parameterSet
    }
    
    static func getDarkCoinParameters() -> EncircleParameterDictionary {
        var parameterSet = EncircleParameterDictionary()
        parameterSet[.adaptiveThresholdType] = 1.0
        parameterSet[.adaptiveThresholdBlockSize] = 55.0    // MUST BE ODD
        parameterSet[.adaptiveThresholdOffset] = 10.0
        parameterSet[.blurKernelSize] = 11.0
        parameterSet[.blurSigma] = 3.5
        parameterSet[.dilateKernelSize] = 23.0
        parameterSet[.erodeKernelSize] = 25.0
        parameterSet[.objectType] = BlobObjectTypes.darkCoin.rawValue
        
        return parameterSet
    }
    
    static func getShinyCoinParameters() -> EncircleParameterDictionary {
        var parameterSet = EncircleParameterDictionary()
        parameterSet[.adaptiveThresholdType] = 0.0
        parameterSet[.adaptiveThresholdBlockSize] = 65.0    // MUST BE ODD
        parameterSet[.adaptiveThresholdOffset] = -16.0
        parameterSet[.blurKernelSize] = 5.0
        parameterSet[.blurSigma] = 2.0
        parameterSet[.dilateKernelSize] = 21.0
        parameterSet[.erodeKernelSize] = 21.0
        parameterSet[.objectType] = BlobObjectTypes.shinyCoin.rawValue
        
        return parameterSet
    }
    
    static func debugAEM(_ fixableData: FixableData, _ parameterSet: inout [EncircleParameters: Float]) -> UIImage? {
        var image = fixableData.fixableImage
        let circle = fixableData.fixableCircle
        var center = circle.center
        
        center = tranformPortraitToLandscapeCoordinate(portraitPt: center, imageWidth: image.size.width)
        image = prepImage(fixableData.fixableImage)
        
        var (circlePosition, ccImage, blobArea) = genericEncircle(image: image, center: center, paramSet: parameterSet)
        
        return unprepImage(ccImage)
    }
    
    
    static func autoEncircleMole(_ fixableData: FixableData) -> CirclePosition? {
        var image = fixableData.fixableImage
        let circle = fixableData.fixableCircle
        var center = circle.center
        
        center = tranformPortraitToLandscapeCoordinate(portraitPt: center, imageWidth: image.size.width)
        image = prepImage(fixableData.fixableImage)
        
        let parameterSet = AutoEncircle.getMoleParameters()
        let (circlePosition, _, _) = genericEncircle(image: image, center: center, paramSet: parameterSet)
        
        circlePosition.center = tranformLandscapeToPortraitCoordinate(landscapePt: circlePosition.center, imageHeight: image.size.height)
        
        // Safety checks
        // Arbitrary values. For outlier moles, make users Fix these corrections
        if circlePosition.radius < 5 {
            circlePosition.radius = 5.0
        }
        if circlePosition.radius > 80 {
            circlePosition.radius = 80
        }
        
        return circlePosition
    }
    
    static func dist(pt1: CGPoint, pt2: CGPoint) -> CGFloat {
        let delta_x = pt1.x - pt2.x
        let delta_y = pt1.y - pt2.y
        return (delta_x * delta_x + delta_y * delta_y)
    }

    
    static func autoEncircleCoin(_ fixableData: FixableData) -> CirclePosition? {
//        var image = fixableData.fixableImage
//        let circle = fixableData.fixableCircle
//        var center = circle.center
//        
//        center = tranformPortraitToLandscapeCoordinate(portraitPt: center, imageWidth: image.size.width)
//        image = prepImage(fixableData.fixableImage)
//        
//        let parameterSet = AutoEncircle.getShinyCoinParameters()
//        let (circlePosition, _, _) = genericEncircle(image: image, center: center, paramSet: parameterSet)
//        
//        circlePosition.center = tranformLandscapeToPortraitCoordinate(landscapePt: circlePosition.center, imageHeight: image.size.height)
        let startingCenter = fixableData.fixableCircle.center
        var fixedCircle:CirclePosition = CirclePosition(center: startingCenter, radius: 25)
        var fixedCircle1:CirclePosition?
        var fixedCircle2:CirclePosition?
        var blobArea1: Double
        var blobArea2: Double
        let shinySegmentationParams = AutoEncircle.getShinyCoinParameters()
        (fixedCircle1, _, blobArea1) = AutoEncircle.autoEncircleObject(fixableData, shinySegmentationParams)
        
        let darkSegmentationParams = AutoEncircle.getDarkCoinParameters()
        (fixedCircle2, _, blobArea2) = AutoEncircle.autoEncircleObject(fixableData, darkSegmentationParams)
        
        var bestDistance: CGFloat = 1000
        if (fixedCircle1 != nil) {
            if fixedCircle1!.radius > AutoEncircle.minCoinRadius && fixedCircle1!.radius < AutoEncircle.maxCoinRadius {
                let area = CGFloat(Float.pi) * fixedCircle1!.radius * fixedCircle1!.radius
                let coverage = CGFloat(blobArea1) / area
                var distance = TranslateUtils.squaredDistance(pt1: fixedCircle1!.center, pt2: startingCenter)
                distance /= coverage
                if distance < bestDistance {
                    bestDistance = distance
                    fixedCircle = fixedCircle1!
                    print("Choosing blob from shiny parameters")
                }
            }
        }
        if (fixedCircle2 != nil) {
            if fixedCircle2!.radius > AutoEncircle.minCoinRadius && fixedCircle2!.radius < AutoEncircle.maxCoinRadius {
                let area = CGFloat(Float.pi) * fixedCircle2!.radius * fixedCircle2!.radius
                let coverage = CGFloat(blobArea2) / area
                var distance = TranslateUtils.squaredDistance(pt1: fixedCircle2!.center, pt2: startingCenter)
                distance /= coverage
                if distance < bestDistance {
                    bestDistance = distance
                    fixedCircle = fixedCircle2!
                    print("Choosing blob from dark parameters")
                }
            }
        }
    
        return fixedCircle
    }

    static func autoEncircleObject(_ fixableData: FixableData, _ parameterSet: EncircleParameterDictionary) -> (CirclePosition?,UIImage?, Double) {
        var image = fixableData.fixableImage
        let circle = fixableData.fixableCircle
        var center = circle.center
        
        center = tranformPortraitToLandscapeCoordinate(portraitPt: center, imageWidth: image.size.width)
        image = prepImage(fixableData.fixableImage)
        
        //        AutoEncircle.paramsDebugOut(parameterSet)
        var (circlePosition, ccImage, blobArea) = genericEncircle(image: image, center: center, paramSet: parameterSet)
        ccImage = unprepImage(ccImage)
        
        // test for too big or too small
        
        circlePosition.center = tranformLandscapeToPortraitCoordinate(landscapePt: circlePosition.center, imageHeight: image.size.height)
        
        return (circlePosition,ccImage,blobArea)
    }
    
    static func genericEncircle(image: UIImage, center: CGPoint, paramSet: EncircleParameterDictionary) -> (CirclePosition, UIImage, Double) {
        var radius:Double = -1.0
        //var center:CGPoint = CGPoint(x: 0,y: 0)
        var centroid:CGPoint = CGPoint(x: 0,y: 0)
        var blobArea:Double = 0.0
        
        let adaptiveThresholdBlockSize = Int32(paramSet[.adaptiveThresholdBlockSize] ?? 111)
        let adaptiveThresholdTypeValue = Int32(paramSet[.adaptiveThresholdType] ?? 0)
        let adaptiveThresholdOffset = Int32(paramSet[.adaptiveThresholdOffset] ?? 0)
        let blurKernelValue = Int(paramSet[.blurKernelSize] ?? 71.0)
        let erodeKernelValue = Int(paramSet[.erodeKernelSize] ?? 15.0)
        let dilateKernelValue = Int(paramSet[.dilateKernelSize] ?? 11.0)
        let blurSigmaValue = Double(paramSet[.blurSigma] ?? 15.0)
        let blurKernelSize = CGSize(width: blurKernelValue, height: blurKernelValue)
        let erodeKernelSize = CGSize(width: erodeKernelValue, height: erodeKernelValue)
        let dilateKernelSize = CGSize(width: dilateKernelValue, height: dilateKernelValue)
        let tinyKernelSize = CGSize(width: 7, height: 7)
        
        let ccstats:CCStats = CCStats()
        
        // Calculate these better based on Gaussian blur kernel size.
        let tinyKernel:UIImage = OpenCVWrapper.getStructuringElement(2, ksize: tinyKernelSize )
        let erodeKernel:UIImage = OpenCVWrapper.getStructuringElement(2, ksize: erodeKernelSize )
        let dilateKernel:UIImage = OpenCVWrapper.getStructuringElement(2, ksize: dilateKernelSize )
        var processedImage = UIImage()
        
        //        processedImage = OpenCVWrapper.makeGray(from: image)
        if (paramSet[.objectType] ?? 0.0)  == BlobObjectTypes.shinyCoin.rawValue {
            processedImage = OpenCVWrapper.extractChannel(fromBGRImage: image, channel: ColorChannels.blueChannel)
        } else {
            processedImage = OpenCVWrapper.extractChannel(fromBGRImage: image, channel: ColorChannels.redChannel)
        }
        processedImage = OpenCVWrapper.gaussianBlur(processedImage,
                                                    kernelSize: blurKernelSize,
                                                    sigmaX: blurSigmaValue,
                                                    sigmaY: blurSigmaValue,
                                                    borderType: 0)
        processedImage = OpenCVWrapper.adaptiveThreshold(processedImage,
                                                         blockSize: adaptiveThresholdBlockSize,
                                                         offset: adaptiveThresholdOffset,
                                                         thresholdType: adaptiveThresholdTypeValue)
        
        // Remove edge structures
        var CCs = OpenCVWrapper.connectedComponents(withStats: processedImage, stats: ccstats)
        
        CCs = OpenCVWrapper.pruneEdgelikeComponents(CCs, stats: ccstats, biggerThan: 105)
        
        // convert remaining structures back to binary image
        processedImage = OpenCVWrapper.whiteFillCCs(CCs, ccCount: ccstats.ccCount)
        
        
        // Remove hairs
        processedImage = OpenCVWrapper.erode(processedImage, kernel: tinyKernel)
        processedImage = OpenCVWrapper.dilate(processedImage, kernel: tinyKernel)
        // connect parts (obscured by reflections)
        processedImage = OpenCVWrapper.dilate(processedImage, kernel: dilateKernel)
        processedImage = OpenCVWrapper.erode(processedImage, kernel: erodeKernel)
        CCs = OpenCVWrapper.connectedComponents(withStats: processedImage, stats: ccstats)
        
        // TODO: comment the next line out and remove dependence from other functions
        processedImage = OpenCVWrapper.floodFillCCs(CCs, ccCount: ccstats.ccCount)
        
        // Have caller evaluate whether the returned circle is big enough and, if not, try
        // shifting the seedPoint
        OpenCVWrapper.findEnclosingCircle(CCs, stats: ccstats, seedPoint: center, ptrCenter: &centroid, ptrRadius: &radius, ptrBlobArea: &blobArea)
        
        let returnedCircle = CirclePosition(center: centroid, radius: CGFloat(radius))
        
        return (returnedCircle, processedImage, blobArea)
    }
    
    
}
