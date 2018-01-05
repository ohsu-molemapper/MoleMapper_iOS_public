//
//  TapCoinView.swift
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

import UIKit
import SnapKit

enum USCoin: Int {
    case penny
    case nickle
    case dime
    case quarter

    /**
    returns standard English name for US Coins
    */
    func toString() -> String {
        switch self {
        case .penny:
            return "Penny"
        case .nickle:
            return "Nickle"
        case .dime:
            return "Dime"
        case .quarter:
            return "Quarter"
        }
    }
    /**
    returns defined Int value for coin type as stored on Bridge
    */
    func toInt() -> Int {
        switch self {
        case .penny:
            return 1
        case .nickle:
            return 5
        case .dime:
            return 10
        case .quarter:
            return 25
        }
    }
    
    // Display sequence. Could be alphabetical, could be domination-value based. Going with #2 for now.
    // We should test this (though I doubt consensus would be reached).
    static let pickSequence = [penny, nickle, dime, quarter]
    
}

protocol TapCoinViewDelegate {
    // called by View
    func positionCoin(position: CirclePosition)
    func setCoinType(toType: USCoin)
    func removeCoin()
    func fixCoin()
}

class TapCoinView: UIView {
    //    private var calloutView: SMCalloutView?
    private var imageView = UIImageView()
    fileprivate weak var image: UIImage!
    fileprivate var delegate: TapCoinViewDelegate!
    fileprivate var circleAndPinView: CircleAndPinView?
    fileprivate var coinPosition: CirclePosition?
    fileprivate var coinType = USCoin.penny
    fileprivate var pickerPopover: UIView?
    
    init(frame: CGRect, image: UIImage, delegate: TapCoinViewDelegate) {
        super.init(frame: frame)
        
        self.delegate = delegate
        self.image = image
        
        imageView.contentMode = .scaleAspectFit
        imageView.image = image
        imageView.frame = frame
        self.addSubview(imageView)
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(onTap(recognizer:)))
        addGestureRecognizer(tapRecognizer)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func onTap(recognizer: UITapGestureRecognizer) {
        let location = recognizer.location(in: self)
        let position = CirclePosition(center: location, radius: 30)     // Relative to VIEW
        // TODO: First see if there is already a coin and we're near it. If so,
        // invoke its menu
        if circleAndPinView != nil {
            let sqrDist = TranslateUtils.squaredDistance(pt1: location, pt2: coinPosition!.center)
            if sqrDist < (coinPosition!.radius * coinPosition!.radius) * 1.10 {
                circleAndPinView!.showPinMenu()
            } else {
                circleAndPinView!.showPinMenu(false)
                circleAndPinView!.removeFromSuperview()
                circleAndPinView = nil
            }
        }
        addCoin(position)
    }
    
    /**
    addCoin is called internally to add a coin annotation.
 
    Parameters:
    position: the position of the coin (center and radius) relative to the View coordinate system.
    */
    func addCoin(_ position: CirclePosition) {
        var newViewPosition = position
        var imagePosition = position
        imagePosition.center = TranslateUtils.viewToImageTranslation(position.center, imageSize: image.size, parentView: imageView)
        let fixableData = FixableData(fixableImage: self.image,
                                      fixableCircle: imagePosition)
        
        if let fixedCircle = AutoEncircle.autoEncircleCoin(fixableData) {
            imagePosition = fixedCircle
            let retranslatedCenter = TranslateUtils.imageToViewTranslation(fixedCircle.center, imageSize: image.size, parentView: imageView)
            newViewPosition = CirclePosition(center: retranslatedCenter, radius: fixedCircle.radius)    // Need to scale radius if ever the photo is scaled
        }
        
        circleAndPinView = CircleAndPinView(circlePosition: newViewPosition, parentView: self, delegate: self,
                                                pinType: CircleAndPinType.coinPin)
        
        
        circleAndPinView?.showPinMenu()
        circleAndPinView?.objectID = 0           // object ID of some kind is needed: TODO add to initialization code
        
        coinPosition = position
        delegate.positionCoin(position: imagePosition)
    }
    
    /**
    updateCoin is called (via this view's controller) by the Container controller to pass on
    changes requested by a fix operation.
 
    Parameters:
    - newPosition: the position of the coin relative to the image's coordinate system.
    */
    func updateCoin(newPosition: CirclePosition) {
        // Called by ViewController to push changes downstream (from Fix)
        let retranslatedCenter = TranslateUtils.imageToViewTranslation(newPosition.center, imageSize: image.size, parentView: imageView)
        let newViewPosition = CirclePosition(center: retranslatedCenter, radius: newPosition.radius)    // Need to scale radius if ever the photo is scaled

        if circleAndPinView != nil {
            circleAndPinView!.moveToCirclePosition(circlePosition: newViewPosition)
        }
    }
    
    func acceptCoinSelection() {
        delegate.setCoinType(toType: coinType)
        if pickerPopover != nil {
            pickerPopover!.removeFromSuperview()
        }
    }
    
    func showDenominationPicker() {
        let backgroundView = UIView(frame: self.frame)
        let pickerView = UIPickerView()
        let okButton = UIButton()
        
        self.addSubview(backgroundView)
        backgroundView.addSubview(pickerView)
        backgroundView.addSubview(okButton)
        
        backgroundView.backgroundColor = UXConstants.mmBackgroundGray
        let trapTaps = UITapGestureRecognizer()
        trapTaps.cancelsTouchesInView = true
        backgroundView.addGestureRecognizer(trapTaps)
        
        pickerView.backgroundColor = .white
        pickerView.dataSource = self
        pickerView.delegate = self
        pickerView.layer.cornerRadius = 8.0
        
        okButton.setTitle("OK", for: .normal)
        okButton.setTitleColor(.blue, for: .normal)
        okButton.layer.cornerRadius = 8.0
        okButton.backgroundColor = .white
        
        backgroundView.snp.remakeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        pickerView.snp.remakeConstraints{ (make) in
            make.centerX.equalTo(backgroundView.snp.centerX)
            make.left.equalTo(backgroundView.snp.leftMargin).offset(40)
            make.right.equalTo(backgroundView.snp.rightMargin).offset(-40)
            make.centerY.equalTo(backgroundView.snp.centerY)
        }
        
        okButton.snp.remakeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.left.equalTo(pickerView.snp.left)
            make.right.equalTo(pickerView.snp.right)
            make.top.equalTo(pickerView.snp.bottom).offset(12)
        }
        
        okButton.addTarget(self, action: #selector(acceptCoinSelection), for: .touchUpInside)
        
        pickerPopover = backgroundView
    }
    
    func showMenu() {
        if circleAndPinView != nil {
            circleAndPinView?.showPinMenu(true)
        }
    }

}

extension TapCoinView: CircleAndPinDelegate {
    func acceptObject(_ withID: CInt) {
        showDenominationPicker()
    }
    
    func fixObject(_ withID: CInt) {
        delegate.fixCoin()
    }
    
    func removeObject(_ withID: CInt) {
        if circleAndPinView != nil{
            circleAndPinView!.removeFromSuperview()
            circleAndPinView = nil
            delegate.removeCoin()
        }
    }
    
    func pinTapped(_ withID: CInt) {
    }
    
}

// MARK: UIPickerViewDelegate

extension TapCoinView: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return USCoin.pickSequence[row].toString()
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        coinType = USCoin.pickSequence[row]
    }
}

// MARK: UIPickerViewDataSource

extension TapCoinView: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return USCoin.pickSequence.count
    }
}

