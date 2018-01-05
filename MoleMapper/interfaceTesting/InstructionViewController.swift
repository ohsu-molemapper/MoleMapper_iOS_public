//
//  InstructionViewController.swift
//  MoleMapper
//
//  Created by Tracy Petrie on 6/16/17.
//  Copyright © 2017 OHSU. All rights reserved.
//

import UIKit

@objc protocol InstructionViewControllerDelegate {
    func instructionDidTapNext()
    func instructionDidTapCancel()
    func instructionDidTapOptionalButton()
}

@objc class InstructionViewController: UIViewController {
    
    fileprivate var delegate: InstructionViewControllerDelegate!
    fileprivate var shortInstruction: String = ""
    fileprivate var longInstruction: String = ""
    fileprivate var optionalButtonText: String?
    fileprivate var instructionView: InstructionView?

    convenience init(shortInstruction: String,
                     longInstruction: String,
                     optionalButtonText: String?,
                     delegate: InstructionViewControllerDelegate) {
        self.init()
        
        self.delegate = delegate
        self.shortInstruction = shortInstruction
        self.longInstruction = longInstruction
        self.optionalButtonText = optionalButtonText

    }
    
    func debugFunc() {
//        instructionView!.reportWindowPositions()
    }
    
    override func loadView() {
        let viewFrame = self.parent?.view.bounds ?? TranslateUtils.calculateNavigationInnerFrameSize(navigationViewController: self.navigationController)
        
        instructionView = InstructionView(frame: viewFrame,
                                          shortInstruction: shortInstruction,
                                          longInstruction: longInstruction,
                                          optionalButtonText: optionalButtonText,
                                          delegate: self)
        
        self.view = instructionView!
        
    }
    
    func resetInstructions(newShortInstruction: String, newLongInstruction: String, newOptionalButtonText: String?) {
        self.shortInstruction = newShortInstruction
        self.longInstruction = newLongInstruction
        self.optionalButtonText = newOptionalButtonText
        
        if self.instructionView != nil {
            self.instructionView!.resetInstructions(newShortInstruction: newShortInstruction,
                                                newLongInstruction: newLongInstruction,
                                                newOptionalButtonText: newOptionalButtonText)
        } else {
            fatalError("resetInstructions called before loadView")
        }
    }

}

extension InstructionViewController: InstructionViewDelegate {
    func onNext() {
        // in preparation for adding a ResearchKit-like "Next" button instead of using the UINavigationBarButton
        delegate.instructionDidTapNext()
    }
    
    func optionalButtonTapped() {
        // specific to one Instruction View incarnation (bit of a hack, really. Ugh.)
        delegate.instructionDidTapOptionalButton()
    }
}
