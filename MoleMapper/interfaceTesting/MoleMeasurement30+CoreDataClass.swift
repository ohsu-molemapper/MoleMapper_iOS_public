//
//  MoleMeasurement30+CoreDataClass.swift
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

import Foundation
import CoreData

@objc(MoleMeasurement30)
public class MoleMeasurement30: NSManagedObject {
    
    /**
     create creates a new ZoneMeasurement30 object using the global context maintained
     by the V30Stack singleton factory.
     */
    class func create() -> MoleMeasurement30 {
        let moleMeasurement30 = MoleMeasurement30(context: V30StackFactory.createV30Stack().managedContext)
        moleMeasurement30.moleMeasurementID = NSUUID().uuidString
        return moleMeasurement30
    }
    /**
     dictionaryForBridge returns an NSDictionary ready for zipping, encrypting and sending
     to the Bridge server.
     */
    func dictionaryForBridge() -> NSDictionary? {
        var bridgeDictionary: NSMutableDictionary?
        var moleMeasurementDict: [String: Any] = [:]

        if let zoneMeasurement = self.whichZoneMeasurement {
            var ratioDictionary = zoneMeasurement.displayToJpegRatios()
            
            let displayToJpegWidthRatio:CGFloat = ratioDictionary["widthRatio"]!
            let displayToJpegHeightRatio:CGFloat = ratioDictionary["heightRatio"]!
            let jpegX = CGFloat(self.moleMeasurementX!) * displayToJpegWidthRatio
            let jpegY = CGFloat(self.moleMeasurementY!) * displayToJpegHeightRatio
            // JPEGs somehow get converted (correctly) to Portrait either when saving to phone or when uploading to Bridge
//            let landscapePoint = TranslateUtils.rotatePoint(portraitPoint: CGPoint(x: jpegX, y: jpegY),
//                                                            imageSize: CGSize(width: Int(zoneMeasurement.fullsizePhotoWidth),
//                                                                              height: Int(zoneMeasurement.fullsizePhotoHeight)))
            guard self.whichMole != nil, whichMole!.moleID != nil else { fatalError("MoleMeasurement30 dictionaryForBridge error") }
            moleMeasurementDict["moleID"] = self.whichMole!.moleID!
            moleMeasurementDict["zoneMeasurementID"] = zoneMeasurement.zoneMeasurementID
            moleMeasurementDict["moleDiameter"] = CGFloat(self.moleMeasurementDiameterInPoints!) * displayToJpegWidthRatio
            moleMeasurementDict["moleX"] = jpegX
            moleMeasurementDict["moleY"] = jpegY
            moleMeasurementDict["calculatedMoleDiameter"] = self.calculatedMoleDiameter!
            moleMeasurementDict["calculatedSizeBasis"] = Int(self.calculatedSizeBasis)

            bridgeDictionary = NSMutableDictionary()
            bridgeDictionary!.addEntries(from: moleMeasurementDict)
        }
        return bridgeDictionary
    }

    private func getMoleMeasurementFilename() -> String {
        var filename = "error.jpg"
        if self.moleMeasurementID != nil {
            if moleMeasurementPhoto != nil {
                filename = moleMeasurementPhoto!
            } else {
                filename = "/mole" + moleMeasurementID! + ".jpg"
                moleMeasurementPhoto = filename
            }
        }
        return filename
    }

    func imageFullPathNameForPhoto() -> String {
        if self.moleMeasurementID != nil {
            let filename = getMoleMeasurementFilename()
            // path-based
            let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .allDomainsMask, true)[0]
            let FQFN = documents.appending(filename)
            return FQFN
        } else {
            return ""
        }
    }

    func moleMeasurementImage() -> UIImage? {
        return UIImage(contentsOfFile: imageFullPathNameForPhoto())
    }
    
    func getDataAsJPEG() -> Data? {
        let fm = FileManager.default
        return fm.contents(atPath: imageFullPathNameForPhoto())
    }
    
    func saveDataAsJPEG(jpegData: Data) {
        let fm = FileManager.default
        fm.createFile(atPath: imageFullPathNameForPhoto(),
                      contents: jpegData,
                      attributes: nil)      // TODO: explicitly type this as PNG?
    }
    
    func deleteResizedImageFile() {
        let fm = FileManager.default
        do {
            try fm.removeItem(atPath: imageFullPathNameForPhoto())
        } catch {
            // nothing
        }
    }
    
    // Returns total number of moles
    class func measurementCount() -> NSNumber {
        let context = V30StackFactory.createV30Stack().managedContext
        let measurementFetch = NSFetchRequest<NSNumber>(entityName: "MoleMeasurement30")
        measurementFetch.resultType = .countResultType
        var count:Int = 0
        do {
            let result = try context.fetch(measurementFetch)
            count = result.first!.intValue
        } catch let err as NSError {
            print("Error \(err), \(err.userInfo)")
        }
        return NSNumber(value: count)
    }
    
    // MARK: Statistics helpers
    
    /**
     biggestMoleMeasurement is a class method that returns the biggest mole measurement.
     
     Parameters:
     - none
     
     Returns: nil if no measurements (with a calculated size) or a MoleMeasurement30 object.
     This object can be used to access the parent Mole30 object and, indirectly, the Zone30 parent.
     */
    class func biggestMoleMeasurement() -> MoleMeasurement30? {
        // May be a sophisticated Core Data way to do this, but it's not obvious and the clock is ticking...
        var biggestMoleMeasurement: MoleMeasurement30?
        let moleMeasurementFetch: NSFetchRequest<MoleMeasurement30> = MoleMeasurement30.fetchRequest()
        let sortDesc = NSSortDescriptor(key: "calculatedMoleDiameter", ascending: false)
        moleMeasurementFetch.sortDescriptors = [sortDesc]
        do {
            let context = V30StackFactory.createV30Stack().managedContext
            let measurements = try context.fetch(moleMeasurementFetch)
            for measurement in measurements {
                if (measurement.calculatedMoleDiameter?.floatValue ?? -1.0) > 0.0 {
                    biggestMoleMeasurement = measurement
                    break;
                }
            }
        } catch let err as NSError {
            print("Error \(err), \(err.userInfo) ")
        }
        return biggestMoleMeasurement
        
    }

    
    
}
