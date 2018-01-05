//
//  V2xStack.swift
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

//import Foundation

import CoreData

@objc  class V2xStackFactory: NSObject {
    private static var v2xStack: V2xStack?
    
    class func createV2xStack() -> V2xStack {
        if v2xStack == nil {
            v2xStack = V2xStack(modelName: "InterfaceTesting")
        }
        return v2xStack!
    }

    class func stackExists() -> Bool {
        var dbExists = false
        let dirs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let existtest = FileManager.default.fileExists(atPath: dirs.last!.relativePath + "/interfaceTesting.sqlite")
        if existtest {
            dbExists = true
        }
        return dbExists
   }
}

@objc class V2xStack: NSObject {
    private let modelName: String
    
    init(modelName: String) {
        self.modelName = modelName
    }
    
    private lazy var storeContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: self.modelName)
        let docsDirUrls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
//        let dbLocation = docsDirUrls.last!.relativePath + "/interfaceTesting.sqlite"       // where it was manually stored in 2.x
        let dbLocation = docsDirUrls.last!.appendingPathComponent("interfaceTesting.sqlite", isDirectory: false)
        let persistentStoreDesc = NSPersistentStoreDescription(url: dbLocation)
        container.persistentStoreDescriptions = [persistentStoreDesc]

        container.loadPersistentStores {
            (storeDescription, error) in
            if let error = error as NSError? {
                print("Unresolved error \(error), \(error.userInfo)")
            } else {
                print(storeDescription)
                if let storeUrl = storeDescription.url {
                    print(storeUrl.absoluteString)
                }
            }
        }
        let d1 = container.persistentStoreCoordinator
        let d2 = container.name
        let d3 = container.managedObjectModel
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
    func dumpModel() {
        print("=========================================================")
        print(">         dumping 2x data")
        print("=========================================================")
        // iterate through each zone getting each mole and then each mole measurement
        let zoneFetch = NSFetchRequest<Zone>(entityName: "Zone")
        do {
            let results = try managedContext.fetch(zoneFetch)
            print(" ---- All Zones --- ")
            for zone in results {
                if (Zone.hasValidImageData(forZoneID: zone.zoneID)){
                    print("ZoneID: \(zone.zoneID)")
                    print("Zone photo: \(zone.zonePhoto)")
                    for case let mole as Mole in zone.moles {
                        print("\tMoleID: \(mole.moleID.debugDescription)")
                        print("\tmole name: \(mole.moleName.debugDescription)")
                        print("\tmole X: \(mole.moleX.debugDescription)")
                        print("\tmole Y: \(mole.moleY.debugDescription)")
                        for case let measurement as Measurement2x in mole.measurements {
                            print("\t\tMM absolute mole diameter: \(measurement.absoluteMoleDiameter.debugDescription)")
                            print("\t\tMM absolute reference diameter: \(measurement.absoluteReferenceDiameter.debugDescription)")
                            print("\t\tMM measurement diameter: \(measurement.measurementDiameter.debugDescription)")
                            print("\t\tMM measurementX: \(measurement.measurementX.debugDescription)")
                            print("\t\tMM measurementY: \(measurement.measurementY.debugDescription)")
                            print("\t\tMM measurement photo: \(measurement.measurementPhoto.debugDescription)")
                            print("\t\tMM reference diameter: \(measurement.referenceDiameter.debugDescription)")
                            print("\t\tMM reference object: \(measurement.referenceObject.debugDescription)")
                            print("\t\tMM reference X: \(measurement.referenceX.debugDescription)")
                            print("\t\tMM reference Y: \(measurement.referenceY.debugDescription)")
                            print("\t\tMM date: \(measurement.date.debugDescription)")
                        }
                    }
                }
            }
        } catch {
            print("Error getting Zone objects")
        }
        print("=========================================================")
        print(">         end of 2x data")
        print("=========================================================")
    }

}
