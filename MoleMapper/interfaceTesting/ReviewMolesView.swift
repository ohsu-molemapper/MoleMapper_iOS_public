//
//  ReviewMolesView.swift
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

protocol ReviewMolesDelegate {
    func shareMoleMeasurement(moleMeasurement: MoleMeasurement30)
}

protocol ReviewMolesDataSource {
    func numberOfMoleMeasurements() -> Int
    func moleMeasurement(at: Int) -> MoleMeasurement30?
    func moleName() -> String
}

class ReviewMolesView: UIView {
    fileprivate var delegate: ReviewMolesDelegate!
    fileprivate var dataSource: ReviewMolesDataSource!
    fileprivate var imageView: UIImageView!
    fileprivate var controlToolbar: UIToolbar!
    fileprivate var previousButton: UIBarButtonItem!
    fileprivate var nextButton: UIBarButtonItem!
    fileprivate var playButton: UIBarButtonItem!
    fileprivate var stopButton: UIBarButtonItem!
    fileprivate var numberOfMeasurements: Int = 0
    fileprivate var currentlyDisplayedMeasurement = 0
    fileprivate var runningLoop = false
    fileprivate var loopTimer: Timer?
    fileprivate var dateLabel: UILabel?
    fileprivate var sizeLabel: UILabel?
    
    var slideshowPauseDuration = 0.7        // in seconds

    init(frame: CGRect, dataSource: ReviewMolesDataSource, delegate: ReviewMolesDelegate) {
        super.init(frame: frame)
        
        var adjustedFrame = frame
        
        self.delegate = delegate
        self.dataSource = dataSource
        
        numberOfMeasurements = dataSource.numberOfMoleMeasurements()
        
        self.backgroundColor = .white
        imageView = UIImageView()
        imageView.backgroundColor = .black
        imageView.contentMode = .scaleAspectFit
        
        
        controlToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: adjustedFrame.size.width, height: 0))
        controlToolbar.sizeToFit()
        controlToolbar.tintColor = UXConstants.mmBlue
        controlToolbar.barTintColor = .white
        controlToolbar.isTranslucent = false
        adjustedFrame.size.height -= controlToolbar.bounds.height
        
        let spacer0 = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        previousButton = UIBarButtonItem(barButtonSystemItem: .rewind,
                                           target: self,
                                           action: #selector(onPrevious))
        
        let spacer1 = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        playButton = UIBarButtonItem(barButtonSystemItem: .play,
                                           target: self,
                                           action: #selector(onPlay))
        stopButton = UIBarButtonItem(barButtonSystemItem: .pause,
                                     target: self,
                                     action: #selector(onStop))
        
        let spacer2 = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        nextButton = UIBarButtonItem(barButtonSystemItem: .fastForward,
                                             target: self,
                                             action: #selector(onNext))
        
        let spacer3 = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        controlToolbar.setItems([spacer0, previousButton, spacer1, playButton, spacer2, nextButton, spacer3], animated: false)
        controlToolbar.frame.origin.y = adjustedFrame.size.height
        self.addSubview(controlToolbar)
        
        imageView.frame = adjustedFrame
        self.addSubview(imageView)
 
        let labelFrame = UIView(frame: CGRect(x: 0, y: 0, width: adjustedFrame.width, height: 100))
        labelFrame.backgroundColor = .white
        labelFrame.layer.cornerRadius = 5
        labelFrame.layoutMargins = UIEdgeInsets(top: 4, left: 12, bottom: 4, right: 12)
        
        imageView.addSubview(labelFrame)
        dateLabel = UILabel()
        sizeLabel = UILabel()

        dateLabel?.textColor = UIColor.darkGray
        dateLabel?.textAlignment = .left
        dateLabel?.font = UIFont.systemFont(ofSize: 15)     // TODO create app guideline and adhere
        dateLabel?.numberOfLines = 1
//        dateLabel?.text = "AugyMM-DD-YYYY HH:MM"
//        let dateLabelSize = dateLabel?.sizeThatFits(labelFrame.bounds.size) ?? CGSize(width: labelFrame.bounds.width, height: 17)
        let dateLabelHeight = 20        // determined using Reveal; no need to re-calculate each time

        sizeLabel?.textColor = UIColor.darkGray
        sizeLabel?.textAlignment = .left
        sizeLabel?.font = UIFont.systemFont(ofSize: 13)     // TODO create app guideline and adhere
        sizeLabel?.numberOfLines = 1
//        sizeLabel?.text = "Size: n/a"
//        let sizeLabelSize = sizeLabel?.sizeThatFits(labelFrame.bounds.size) ?? CGSize(width: labelFrame.bounds.width, height: 14)
        let sizeLabelHeight = 16        // determined using Reveal; no need to re-calculate each time
        
        let labelFrameHeight = dateLabelHeight + sizeLabelHeight + 11

        labelFrame.addSubview(dateLabel!)
        labelFrame.addSubview(sizeLabel!)

        labelFrame.snp.remakeConstraints { (make) in
            make.left.equalTo(imageView.snp.leftMargin).offset(8)
            make.right.equalTo(imageView.snp.rightMargin).offset(-8)
            make.top.equalTo(imageView.snp.topMargin).offset(3)
            make.height.equalTo(labelFrameHeight)
        }
        
        dateLabel!.snp.remakeConstraints { (make) in
            make.left.equalTo(labelFrame.snp.leftMargin)
            make.right.equalTo(labelFrame.snp.rightMargin)
            make.top.equalTo(labelFrame.snp.topMargin).offset(0)
            make.height.equalTo(dateLabelHeight)
        }
        
        sizeLabel!.snp.remakeConstraints { (make) in
            make.left.equalTo(labelFrame.snp.leftMargin).offset(16)
            make.right.equalTo(labelFrame.snp.rightMargin)
            make.bottom.equalTo(labelFrame.snp.bottomMargin).offset(0)
            make.height.equalTo(sizeLabelHeight)
        }
        
        nextButton.isEnabled = false
        currentlyDisplayedMeasurement = 0
        resetControlToolbar()
        updateInfoBox()
        showMeasurement(index: currentlyDisplayedMeasurement)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        stopLoop()
    }
    
    func stopLoop() {
        if loopTimer != nil {
            loopTimer!.invalidate()
            loopTimer = nil
        }
    }
    
    func updateInfoBox() {
        // set text in info box
        let moleMeasurement = dataSource.moleMeasurement(at: currentlyDisplayedMeasurement)
        var dateString = moleMeasurement?.date?.description ?? "Unknown date"
        var sizeString = "Size: n/a"
        if let moleSize = moleMeasurement?.calculatedMoleDiameter {
            if moleSize.floatValue > 0 {
                let formatter = NumberFormatter()
                formatter.maximumFractionDigits = 1
                sizeString = "Size: " + (formatter.string(from: moleSize) ?? "bad")
            }
        }
        if let measurementDate = moleMeasurement?.date {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .short
            dateString = dateFormatter.string(from: measurementDate as Date)
            print(measurementDate.debugDescription)
        }
        self.dateLabel?.text = dateString
        self.sizeLabel?.text = sizeString
    }
    
    func resetControlToolbar() {
        self.controlToolbar.items?[3] = playButton
        if currentlyDisplayedMeasurement >= numberOfMeasurements - 1 {
            previousButton.isEnabled = false
        } else {
            previousButton.isEnabled = true
        }
        if currentlyDisplayedMeasurement == 0 {
            nextButton.isEnabled = false
        } else {
            nextButton.isEnabled = true
        }
    }
    
    func onPlay() {
        print("Play")
        DispatchQueue.main.async {
            self.loopTimer = Timer.scheduledTimer(timeInterval: self.slideshowPauseDuration,
                                                  target: self, selector: #selector(self.onTimer),
                                                  userInfo: nil, repeats: true)
        }
        self.controlToolbar.items?[3] = stopButton
        self.previousButton.isEnabled = false
        self.nextButton.isEnabled = false
    }
    
    func onStop() {
        print("Stop")
        stopLoop()
        resetControlToolbar()
    }
    
    // Of importance: indexes go up as the dates get older
    func onPrevious() {
        print("Prev")
        currentlyDisplayedMeasurement += 1
        showMeasurement(index: currentlyDisplayedMeasurement)

        if currentlyDisplayedMeasurement >= numberOfMeasurements - 1 {
            previousButton.isEnabled = false
        }
        if nextButton.isEnabled == false {
            nextButton.isEnabled = true
        }
    }
    
    func onNext() {
        print("Next")
        currentlyDisplayedMeasurement -= 1
        showMeasurement(index: currentlyDisplayedMeasurement)
        
        if currentlyDisplayedMeasurement == 0 {
            nextButton.isEnabled = false
        }
        if previousButton.isEnabled == false {
            previousButton.isEnabled = true
        }
    }
    
    func onTimer() {
        currentlyDisplayedMeasurement += 1
        if currentlyDisplayedMeasurement >= numberOfMeasurements {
            currentlyDisplayedMeasurement = 0
        }
        showMeasurement(index: currentlyDisplayedMeasurement)
        print("tick; showing \(currentlyDisplayedMeasurement)")
    }
    
    func showMeasurement(index: Int) {
        let moleMeasurement = dataSource.moleMeasurement(at: index)
        if let imageView = self.imageView {
            if let image = moleMeasurement?.moleMeasurementImage() {
                imageView.image = image
            } else {
                print("no image!")
            }
        } else {
            print("no imageView!")
        }
        updateInfoBox()
    }
}
