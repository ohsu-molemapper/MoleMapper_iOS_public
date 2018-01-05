//
//  V30Stack.swift
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

@objc class V30StackFactory: NSObject {
    private static var v30Stack: V30Stack?
    
    class func createV30Stack() -> V30Stack {
        if v30Stack == nil {
            v30Stack = V30Stack(modelName: "Version30")
        }
        return v30Stack!
    }
}

@objc class V30Stack: NSObject {
    private let modelName: String
    
    init(modelName: String) {
        self.modelName = modelName
    }
    
    private lazy var storeContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: self.modelName)
        container.loadPersistentStores {
            (storeDescription, error) in
            if let error = error as NSError? {
                print("Unresolved error \(error), \(error.userInfo)")
            }
        }
        return container
    }()
    
    lazy var managedContext: NSManagedObjectContext = {
        return self.storeContainer.viewContext
    }()
    
    func saveContext () {
        if managedContext.hasChanges {
            do {
                try managedContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    func transferV2xTo30() {
        let oldModel = V2xStackFactory.createV2xStack()
        let newModel = V30StackFactory.createV30Stack()
        let oldContext: NSManagedObjectContext = oldModel.managedContext
        let newContext: NSManagedObjectContext = newModel.managedContext
        
        //NSFetchRequest<Zone30>(entityName: "Zone30")
        let zoneFetch: NSFetchRequest<Zone> = NSFetchRequest<Zone>(entityName: "Zone")
        let zone30Fetch: NSFetchRequest<Zone30> = Zone30.fetchRequest()

        do {
            let results = try oldContext.fetch(zoneFetch)
            for zone in results {
                print("Got Objective-C Zone object")
                let newZone = Zone30(context: newContext)
                newZone.zoneID = zone.zoneID                // No conversions on this field?
            }
        } catch {
            print("Error getting Zone objects")
        }

        // Just double-checking (syntax-wise) that Swift objects work fine...
        do {
            let results = try newContext.fetch(zone30Fetch)
            for zone30 in results {
                print("Got Swift Zone30 object: \(zone30.zoneID)")
            }
        } catch {
            print("Error getting Zone30 objects")
        }
        // Not saving new objects... just for test right now
        // newModel.saveContext()
        
    }
    
    func dumpModel() {
        print("=========================================================")
        print(">         dumping 30 data")
        print("=========================================================")

        // iterate through each zone and zone measurements
        let zone30Fetch: NSFetchRequest<Zone30> = Zone30.fetchRequest()
        do {
            let results = try managedContext.fetch(zone30Fetch)
            print(" ---- All Zones + Zone Measurements + Mole Measurements--- ")
            for zone in results {
                if zone.whichUser == nil {
                    print("whichUser is nil for zone \(zone.zoneID)")
                } else if zone.whichUser!.count != 1 {
                    print("No users in whichUser set for zone \(zone.zoneID)")
                }
                if zone.zoneMeasurements?.count ?? 0 > 0 {
                    print("ZoneID: \(zone.zoneID ?? "no zone id")")
                    for case let zoneMeasurement as ZoneMeasurement30 in zone.zoneMeasurements! {
                        print("\t----------------------------------")
                        print("\tZM displayPhotoFilename: \(zoneMeasurement.displayPhotoFilename.debugDescription)")
                        print("\tZM fullsizePhotoFilename: \(zoneMeasurement.fullsizePhotoFilename.debugDescription)")
                        print("\tZM lensPosition: \(zoneMeasurement.lensPosition.debugDescription)")
                        print("\tZM referenceDiameter: \(zoneMeasurement.referenceDiameterInPoints.debugDescription)")
                        print("\tZM referenceX: \(zoneMeasurement.referenceX.debugDescription)")
                        print("\tZM referenceY: \(zoneMeasurement.referenceY.debugDescription)")
                        print("\tZM reference object: \(zoneMeasurement.referenceObject)")
                        print("\tZM calculated reference: \(zoneMeasurement.referenceDiameterInMillimeters.debugDescription)")
                        print("\tZM date: \(zoneMeasurement.date.debugDescription)")
                        print("\tZM ID: \(zoneMeasurement.zoneMeasurementID.debugDescription)")
                        print("\tWith the following mole measurements:")
                        if zoneMeasurement.moleMeasurements != nil {
                            for case let moleMeasurement as MoleMeasurement30 in zoneMeasurement.moleMeasurements! {
                                print("\t\t== for mole: \(moleMeasurement.whichMole?.moleName.debugDescription ?? "Missing Mole") =======")
                                print("\t\tcalculated mole diameter: \(moleMeasurement.calculatedMoleDiameter.debugDescription)")
                                print("\t\tcalculated size: \(moleMeasurement.calculatedSizeBasis)")
                                print("\t\tdate: \(moleMeasurement.date.debugDescription)")
                                print("\t\tmole diameter: \(moleMeasurement.moleMeasurementDiameterInPoints.debugDescription)")
                                print("\t\tmole X: \(moleMeasurement.moleMeasurementX.debugDescription)")
                                print("\t\tmole Y: \(moleMeasurement.moleMeasurementY.debugDescription)")
                                print("\t\tmole photo: \(moleMeasurement.moleMeasurementPhoto.debugDescription)")
                            }
                        }
                    }
                }
                let mole30Fetch: NSFetchRequest<Mole30> = Mole30.fetchRequest()
                mole30Fetch.predicate = NSPredicate(format: "whichZone == %@", zone)
                let moleResults = try managedContext.fetch(mole30Fetch)
                for mole in moleResults {
                    print("\tMole: \(mole.moleName) in \(zone.zoneID.debugDescription)")
                }
            }
            // now get all moles and mole measurements (should agree with above)
            print(" ---- All Moles  + Mole Measurements--- ")
            let mole30Fetch2: NSFetchRequest<Mole30> = Mole30.fetchRequest()
            let moleResults = try managedContext.fetch(mole30Fetch2)
            for mole in moleResults {
                print("Mole: \(mole.moleName) in \(mole.whichZone?.zoneID.debugDescription)")
                for case let moleMeasurement as MoleMeasurement30 in mole.moleMeasurements! {
                    print("\tMM Calculated mole diameter: \(moleMeasurement.calculatedMoleDiameter.debugDescription)")
                    print("\tMM Calculated mole basis: \(moleMeasurement.calculatedSizeBasis)")
                    print("\tMM Mole diameter: \(moleMeasurement.moleMeasurementDiameterInPoints.debugDescription)")
                    print("\tMM Mole X: \(moleMeasurement.moleMeasurementX.debugDescription)")
                    print("\tMM Mole Y: \(moleMeasurement.moleMeasurementY.debugDescription)")
                    print("\tMM Mole photo: \(moleMeasurement.moleMeasurementPhoto.debugDescription)")
                    print("\tMM date: \(moleMeasurement.date.debugDescription)")
                    print("\tMM in ZM: \(moleMeasurement.whichZoneMeasurement?.zoneMeasurementID?.debugDescription ?? "Missing ZM")")
                }
            }
        } catch {
            print("Error getting Zone objects")
        }
        do {
            let moleMeasurementsFetch: NSFetchRequest<MoleMeasurement30> = MoleMeasurement30.fetchRequest()
            let measurementResults = try managedContext.fetch(moleMeasurementsFetch)
            for measurement in measurementResults {
                print("Mole Measurement ID: \(measurement.moleMeasurementID)")
            }
        } catch {
            print("Error getting Zone objects")
        }
        print("=========================================================")
        print(">         end of 30 data")
        print("=========================================================")
    }
    
}
