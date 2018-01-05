//
//  Zone30+CoreDataClass.swift
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

@objc(Zone30)
public class Zone30: NSManagedObject {
    /**
     zoneForZoneID creates a zone iff it hasn't been created yet.
     
     Parameters:
     - zoneID: string ID for zone (number as string)
     
     Returns: the Zone object if zone is already created, new Zone30 object if not.
    */
    class func zoneForZoneID(_ zoneID: String) -> Zone30? {
        let context = V30StackFactory.createV30Stack().managedContext
        var zone30: Zone30?
        let zoneFetch: NSFetchRequest<Zone30> = Zone30.fetchRequest()
        zoneFetch.predicate = NSPredicate(format: "%K == %@", #keyPath(Zone30.zoneID),zoneID)
        
        do {
            let result = try context.fetch(zoneFetch)
            if result.count == 0 {
                zone30 = Zone30(context: context)
                zone30!.zoneID = zoneID
                // optionals are nil by default
                // zone photos are stored in ZoneMeasurement now
            } else {
                zone30 = result[0]
            }
        } catch let err as NSError {
//            print("Error \(err), \(err.userInfo) fetching zone for ID \(zoneID)")
        }
        
        return zone30
    }
    
    /**
        createAllZones is a helper function to create all zones in one fell swoop
    */
    class func createAllZones() {
        let managedContext = V30StackFactory.createV30Stack().managedContext
        var zone30: Zone30?
        let zoneFetch: NSFetchRequest<Zone30> = Zone30.fetchRequest()
        
        do {
            let result = try managedContext.fetch(zoneFetch)
            let user = User.getCurrentUser(nil)
            if result.count == 0 {
                let zoneIDs = Zone30.allZoneIDs()
                for zoneID in zoneIDs {
                    zone30 = Zone30(context: managedContext)
                    zone30!.zoneID = (zoneID as! String)
                    zone30!.addToWhichUser(user)
                }
                try managedContext.save()
            } else {
//                print("Zones already exist")
            }
        } catch let err as NSError {
            print("Error \(err), \(err.userInfo)")
        }
    }
    
    /**
        allZoneIDs returns an array of strings containing all the zone IDs as strings
    */
    class func allZoneIDs() -> NSArray {
        return zoneIDArray
    }
    
    class func zoneNameForZoneID(_ zoneID:String) -> String?
    {
        return zoneNameToZoneID[zoneID]
    }
    
    /**
        allMolesInZoneForZoneID returns an NSSet of Mole30 objects associated with the zone
        identified by the ID.
 
        Parameters:
        - zoneID: String containing the zone ID

        Returns: NSSet of Mole30 objects that are bound to this zone.
    */
    class func allMolesInZoneForZoneID(_ zoneID: String) -> NSSet? {
        var moles: NSSet?
        let zoneFetch: NSFetchRequest<Zone30> = Zone30.fetchRequest()
        zoneFetch.predicate = NSPredicate(format: "%K == %@", #keyPath(Zone30.zoneID),zoneID)
        
        do {
            let result = try V30StackFactory.createV30Stack().managedContext.fetch(zoneFetch)
            if result.count == 1 {
                moles = result[0].moles   //
            } else {
//                print("Wrong number of results for zoneID \(zoneID)")
            }
        } catch let err as NSError {
            print("Error \(err), \(err.userInfo) fetching zone for ID \(zoneID)")
        }
        
        return moles
    }
    
    /**
        numberOfMolesNeedingRemeasurementInZone returns the number of moles that need
        remeasuring for the zone identified by the ID.
     
        Parameters:
        - zoneID: String containing the zone ID
     
        Returns: the number of moles that need remeasuring
     */
    class func numberOfMolesNeedingRemeasurementInZone(_ zoneID: String) -> CInt {
        // TODO - implement numberOfMolesNeedingRemeasurementInZone
        var remeasurementCount = 0
        if let zone = Zone30.zoneForZoneID(zoneID) {
            if zone.moles != nil {
                for case let mole as Mole30 in zone.moles! {
                    if mole.needsRemeasuring() {
                        remeasurementCount += 1
                    }
                }
            }
        }
        // Returning a CInt because ObjectiveC likes those...
        return CInt(remeasurementCount)
    }
    
    /**
        hasValidImageDataForZoneID returns true if there is an image available (i.e. that
        there has been at least one zone measurement).

        Parameters:
        - zoneID: String containing the zone ID

        Returns: true if there is at least one completed ZoneMeasurement
     */
    class func hasValidImageDataForZoneID(_ zoneID: String) -> Bool {
        var imageDataExists = false
        
//        // DEBUG BACK DOOR
//        if zoneID == "1351" {       // left pelvis
////            let model = V30StackFactory.createV30Stack()
////            model.dumpModel()
//        }
//        //
        // Special case the front/back head
        if (zoneID == "1100")  || (zoneID == "2100") {
            if hasValidImageDataForZoneID("3150") {
                imageDataExists = true
            } else if hasValidImageDataForZoneID("3151") {
                imageDataExists = true
            } else if hasValidImageDataForZoneID("3170") {
                imageDataExists = true
            } else if hasValidImageDataForZoneID("3171") {
                imageDataExists = true
            } else if hasValidImageDataForZoneID("3172") {
                imageDataExists = true
            }
        } else if let zone30 = Zone30.zoneForZoneID(zoneID) {
            if zone30.zoneMeasurements != nil {
                imageDataExists = zone30.zoneMeasurements!.count > 0
            }
        }
        
        return imageDataExists
    }
    
    /**
        imageFullFilepathForZoneID returns full filepath of most recent zone measurement image.

        Parameters:
        - zoneID: String containing the zone ID

        Returns: filename of most recent zone measurement image
     */
    class func imageFullFilepathForZoneID(_ zoneID: String) -> String {
        var imageFQFN = ""
        guard let zone30 = Zone30.zoneForZoneID(zoneID) , zone30.zoneMeasurements != nil else { return imageFQFN }
        if zone30.zoneMeasurements!.count > 0 {
            // Fetch zone measurements, sorted by date (most recent first)
            // Come at it from the ZM perspective
            let sortDesc = NSSortDescriptor(key: "date", ascending: false)
            let zoneMeasurementFetch: NSFetchRequest<ZoneMeasurement30> = ZoneMeasurement30.fetchRequest()
            zoneMeasurementFetch.predicate = NSPredicate(format: "whichZone == %@", zone30)
            zoneMeasurementFetch.sortDescriptors = [sortDesc]
            let context = V30StackFactory.createV30Stack().managedContext
            do {
                let result = try context.fetch(zoneMeasurementFetch)
                if result.count > 0 {
                    let latestMeasurement: ZoneMeasurement30 = result[0]
                    imageFQFN = (latestMeasurement.fullsizePhotoFilename ?? "")
                } else {
//                    print("Zone already exists")
                }
            } catch let err as NSError {
                print("Error \(err), \(err.userInfo) fetching zone for ID \(zoneID)")
            }
        }
        
        return imageFQFN
    }
    
    /**
     latestFullImageForZoneID returns the JPEG (large) version of the most recent zone measurement image.
     
     Parameters:
     - zoneID: String containing the zone ID
     
     Returns: UIImage of most recent zone measurement image (JPEG)
     */
    class func latestFullImageForZoneID(_ zoneID: String) -> UIImage? {
        var image: UIImage?
        if let zone30 = Zone30.zoneForZoneID(zoneID) {
            if zone30.zoneMeasurements != nil {
                // Fetch zone measurements, sorted by date (most recent first)
                // Come at it from the ZM perspective
                let sortDesc = NSSortDescriptor(key: "date", ascending: false)
                let zoneMeasurementFetch: NSFetchRequest<ZoneMeasurement30> = ZoneMeasurement30.fetchRequest()
                zoneMeasurementFetch.predicate = NSPredicate(format: "whichZone == %@", zone30)
                zoneMeasurementFetch.sortDescriptors = [sortDesc]
                let context = V30StackFactory.createV30Stack().managedContext
                do {
                    let result = try context.fetch(zoneMeasurementFetch)
                    if result.count > 0 {
                        let latestMeasurement: ZoneMeasurement30 = result[0]
                        image = latestMeasurement.fullsizedImage()
                    } else {
//                        print("Zone already exists")
                    }
                } catch let err as NSError {
                    print("Error \(err), \(err.userInfo) fetching zone for ID \(zoneID)")
                }
            }
        }
        
        return image
    }

    /**
     latestDisplayImageForZoneID returns the PNG (small) version of the most recent zone measurement image.
     
     Parameters:
     - zoneID: String containing the zone ID
     
     Returns: UIImage of most recent zone measurement image (JPEG)
     */
    class func latestDisplayImageForZoneID(_ zoneID: String) -> UIImage? {
        var image: UIImage?
        if let zone30 = Zone30.zoneForZoneID(zoneID) {
            if zone30.zoneMeasurements != nil {
                // Fetch zone measurements, sorted by date (most recent first)
                // Come at it from the ZM perspective
                let sortDesc = NSSortDescriptor(key: "date", ascending: false)
                let zoneMeasurementFetch: NSFetchRequest<ZoneMeasurement30> = ZoneMeasurement30.fetchRequest()
                zoneMeasurementFetch.predicate = NSPredicate(format: "whichZone == %@", zone30)
                zoneMeasurementFetch.sortDescriptors = [sortDesc]
                let context = V30StackFactory.createV30Stack().managedContext
                do {
                    let result = try context.fetch(zoneMeasurementFetch)
                    if result.count > 0 {
                        let latestMeasurement: ZoneMeasurement30 = result[0]
                        image = latestMeasurement.displayImage()
                    } else {
//                        print("Zone already exists")
                    }
                } catch let err as NSError {
                    print("Error \(err), \(err.userInfo) fetching zone for ID \(zoneID)")
                }
            }
        }
//        if image?.imageOrientation == .right { print("Image Orientation: right") }
//        else if image?.imageOrientation == .up { print("Image Orientation: up") }
//        else { print("Image Orientation ?? \(image?.imageOrientation)") }
        
        return image
    }

    
    /**
        imageFilenameForZoneID returns filename of most recent zone measurement image.

        Parameters:
        - zoneID: String containing the zone ID

        Returns: filename of most recent zone measurement image
     */
    class func imageFilenameForZoneID(_ zoneID: String) -> String {
        // TODO - implement
        // Ditto
        fatalError("imageFilenameForZoneID not implemented yet")
        return ""
    }
    
    // MARK: Statistics helpers
    
    /**
        moliestZone is a class method that returns the zone object with the most moles. Tie-breaks
        are handled by zones with the most zone measurements.

        Parameters:
        - none

        Returns: nil (if no zones have moles yet) or Zone30 object.
    */
    class func moliestZone() -> Zone30? {
        let zoneFetch: NSFetchRequest<Zone30> = Zone30.fetchRequest()
        // Alas, these do not work! See: https://stackoverflow.com/questions/11114399/core-data-fetch-sort-by-relationship-count
//        let sortCriteria = NSSortDescriptor(key: "moles.@count", ascending: false)
//        zoneFetch.sortDescriptors = [sortCriteria]
        var moleyZones: [String] = []
        var moliestZone: Zone30?
        
        do {
            let results = try V30StackFactory.createV30Stack().managedContext.fetch(zoneFetch)
            // create dictionary
            var zoneMoleCounts: [String:Int] = [:]
            for case let zone as Zone30 in results {
                zoneMoleCounts[zone.zoneID!] = zone.moles?.count ?? 0
            }
            // sort ids by counts
            let sortedZoneCounts = zoneMoleCounts.sorted(by: { (first: (key: String, value: Int), second: (key: String, value: Int)) -> Bool in
                return first.value > second.value
            })
            let biggestCount = sortedZoneCounts[0].value
            moleyZones.append(sortedZoneCounts[0].key)
            for nextPair in sortedZoneCounts.dropFirst() {
                if nextPair.value == biggestCount {
                    moleyZones.append(nextPair.key)
                } else {
                    break
                }
            }
            
//                // now break any ties
            let moliestZoneID = moleyZones[0]
            moliestZone = Zone30.zoneForZoneID(moliestZoneID)
            var mostZoneMeasurements = moliestZone!.zoneMeasurements?.count ?? 0
            if moleyZones.count > 1 {
                for nextID in moleyZones.dropFirst() {
                    let moleyZone = Zone30.zoneForZoneID(nextID)
                    let measurementCount = moleyZone?.zoneMeasurements?.count ?? 0
                    if measurementCount > mostZoneMeasurements {
                        mostZoneMeasurements = measurementCount
                        moliestZone = moleyZone
                    }
                }
            }
        } catch let err as NSError {
            print("Error \(err), \(err.userInfo) ")
        }
        return moliestZone
    }
    
    class func zonesMeasured() -> NSNumber {
        let zoneFetch: NSFetchRequest<Zone30> = Zone30.fetchRequest()
        var measurementCount: Int = 0
        do {
            let results = try V30StackFactory.createV30Stack().managedContext.fetch(zoneFetch)
            for zone in results {
                let thisZonesMeasurementCount = zone.zoneMeasurements?.count ?? 0
                if thisZonesMeasurementCount > 0 {
                    measurementCount += 1
                }
            }
        } catch let err as NSError {
            print("Error \(err), \(err.userInfo) ")
        }
        return NSNumber(value: measurementCount)
    }

    // MARK: class properties
    
    // long, so they're at the bottom
    static let zoneNameToZoneID = [
        "1100" : "Head",
        "1200" : "Neck & Center Chest",
        "1250" : "Right Pectoral",
        "1251" : "Left Pectoral",
        "1300" : "Right Abdomen",
        "1301" : "Left Abdomen",
        "1350" : "Right Pelvis",
        "1351" : "Left Pelvis",
        "1400" : "Right Upper Thigh",
        "1401" : "Left Upper Thigh",
        "1450" : "Right Lower Thigh & Knee",
        "1451" : "Left Lower Thigh & Knee",
        "1500" : "Right Upper Calf",
        "1501" : "Left Upper Calf",
        "1550" : "Right Lower Calf",
        "1551" : "Left Lower Calf",
        "1600" : "Right Ankle & Foot",
        "1601" : "Left Ankle & Foot",
        "1650" : "Right Shoulder",
        "1651" : "Left Shoulder",
        "1700" : "Right Upper Arm",
        "1701" : "Left Upper Arm",
        "1750" : "Right Upper Forearm",
        "1751" : "Left Upper Forearm",
        "1800" : "Right Lower Forearm",
        "1801" : "Left Lower Forearm",
        "1850" : "Right Hand",
        "1851" : "Left Hand",
        "2100" : "Head",
        "2200" : "Neck",
        "2250" : "Left Upper Back",
        "2251" : "Right Upper Back",
        "2300" : "Left Lower Back",
        "2301" : "Right Lower Back",
        "2350" : "Left Glute",
        "2351" : "Right Glute",
        "2400" : "Left Upper Thigh",
        "2401" : "Right Upper Thigh",
        "2450" : "Left Lower Thigh & Knee",
        "2451" : "Right Lower Thigh & Knee",
        "2500" : "Left Upper Calf",
        "2501" : "Right Upper Calf",
        "2550" : "Left Lower Calf",
        "2551" : "Right Lower Calf",
        "2600" : "Left Ankle & Foot",
        "2601" : "Right Ankle & Foot",
        "2650" : "Left Shoulder",
        "2651" : "Right Shoulder",
        "2700" : "Left Upper Arm",
        "2701" : "Right Upper Arm",
        "2750" : "Left Elbow",
        "2751" : "Right Elbow",
        "2800" : "Left Lower Forearm",
        "2801" : "Right Lower Forearm",
        "2850" : "Left Hand",
        "2851" : "Right Hand",
        "3150" : "Face: Left Side",
        "3151" : "Face: Right Side",
        "3170" : "Top of Head",
        "3171" : "Face: Front",
        "3172" : "Back of Head"
    ]

    static let zoneIDArray = NSArray(array: [
        "1100", "1200", "1250", "1251",
        "1300", "1301", "1350", "1351",
        "1400", "1401", "1450", "1451",
        "1500", "1501", "1550", "1551",
        "1600", "1601", "1650", "1651",
        "1700", "1701", "1750", "1751",
        "1800", "1801", "1850", "1851",
        "2100", "2200", "2250", "2251",
        "2300", "2301", "2350", "2351",
        "2400", "2401", "2450", "2451",
        "2500", "2501", "2550", "2551",
        "2600", "2601", "2650", "2651",
        "2700", "2701", "2750", "2751",
        "2800", "2801", "2850", "2851",
        "3150", "3151", "3170", "3171", "3172"])
    


}

