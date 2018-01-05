//
//  FixableData.swift
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

enum FixedObjectType {
    case measurementMoleFixed
    case measurementCoinFixed
    case remeasurementMoleFixed
    case remeasurementCoinFixed
    case calibrationCoinFixed
    
    func toInt() -> Int {
        switch self {
        case .measurementMoleFixed:
            return 1
        case .measurementCoinFixed:
            return 2
        case .remeasurementMoleFixed:
            return 3
        case .remeasurementCoinFixed:
            return 4
        case .calibrationCoinFixed:
            return 5
        }
    }
    
}

// Encapsulated data to ship to Bridge
@objc class FixedRecord: NSObject {
    var fixedImage: UIImage
    var fixedObjectType: FixedObjectType
    var originalPosition: CirclePosition
    var fixedPosition: CirclePosition

    init(fixedImage: UIImage, fixedObjectType: FixedObjectType, originalPosition: CirclePosition, fixedPosition: CirclePosition?) {
        self.fixedImage = fixedImage
        self.fixedObjectType = fixedObjectType
        self.originalPosition = originalPosition
        if fixedPosition == nil {
            self.fixedPosition = CirclePosition.zero()
        } else {
            self.fixedPosition = fixedPosition!
        }
        
    }
    
    func dictionaryForBridge() -> NSDictionary {
        var fixedDictionary: [String: Any] = [:]

        fixedDictionary["originalX"] = originalPosition.center.x
        fixedDictionary["originalY"] = originalPosition.center.y
        fixedDictionary["originalRadius"] = originalPosition.radius
        fixedDictionary["fixedX"] = fixedPosition.center.x
        fixedDictionary["fixedY"] = fixedPosition.center.y
        fixedDictionary["fixedRadius"] = fixedPosition.radius
        fixedDictionary["objectType"] = fixedObjectType.toInt()

        let bridgeDictionary = NSMutableDictionary()
        bridgeDictionary.addEntries(from: fixedDictionary)
        return bridgeDictionary
    }

    func sendFixRecordToBridge() {
        let ad = (UIApplication.shared.delegate as? AppDelegate)!
        if ad.user.hasConsented {
            if let bridgeManager = ad.bridgeManager {
                bridgeManager.signInAndSendFixedRecord(fixedRecord: self)
            }
        }
    }

}


@objc class FixableData: NSObject {
    var fixableImage: UIImage           // Image of object to display
    var fixableCircle: CirclePosition   // Position of object being fixed relative to the Image
    
    init(fixableImage: UIImage, fixableCircle: CirclePosition) {
        self.fixableImage = fixableImage
        self.fixableCircle = fixableCircle
    }
}
