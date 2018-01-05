//
//  ReviewZoneViewController.swift
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

/*
 Placeholder classes; either replace with modified ZoneView* classes or integrate
 the ZoneView* classes into these classes.
 */

import UIKit

class ReviewZoneViewController: UIViewController {

    var image: UIImage!
    var moleMeasurements: [MoleMeasurement30] = []
    var reviewZoneView: ReviewZoneView!
    var delegate: ReviewZoneViewDelegate!
    
    convenience init(zoneID: String,
                     displayImage: UIImage,
                     moleMeasurements: [MoleMeasurement30],
                     delegate: ReviewZoneViewDelegate) {
        self.init()
        
        self.delegate = delegate
        self.image = displayImage
        self.moleMeasurements = moleMeasurements
    }
    
    override func loadView() {
        var frame = self.parent?.view.bounds
        if frame == nil {
            frame = UIScreen.main.bounds
        }
        
        reviewZoneView = ReviewZoneView(frame: frame!, image: image, moleMeasurements: moleMeasurements, delegate: delegate)
        self.view = reviewZoneView
        self.view.frame = frame!
    }
    
    func changePinType(forID: Int, newType: CircleAndPinType) {
        reviewZoneView.changePinType(forID,newType)
    }
    
    func removePin(forID: Int) {
        reviewZoneView.removePin(forID)
    }
    
    func updatePinMoleName(newName: String, forID: Int) {
        reviewZoneView.updatePinTitle(newName, forID:forID)
    }

}
