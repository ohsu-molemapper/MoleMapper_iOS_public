//
//  Mole30+CoreDataClass.swift
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

@objc(Mole30)
public class Mole30: NSManagedObject {
    
    /**
     create creates a new Mole30 object using the global context maintained
     by the V30Stack singleton factory.
     */
    class func create() -> Mole30 {
        let mole30 = Mole30(context: V30StackFactory.createV30Stack().managedContext)
        mole30.moleID = NSUUID().uuidString
        mole30.moleWasRemoved = false
        return mole30
    }

    // MARK: Query helpers

    /**
     moleFromMoleID is a class function that returns the mole object for a given mole ID
     
     Parameters:
     - _ String containing UUID that identifies the mole
     
     Returns: nil if not found, the Mole30 object if found.
     */
    class func moleFromMoleID(_ moleID: String) -> Mole30? {
        var mole30: Mole30?
        let context = V30StackFactory.createV30Stack().managedContext
        let moleFetch: NSFetchRequest<Mole30> = Mole30.fetchRequest()
        moleFetch.predicate = NSPredicate(format: "moleID == %@", moleID)
        do {
            let result = try context.fetch(moleFetch)
            if result.count > 0 {
                mole30 = result[0]
            } else {
                print("Couldn't find mole for \(moleID)")
            }
        } catch let err as NSError {
            print("Error \(err), \(err.userInfo) fetching mole  \(moleID)")
        }
        return mole30
        
    }
    
    class func allMoles() -> [Mole30] {
        var moleArray: [Mole30] = []
        let context = V30StackFactory.createV30Stack().managedContext
        let moleFetch: NSFetchRequest<Mole30> = Mole30.fetchRequest()
        do {
            let results = try context.fetch(moleFetch)
            moleArray = results as! [Mole30]
        } catch let err as NSError {
            print("Error \(err), \(err.userInfo) ")
        }
        return moleArray
    }
    
    /**
     mostRecentMeasurement is an instance method that returns the most recent
     measurement object for this mole.
     
     Parameters:
     - _ withCalculatedDiameter: Boolean value; true if measurement must have a calculated value,
     false (default) if the caller only cares about the existence of a measurement of any kind.
     
     Returns: nil if not found, a MoleMeasurement30 object if found.
     */
    func mostRecentMeasurement(_ withCalculatedDiameter: Bool = false) -> MoleMeasurement30? {
        var moleMeasurement: MoleMeasurement30?
        let context = V30StackFactory.createV30Stack().managedContext
        let sortDesc = NSSortDescriptor(key: "date", ascending: false)
        let moleMeasurementFetch: NSFetchRequest<MoleMeasurement30> = MoleMeasurement30.fetchRequest()
        moleMeasurementFetch.predicate = NSPredicate(format: "whichMole == %@", self)
        moleMeasurementFetch.sortDescriptors = [sortDesc]
        do {
            let results = try context.fetch(moleMeasurementFetch)
            if results.count > 0 {
                if withCalculatedDiameter {
                    for measurement in results {
                        if let calculatedDiameter = measurement.calculatedMoleDiameter {
                            if calculatedDiameter.floatValue > 0.0 {
                                moleMeasurement = measurement
                                break;
                            }
                        }
                    }
                } else {
                    moleMeasurement = results[0]
                }
            } else {
//                print("Zone already exists")
            }
        } catch let err as NSError {
            print("Error \(err), \(err.userInfo) fetching mole measurement for mole \(self.moleName)")
        }
        return moleMeasurement
    }

    /**
     oldestMeasurement is an instance method that returns the oldest measurement object 
     for this mole WITH A CALCULATED VALUE.
     
     Parameters:
     - _ withCalculatedDiameter: Boolean value; true if measurement must have a calculated value,
     false (default) if the caller only cares about the existence of a measurement of any kind.
     
     Returns: nil if not found, a MoleMeasurement30 object if found.
     */
    func oldestMeasurement(_ withCalculatedDiameter: Bool = false) -> MoleMeasurement30? {
        var moleMeasurement: MoleMeasurement30?
        let context = V30StackFactory.createV30Stack().managedContext
        let sortDesc = NSSortDescriptor(key: "date", ascending: true)
        let moleMeasurementFetch: NSFetchRequest<MoleMeasurement30> = MoleMeasurement30.fetchRequest()
        moleMeasurementFetch.predicate = NSPredicate(format: "whichMole == %@", self)
        moleMeasurementFetch.sortDescriptors = [sortDesc]
        do {
            let results = try context.fetch(moleMeasurementFetch)
            if results.count > 0 {
                if withCalculatedDiameter {
                    for measurement in results {
                        if let calculatedDiameter = measurement.calculatedMoleDiameter {
                            if calculatedDiameter.floatValue > 0.0 {
                                moleMeasurement = measurement
                                break
                            }
                        }
                    }
                } else {
                    moleMeasurement = results[0]
                }
            } else {
//                print("Zone already exists")
            }
        } catch let err as NSError {
            print("Error \(err), \(err.userInfo) fetching mole measurement for mole \(self.moleName ?? "")")
        }
        return moleMeasurement
    }
    
    /**
     needsRemeasuring returns True if the mole hasn't been measured in more than 30 days.
     Eventually, we may want to let the user configure this interval.
     */
    func needsRemeasuring() -> Bool {
        var retval = false
        if let mostRecentMeasurement = self.mostRecentMeasurement() {
            let secondsAgo = mostRecentMeasurement.date!.timeIntervalSinceNow
            let daysAgo = -(secondsAgo / 86400)    // 60 sec/min * 60 min/hour * 24 hour/day
            if daysAgo > 30 {
                retval = true
            }
        }
        return retval
    }
    
    /**
     numberOfMolesNeedingRemeasurement returns just what it claims to return. It returns as a CInt so that
     it can more easily be called from Objective-C code.
    */
    class func numberOfMolesNeedingRemeasurement() -> CInt {
        var total = 0
        for mole in Mole30.allMoles() {
            if mole.needsRemeasuring() {
                total += 1
            }
        }
        return CInt(total)
    }
    
    /**
     allMeasurementsSorted is an instance method that returns all measurement
     objects for this mole sorted by date (most recent first).
     
     Parameters:
     - none
     
     Returns: an array (potentially empty) of MoleMeasurement30 objects.
     */
    func allMeasurementsSorted() -> [MoleMeasurement30] {
        var moleMeasurements: [MoleMeasurement30] = []
        let context = V30StackFactory.createV30Stack().managedContext
        let sortDesc = NSSortDescriptor(key: "date", ascending: false)
        let moleMeasurementFetch: NSFetchRequest<MoleMeasurement30> = MoleMeasurement30.fetchRequest()
        moleMeasurementFetch.predicate = NSPredicate(format: "whichMole == %@", self)
        moleMeasurementFetch.sortDescriptors = [sortDesc]
        do {
            let result = try context.fetch(moleMeasurementFetch)
            for measurement in result {
                moleMeasurements.append(measurement)
            }
        } catch let err as NSError {
            print("Error \(err), \(err.userInfo) fetching mole measurements for mole \(self.moleName.debugDescription)")
        }
        return moleMeasurements
    }
    
    // MARK: Statistics helpers
    
    /**
     moleCount is a class method that returns the total number of moles
     currently tracked.
     
     Parameters:
     - none
     
     Returns: an NSNumber containing an integer value
     */
    class func moleCount() -> NSNumber {
        let context = V30StackFactory.createV30Stack().managedContext
        let moleFetch = NSFetchRequest<NSNumber>(entityName: "Mole30")
        moleFetch.resultType = .countResultType
        var count:Int = 0
        do {
            let result = try context.fetch(moleFetch)
            count = result.first!.intValue
        } catch let err as NSError {
            print("Error \(err), \(err.userInfo)")
        }
        return NSNumber(value: count)
    }
    
    
    /**
     averageMoleSize is a class method that returns the average mole measurement.
     
     Parameters:
     - none
     
     Returns: an NSNumber containing a Float value. Only moles with calculated values
     are averaged together.
     */
    class func averageMoleSize() -> NSNumber {
        // Can contain "n/a" values so we can't just call a database average function
        var cumulativeSize:Float = 0.0
        var totalMeasurements = 0
        let context = V30StackFactory.createV30Stack().managedContext
        let moleFetch: NSFetchRequest<Mole30> = Mole30.fetchRequest()
        let moleMeasurementFetch: NSFetchRequest<MoleMeasurement30> = MoleMeasurement30.fetchRequest()
        do {
            let moles = try context.fetch(moleFetch)
            if moles.count > 0 {
                for mole in moles {
                    moleMeasurementFetch.predicate = NSPredicate(format: "whichMole == %@", mole)
                    let measurements = try context.fetch(moleMeasurementFetch)
                    for measurement in measurements {
                        if let calculatedDiameter = measurement.calculatedMoleDiameter?.floatValue {
                            if calculatedDiameter > 0 {
                                cumulativeSize = cumulativeSize + calculatedDiameter
                                totalMeasurements += 1
                            }
                        }
                    }
                }
            } else {
//                print("no moles")
            }
        } catch let err as NSError {
            print("Error \(err), \(err.userInfo) ")
        }
        var averageSize:Float = 0.0
        if totalMeasurements > 0 {
            averageSize = cumulativeSize / Float(totalMeasurements)
        }
        return NSNumber(value: averageSize)
    }
    
    // Testing Function
    func setMeasurementDatesBackOneMonthForMole() {
        let thirtyDaysInSeconds = 60*60*24*30 as Double
        for case let moleMeasurement as MoleMeasurement30 in self.moleMeasurements! {
            moleMeasurement.date = moleMeasurement.date!.addingTimeInterval(-thirtyDaysInSeconds)
        }
        V30StackFactory.createV30Stack().saveContext()
    }

}
