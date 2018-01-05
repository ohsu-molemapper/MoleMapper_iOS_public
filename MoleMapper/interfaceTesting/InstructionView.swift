//
//  InstructionView.swift
//  MoleMapper
//
//  Created by Tracy Petrie on 6/16/17.
//  Copyright © 2017 OHSU. All rights reserved.
//

import UIKit
import SnapKit

protocol InstructionViewDelegate {
    func onNext()
    func optionalButtonTapped()
}

class InstructionView: UIView {
    var shortInstruction: String = ""
    var longInstruction: String = ""
    var optionalButtonText: String?
    let shortLabel = UILabel()
    let longLabel = UILabel()
    let optionalButton = UIButton()
    var nextButton: UIButton!
    fileprivate var delegate: InstructionViewDelegate!
    var optionalTapRecognizer: UITapGestureRecognizer?
    
    let instructionsMargin: CGFloat = 10.0
    
    convenience init(frame: CGRect,
                     shortInstruction: String,
                     longInstruction: String,
                     optionalButtonText: String?,
                     delegate: InstructionViewDelegate) {
        
        self.init(frame: frame)
        self.backgroundColor = .white
        self.shortInstruction = shortInstruction // TODO scrap these? Not using the local cached copy other than in labels
        self.longInstruction = longInstruction
        self.optionalButtonText = optionalButtonText
        
        // Mimic RK's rounded button
        nextButton = createRoundedButton(title: "Next")
        
        self.addSubview(shortLabel)
        self.addSubview(longLabel)
        self.addSubview(optionalButton)
        self.addSubview(nextButton)
        
        self.delegate = delegate
        optionalTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.onTapOptionalButton))
        
        layoutWidgets()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func createRoundedButton(title: String) -> UIButton {
        // Reverse-engineered RK task button
        let btn = UIButton(type: .custom)
        btn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 6, bottom: 0, right: 6)
        btn.addTarget(self, action: #selector(onNext(_:)), for: .touchUpInside)
        btn.addTarget(self, action: #selector(onPress(_:)), for: .touchDown)
        btn.setTitle(title, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        btn.backgroundColor = .white
        btn.setTitleColor(UXConstants.mmBlue, for: .normal)
        btn.setTitleColor(.white, for: .highlighted)
        btn.layer.cornerRadius = 5
        btn.layer.borderColor = UXConstants.mmBlue.cgColor
        btn.layer.borderWidth = 1
        btn.bounds.size = CGSize(width: 146, height: 44)
        return btn
    }
    
    func onPress(_ sender:Any) {
        if sender is UIButton {
            (sender as! UIButton).backgroundColor = UXConstants.mmBlue
        }
    }
    
    func onNext(_ sender: Any) {
        if sender is UIButton {
            (sender as! UIButton).backgroundColor = .white
        }
        self.delegate.onNext()
    }

    
    func layoutWidgets() {
        // TODO: too many magic constants in this code
 
        shortLabel.textColor = UXConstants.mmBlue
        shortLabel.textAlignment = .center
        shortLabel.font = UIFont.systemFont(ofSize: 30)     // TODO create app guideline and adhere
        shortLabel.numberOfLines = 1
        shortLabel.text = shortInstruction
        let shortSize = shortLabel.sizeThatFits(UIScreen.main.bounds.size)
        shortLabel.snp.remakeConstraints { (make) in
            make.left.equalTo(self.snp.leftMargin)
            make.right.equalTo(self.snp.rightMargin)
            make.top.equalTo(self.snp.topMargin).offset(instructionsMargin)
            make.height.equalTo(shortSize.height)
        }
        
        longLabel.textColor = UIColor.darkGray              // TODO app guideline
        longLabel.textAlignment = .center
        longLabel.font = UIFont.systemFont(ofSize: 18)     // TODO create app guideline and adhere
        longLabel.numberOfLines = 0                         // perversely, this means infinite
        longLabel.text = longInstruction
        var longSize = UIScreen.main.bounds.size
        longSize.width -= (self.layoutMargins.left + self.layoutMargins.right)
        longSize = longLabel.sizeThatFits(longSize)
        longLabel.snp.remakeConstraints { (make) in
            make.centerX.equalTo(self.snp.centerX)
            make.left.equalTo(self.snp.leftMargin)
            make.right.equalTo(self.snp.rightMargin)
            make.top.equalTo(shortLabel.snp.bottom).offset(instructionsMargin)
            make.height.equalTo(longSize.height + 30)       // adding 30 because sizeThatFits doesn't seem to work properly.
        }
        
        if let buttonText = optionalButtonText {
            optionalButton.setTitle(buttonText, for: .normal)
            optionalButton.setTitleColor(UXConstants.mmBlue, for: .normal)
            optionalButton.addGestureRecognizer(optionalTapRecognizer!)
            optionalButton.snp.remakeConstraints { (make) in
                make.centerX.equalTo(self.snp.centerX)
                make.left.equalTo(self.snp.leftMargin)
                make.right.equalTo(self.snp.rightMargin)
                make.top.equalTo(self.snp.bottomMargin).offset(-( 2 * instructionsMargin + 30))
                make.height.equalTo(30)
            }
        } else {
            optionalButton.setTitle("", for: .normal)
            optionalButton.removeGestureRecognizer(optionalTapRecognizer!)
        }
        
        nextButton.snp.remakeConstraints { (make) in
            make.centerX.equalTo(self.snp.centerX)
            make.top.equalTo(self.snp.bottomMargin).offset(-( 4 * instructionsMargin + 30 + 44))
            make.width.equalTo(146)
            make.height.equalTo(44)
        }
        
    }
    
    func resetInstructions(newShortInstruction: String, newLongInstruction: String, newOptionalButtonText: String?) {
        self.shortInstruction = newShortInstruction
        self.longInstruction = newLongInstruction
        self.optionalButtonText = newOptionalButtonText
        layoutWidgets()
        setNeedsDisplay()
    }
    
    func onTapOptionalButton () {
//        print("optional button tapped")
        delegate.optionalButtonTapped()
    }
    
}
