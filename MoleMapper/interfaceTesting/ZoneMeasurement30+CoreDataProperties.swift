//
//  ZoneMeasurement30+CoreDataProperties.swift
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


extension ZoneMeasurement30 {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ZoneMeasurement30> {
        return NSFetchRequest<ZoneMeasurement30>(entityName: "ZoneMeasurement30")
    }

    @NSManaged public var referenceDiameterInMillimeters: NSNumber?
    @NSManaged public var date: NSDate?
    @NSManaged public var displayPhotoFilename: String?
    @NSManaged public var fullsizePhotoFilename: String?
    @NSManaged public var lensPosition: NSNumber?
    @NSManaged public var referenceDiameterInPoints: NSNumber?
    @NSManaged public var referenceObject: Int16
    @NSManaged public var referenceX: NSNumber?
    @NSManaged public var referenceY: NSNumber?
    @NSManaged public var uploadSuccess: NSNumber?
    @NSManaged public var zoneMeasurementID: String?
    @NSManaged public var moleMeasurements: NSSet?
    @NSManaged public var whichZone: Zone30?

}

// MARK: Generated accessors for moleMeasurements
extension ZoneMeasurement30 {

    @objc(addMoleMeasurementsObject:)
    @NSManaged public func addToMoleMeasurements(_ value: MoleMeasurement30)

    @objc(removeMoleMeasurementsObject:)
    @NSManaged public func removeFromMoleMeasurements(_ value: MoleMeasurement30)

    @objc(addMoleMeasurements:)
    @NSManaged public func addToMoleMeasurements(_ values: NSSet)

    @objc(removeMoleMeasurements:)
    @NSManaged public func removeFromMoleMeasurements(_ values: NSSet)

}
