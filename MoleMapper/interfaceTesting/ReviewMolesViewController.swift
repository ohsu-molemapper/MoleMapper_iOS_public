//
//  ReviewMolesViewController.swift
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
import MessageUI

// @objc is needed to make mailComposeDelegate callback in MFMailComposeViewController work
@objc
class ReviewMolesViewController: UIViewController {
    fileprivate var delegate: ReviewMolesDelegate!
    fileprivate var reviewMolesView: ReviewMolesView?
    fileprivate var mole: Mole30?
    fileprivate var sortedMeasurements: [MoleMeasurement30] = []
    
    convenience init(mole: Mole30, delegate: ReviewMolesDelegate) {
        self.init()
        self.delegate = delegate
        self.mole = mole
        
        sortedMeasurements = mole.allMeasurementsSorted()
    }
    
    override func loadView() {
        if mole == nil {
            fatalError("Called ReviewMolesViewController with no mole")
        }

//        var viewFrame = TranslateUtils.calculateNavigationInnerFrameSize(navigationViewController: self.navigationController)
        let viewFrame = self.parent?.view.bounds ?? TranslateUtils.calculateNavigationInnerFrameSize(navigationViewController: self.navigationController)

        reviewMolesView = ReviewMolesView(frame: viewFrame, dataSource: self, delegate: delegate)
        self.view = reviewMolesView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        (self.view as! ReviewMolesView).stopLoop()
        print("review moles view controller disappearing")
    }
    
    func shareMole() {
        if mole != nil {
            self.shareMoleByEmail(forMole: mole!)
        }
    }
    
    func shareMoleByEmail(forMole: Mole30) {
        let subjectText = "[MoleMapper] images for \(forMole.moleName!)"
        let zoneDescription = Zone30.zoneNameForZoneID(forMole.whichZone!.zoneID!) ?? "unknown zone"
        var bodyText = "Measurement data for this mole on \(zoneDescription):\n"
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 1
        
        let mailVC = MFMailComposeViewController()
        //        mailVC.mailComposeDelegate = self
        mailVC.mailComposeDelegate = self
        mailVC.setSubject(subjectText)
        mailVC.setToRecipients(defaultEmailRecipient())
        for moleMeasurement in forMole.allMeasurementsSorted() {
            var index = 0
            if let data = moleMeasurement.getDataAsJPEG() {
                let filename = "image\(index).jpg"
                index += 1
                mailVC.addAttachmentData(data, mimeType: "image/jpg", fileName: filename)
                let measurementDate = moleMeasurement.date!.description
                var sizeString = "Size: n/a"
                if let moleSize = moleMeasurement.calculatedMoleDiameter {
                    if moleSize.floatValue > 0 {
                        let formatter = NumberFormatter()
                        formatter.maximumFractionDigits = 1
                        sizeString = "Size: " + (formatter.string(from: moleSize) ?? "bad")
                    }
                }
                
                var description = "Measurement date: \(measurementDate)\n"
                description.append("mole size: \(sizeString)\n\n")
                bodyText.append(description)
            }
        }
        mailVC.setMessageBody(bodyText, isHTML: false)
        self.present(mailVC, animated: true, completion: {print("done")})
    }
    
    func defaultEmailRecipient() -> [String] {
        let ud = UserDefaults.standard
        let defaultEmail = ud.string(forKey: "emailForExport") ?? ""
        return [defaultEmail]
    }
 
}

extension ReviewMolesViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController,
                               didFinishWith result: MFMailComposeResult, error: Error?) {
        // Check the result or perform other tasks.
        switch result {
        case .cancelled:
            print("mail cancelled")
        case .failed:
            print("mail failed")
        case .saved:
            print("mail saved")
        case .sent:
            print("mail sent")
        }
        
        // Dismiss the mail compose view controller.
        controller.dismiss(animated: true, completion: nil)
    }
   
}

extension ReviewMolesViewController: ReviewMolesDataSource {
    func numberOfMoleMeasurements() -> Int {
        return sortedMeasurements.count
    }
    func moleMeasurement(at: Int) -> MoleMeasurement30? {
        guard at >= 0, at < sortedMeasurements.count else {return nil}
        
        return sortedMeasurements[at]
    }
    func moleName() -> String {
        return mole!.moleName ?? "Missing Name"
    }
}

