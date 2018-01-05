//
//  RemeasureZoneViewController.swift
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

enum RemeasureZoneState {
    case reviewZone
    case takePhotoInstruction
    case takingPhoto
    case tapCoinInstruction
    case tappingCoin
    case fixCoinInstruction
    case fixingCoin
    case dragMoleInstruction
    case draggingMole
    case fixMoleInstruction
    case fixingMole
    case reviewMole
    case zmUndefined
}

/**
 Event states for the NewZoneMeasurementController state machine
 
 - zmGoto: initialization event to setup whatever needs setting up in that state
 - zmBack: Back clicked (on Fix instructions screens)
 - zmCancel: Cancel clicked
 - zmDone: Done clicked (on Fix and Mole Tap screens)
 - zmNext: Next clicked
 - zmFix: Fix called from Fix system
 - zmSkipCoin: Hack event to deal with bypassing coin steps
 - zmUpdateMole: called by Fix system
 */
enum RemeasureZoneEvent {
    case zmGoto
    case zmBack
    case zmCancel
    case zmDone
    case zmNext
    case zmFix
    case zmSkipCoin
    case zmUpdateMole
}

@objc class RemeasureZoneViewController: UINavigationController {
    var zoneTitle: String = ""
    var zoneID: Int = 0
    
    convenience init(zoneID: String, zoneTitle: String, moleToShow: Mole30? = nil) {
        let containerVC = RemeasureZoneContainer()
        containerVC.zoneTitle = zoneTitle
        containerVC.zoneID = zoneID
        if moleToShow != nil {
            containerVC.showMoleHistoryAfterLoading(moleToShow: moleToShow!)
        }
        self.init(rootViewController: containerVC)
    }
    
    override func loadView() {
        self.navigationBar.isTranslucent = false    // Warning: this changes where subviews start!
        super.loadView()
    }
    
}

@objc class RemeasureZoneContainer: UIViewController {
    fileprivate var currentState = RemeasureZoneState.reviewZone
    fileprivate var animationDirection = ContainerTransitionDirection.none
    
    fileprivate var instructionVC: InstructionViewController?
    fileprivate var jpegData: Data?
    fileprivate var displayPhoto: UIImage?
    fileprivate var lensPosition: Float = -1.0
    fileprivate var skipCoinStep = false

    fileprivate var mmPhotoVC: MoleMapperPhotoController?
    fileprivate var reviewZoneVC: ReviewZoneViewController?
    fileprivate var dragMolesViewController: DragMolesViewController?
    fileprivate var tapCoinViewController: TapCoinViewController?
    fileprivate var reviewMolesVC: ReviewMolesViewController?
    
    fileprivate var originalMoleMeasurements: [MoleMeasurement30] = []      // input into Draggable system, etc. :: MOST RECENT measurement for each mole
    fileprivate var numericIdToPosition: [Int:CirclePosition] = [:]        // cache changes sent by Draggable system
    fileprivate var numericIdToMole: [Int:Mole30] = [:]
    fileprivate var moleBeingFixedID: Int = -1
    fileprivate var moleBeingFixedPosition: CirclePosition?     // Relative to IMAGE
    fileprivate var lastID = 0

    fileprivate var fixableData: FixableData?
    fileprivate var fixedObject: FixedRecord?

    fileprivate var moleToReview: Mole30?
    
    fileprivate var coinPosition: CirclePosition?
    fileprivate var coinType: USCoin?
    fileprivate var coinBeingFixedPosition: CirclePosition?
    fileprivate var coinFixResults: ZoneMeasurementFixResults = .zmNotFixing

    fileprivate var removedSurvey: MoleWasRemovedRKModule?
    
    var zoneTitle: String = "New Zone"

    // MARK: Properties
    var zoneID: String?
    
    func showMoleHistoryAfterLoading(moleToShow: Mole30) {
        moleToReview = moleToShow
    }

    override func loadView() {
        if zoneID == nil {
            fatalError("Called RemeasureZoneViewController with no zoneID")
        }
        
        
        self.displayPhoto = Zone30.latestDisplayImageForZoneID(zoneID!)
        // Get moles, then get **most recent** measurement for each mole and append to originalMoleMeasurements
        let moles = Zone30.allMolesInZoneForZoneID(zoneID!)
        if moles != nil {
            for mole in moles! {
                if let moleMeasurement = (mole as! Mole30).mostRecentMeasurement() {
                    let radius: CGFloat = CGFloat(moleMeasurement.moleMeasurementDiameterInPoints!) / 2.0
                    let center = CGPoint(x: (moleMeasurement.moleMeasurementX! as! CGFloat),
                                         y: (moleMeasurement.moleMeasurementY! as! CGFloat))
                    self.originalMoleMeasurements.append(moleMeasurement)
                    self.numericIdToPosition[lastID] = CirclePosition(center: center, radius: radius)
                    self.numericIdToMole[lastID] = mole as? Mole30
                    lastID += 1
                }
            }
        }

        // Have to have a base view to add subviews to
        let viewFrame = TranslateUtils.calculateNavigationInnerFrameSize(navigationViewController: self.navigationController)
                
        view = UIView(frame: viewFrame)
        view.backgroundColor = .darkGray
        
        reviewZoneVC = ReviewZoneViewController(zoneID: zoneID!,
                                                displayImage: self.displayPhoto!,
                                                moleMeasurements: self.originalMoleMeasurements,
                                                delegate: self)
        
        // TODO: what to use if not using instructions?
        instructionVC = InstructionViewController(shortInstruction: "",
                                                  longInstruction: "",
                                                  optionalButtonText: nil,
                                                  delegate: self)
        currentState = .reviewZone
        
        if moleToReview != nil {
            currentState = .reviewMole
        }
        animationDirection = .toLeft
    }
    
    override func viewDidLoad() {
        transitionState(event: .zmGoto)     // kick off state machine
    }
 
    func showCancelDoneNavigation() {
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain,
                                                                target: self, action: #selector(handleCancel))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .done,
                                                                 target: self, action: #selector(handleDone))
    }
    
    func showCancelNextNavigation() {
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain,
                                                                target: self, action: #selector(handleCancel))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Next", style: .plain,
                                                                 target: self, action: #selector(handleNext))
    }
    
    func showBackNextNavigation() {
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back", style: .plain,
                                                                target: self, action: #selector(handleBack))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Next", style: .plain,
                                                                 target: self, action: #selector(handleNext))
    }
    
    func showBackRemeasureNavigation() {
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back", style: .plain,
                                                                target: self, action: #selector(handleBack))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Re-measure", style: .plain,
                                                                 target: self, action: #selector(handleNext))
    }
    
    func showBackShareNavigation() {
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back", style: .plain,
                                                                target: self, action: #selector(handleBack))
 
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action,
                                     target: self,
                                     action: #selector(handleShare))
    }
    
    func cleanupAndExit() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func saveDataAndExit() {
        let ad = (UIApplication.shared.delegate as? AppDelegate)!
        var measurementsToSendToBridge = ad.user.measurementsToSendBridge! // type bridging happens magically

        let zone30 = Zone30.zoneForZoneID(zoneID!)

        // Step1: Create Parent Zone Measurement
        let zoneMeasurement30 = ZoneMeasurement30.create()
        zoneMeasurement30.whichZone = zone30
        zoneMeasurement30.date = NSDate()
        // TODO: finish calculating reference diameter
        zoneMeasurement30.referenceDiameterInMillimeters = NSNumber(value: 0.0)
        zoneMeasurement30.lensPosition = NSNumber(value: self.lensPosition)
        var mmPerPixel:Float = 0.0
        if self.coinPosition != nil {
            zoneMeasurement30.referenceX = coinPosition!.center.x as NSNumber
            zoneMeasurement30.referenceY = coinPosition!.center.y as NSNumber
            zoneMeasurement30.referenceDiameterInPoints = (coinPosition!.radius * 2) as NSNumber
            zoneMeasurement30.referenceObject = Int16(coinType!.toInt())
            if self.coinType != nil {
                zoneMeasurement30.referenceObject = Int16(coinType!.toInt())
                if let mmCoin = TranslateUtils.coinDiametersInMillemeters[self.coinType!.toInt()] {
                    zoneMeasurement30.referenceDiameterInMillimeters = NSNumber(value: mmCoin)
                    mmPerPixel = TranslateUtils.mmPerSomething(diameter: (Float(coinPosition!.radius * 2)), coinDenomiation: coinType!.toInt())
                }
            } else {
                zoneMeasurement30.referenceObject = 0
            }

        } else {
            zoneMeasurement30.referenceX = -1.0
            zoneMeasurement30.referenceY = -1.0
            zoneMeasurement30.referenceDiameterInPoints = -1.0
            zoneMeasurement30.referenceObject = 0
        }
        zoneMeasurement30.uploadSuccess = false
        
        // ******
        // TODO: asynchronize the calls
        // ******
        //        filenames implicitly set inside the save calls; the property is what they _are_ named, the method is what they _should_ be named
        zoneMeasurement30.saveFullsizedDataAsJPEG(jpegData: self.jpegData!)
        zoneMeasurement30.saveDisplayDataAsPNG(pngData: UIImagePNGRepresentation(self.displayPhoto!)!)
        
        // Read full image into UIImage object (not Data object) for clipping
        let jpegImage = zoneMeasurement30.fullsizedImage()

        // Now generate new MoleMeasurements
        let mng = MoleNameGenerator()
        let moleNameGender = UserDefaults.standard.string(forKey: "moleNameGender")
        
        for (tempID, position) in numericIdToPosition {
            var mole30 = numericIdToMole[tempID]
            if mole30 == nil {
                print("Creating a new mole object")
                mole30 = Mole30.create()
                mole30!.moleName = mng.randomUniqueMoleName(withGenderSpecification: moleNameGender)
                mole30!.whichZone = zone30
            }
            
            // Create MoleMeasurement object here
            let moleMeasurement30 = MoleMeasurement30.create()
            moleMeasurement30.whichMole = mole30
            moleMeasurement30.whichZoneMeasurement = zoneMeasurement30
            if (mmPerPixel > 0) {
                moleMeasurement30.calculatedMoleDiameter = NSNumber(value: (Float(position.radius) * 2) * mmPerPixel)
                moleMeasurement30.calculatedSizeBasis = 1
            } else {
                moleMeasurement30.calculatedMoleDiameter = -1.0
                moleMeasurement30.calculatedSizeBasis = 0
            }

            moleMeasurement30.calculatedSizeBasis = 0
            moleMeasurement30.date = zoneMeasurement30.date
            moleMeasurement30.moleMeasurementDiameterInPoints = (position.radius * 2) as NSNumber
            moleMeasurement30.moleMeasurementX = position.center.x as NSNumber
            moleMeasurement30.moleMeasurementY = position.center.y as NSNumber
            
            if jpegImage != nil {
//                // Clip image here
//                // convert display coordinates to full image coordinates
//                // Note: measurement coordinates are in Portrait orientation but the JPEG is in Landscape orientation
//                // (and there doesn't seem to be an easy way to "treat" it differently though we could create a new
//                // rotated version...but why?)
                let fullsizeCircle = TranslateUtils.translateDisplayCircleToJpegCircle(objectPosition: position,
                                                                                       displaySize: self.displayPhoto!.size,
                                                                                       jpegSize: jpegImage!.size)
            
                if let croppedImage = TranslateUtils.cropMoleInImage(sourceImage: jpegImage!, moleLocation: fullsizeCircle) {
                    moleMeasurement30.saveDataAsJPEG(jpegData: UIImageJPEGRepresentation(croppedImage, 1.0)!)
                }
            }
            if ad.user.hasConsented {
                measurementsToSendToBridge[moleMeasurement30.moleMeasurementID!] = 1
            }
        }
        V30StackFactory.createV30Stack().saveContext()
        if ad.user.hasConsented {
            measurementsToSendToBridge[zoneMeasurement30.zoneMeasurementID!] = 0
            ad.user.measurementsToSendBridge = measurementsToSendToBridge
            
            // DEBUG TEST
            //        if let really = ad.user.measurementsToSendBridge {
            //            for (key,value) in really {
            //                print("\(key) : \(value)")
            //            }
            //        }
            if let bridgeManager = ad.bridgeManager {
                bridgeManager.signInAndSendMeasurements()
            }
        }
  
        cleanupAndExit()
    }
    

    
    /**
     This is the bulk of the intelligence for this subsystem. The state machine responds
     to events, modifies the model and possibly the view (ViewControllers) and transitions
     usually to the next state (which often finishes the transtion)
     */
    func transitionState(event: ZoneMeasurementEvent) {
        var nextState = currentState
        switch currentState {
        case .reviewZone:
            if event == .zmGoto {
                if childViewControllers.count == 0 {
                    var screenBounds = UIScreen.main.bounds
                    if let vc = self.navigationController {
                        if vc.navigationBar.isTranslucent == false {
                            screenBounds.size.height -= vc.navigationBar.bounds.size.height
                        }
                    }
                    screenBounds.size.height -= UIApplication.shared.statusBarFrame.size.height
                    self.addChildViewController(reviewZoneVC!)
                    reviewZoneVC!.view.frame = screenBounds
                    self.view.addSubview(reviewZoneVC!.view)
                    reviewZoneVC!.didMove(toParentViewController: self)
                } else {
                    if childViewControllers[0] !=  reviewZoneVC {
                        ContainerTransitions.switchToWithAnimation(containerVC: self, fromVC: childViewControllers[0], toVC: reviewZoneVC!, direction: animationDirection)
                    }
                }
                showCancelNextNavigation()
                self.navigationItem.title = zoneTitle
            } else if event == .zmCancel {
                cleanupAndExit()
            } else if event == .zmNext {
                nextState = .takePhotoInstruction
            } else {
                print("Unexpected event in .takePhotoInstructions")
            }
            break
            
        case .takePhotoInstruction:
            if event == .zmGoto {
                if instructionVC != nil {       // not the greatest test for "are we showing instructions?" Should be explicit.
                    let viewFrame = TranslateUtils.calculateNavigationInnerFrameSize(navigationViewController: self.navigationController)
                    
                    self.addChildViewController(instructionVC!)
                    instructionVC!.view.frame = viewFrame
                    self.view.addSubview(instructionVC!.view)
                    instructionVC!.didMove(toParentViewController: self)
                } else {
                    // TODO: transition directly to taking photo
                    self.addChildViewController(UIViewController())     // need an root view controller to swap out
                    handleNext()
                }
                instructionVC?.resetInstructions(
                    newShortInstruction: "Photograph Zone",
                    newLongInstruction: "Tap to auto-focus and take a photo. Include a US coin if possible. \n\nTry to line up mole pins with moles.",
                    newOptionalButtonText: nil)
                if childViewControllers[0] !=  instructionVC {
                    ContainerTransitions.switchToWithAnimation(containerVC: self, fromVC: childViewControllers[0], toVC: instructionVC!, direction: animationDirection)
                }
                showCancelNextNavigation()
                self.navigationItem.title = zoneTitle
            } else if event == .zmCancel {
                cleanupAndExit()
            } else if event == .zmNext {
                nextState = .takingPhoto
            } else {
                print("Unexpected event in .takePhotoInstructions")
            }
            break
            
        case .takingPhoto:
            if event == .zmGoto {
                mmPhotoVC = MoleMapperPhotoController(withDelegate: self)
                mmPhotoVC!.showTorch = true
                mmPhotoVC!.showControls = true
                mmPhotoVC!.moleMeasurements = self.originalMoleMeasurements
                self.present(mmPhotoVC!, animated: true, completion: nil)
            } else if event == .zmCancel {
                if mmPhotoVC != nil {
                    mmPhotoVC!.dismiss(animated: false, completion: nil)
                }
                cleanupAndExit()
            } else if event == .zmNext {
                if mmPhotoVC != nil {
                    mmPhotoVC!.dismiss(animated: true, completion: nil)
                }
                animationDirection = .toLeft
                nextState = .tapCoinInstruction
                
            } else {
                print("Unexpected event in .takingPhoto")
            }
            break
            
        case .tapCoinInstruction:
            if event == .zmGoto {
                instructionVC?.resetInstructions(
                    newShortInstruction: "Tap Coin",
                    newLongInstruction: "Tap on coin image. A sizing circle will be drawn around the it.\n\nYou can FIX sizing circles. \n\nYou can CANCEL accidental taps. \n\nOK accepts the sizing circle.\nYou will be asked to identify the coin.",
                    newOptionalButtonText: "Skip coin step")
                
                if childViewControllers[0] !=  instructionVC {
                    ContainerTransitions.switchToWithAnimation(containerVC: self, fromVC: childViewControllers[0], toVC: instructionVC!, direction: animationDirection)
                }
                showCancelNextNavigation()
                self.navigationItem.title = "Tap Coin"
            } else if event == .zmCancel {
                cleanupAndExit()
            } else if event == .zmNext {
                animationDirection = .toLeft
                nextState = .tappingCoin
            } else if event == .zmSkipCoin {
                animationDirection = .toLeft
                nextState = .dragMoleInstruction
            } else {
                print("Unexpected event in .tapCoinInstruction")
            }
            break
            
        case .tappingCoin:
            if event == .zmGoto {
                if tapCoinViewController == nil {
                    tapCoinViewController = TapCoinViewController(image: displayPhoto!, delegate: self)
                }
                showCancelNextNavigation()
                ContainerTransitions.switchToWithAnimation(containerVC: self, fromVC: childViewControllers[0],
                                                           toVC: tapCoinViewController!, direction: animationDirection)
                if coinFixResults == .zmCancelled {
                    tapCoinViewController?.showCircleMenu()
                } else if coinFixResults == .zmFixed {
                    tapCoinViewController?.queryForDenomination()
                }
                coinFixResults = .zmNotFixing

                self.navigationItem.title = "Tap Coin"
            } else if event == .zmCancel {
                cleanupAndExit()
            } else if event == .zmNext {
                animationDirection = .toLeft
                nextState = .dragMoleInstruction
            } else if event == .zmFix {
                animationDirection = .toLeft
                nextState = .fixCoinInstruction
            } else {
                print("Unexpected event in .tappingCoin")
            }
            break
            
        case .fixCoinInstruction:
            if event == .zmGoto {
                instructionVC?.resetInstructions(
                    newShortInstruction: "Fix Coin",
                    newLongInstruction: "Pinch to resize circle\\nnDrag with one finger to move the circle.\n\nUse '+' and '-' buttons to zoom in and out.\n\nUse target button to re-center the image around the circle.",
                    newOptionalButtonText: nil)
                
                if childViewControllers[0] !=  instructionVC {
                    ContainerTransitions.switchToWithAnimation(containerVC: self, fromVC: childViewControllers[0], toVC: instructionVC!, direction: animationDirection)
                }
                showBackNextNavigation()
                self.navigationItem.title = "Fix Coin"
            } else if event == .zmBack {
                animationDirection = .toRight
                coinFixResults = .zmCancelled
                nextState = .tappingCoin
            } else if event == .zmNext {
                animationDirection = .toLeft
                nextState = .fixingCoin
            } else {
                print("Unexpected event in .fixCoinInstruction")
            }
            break
            
        case .fixingCoin:
            if event == .zmGoto {
                fixedObject = FixedRecord(fixedImage: fixableData!.fixableImage,
                                          fixedObjectType: .remeasurementCoinFixed,
                                          originalPosition: fixableData!.fixableCircle,
                                          fixedPosition: nil)
                showCancelDoneNavigation()
                let fixCircleVC = FixCircleViewController(fixableData: fixableData!, delegate: self)
                fixCircleVC.setCircleColor(UXConstants.mmRed)
                ContainerTransitions.switchToWithAnimation(containerVC: self, fromVC: childViewControllers[0], toVC: fixCircleVC, direction: animationDirection)
                self.navigationItem.title = "Fixing Coin"
            } else if event == .zmCancel {
                animationDirection = .toRight
                coinFixResults = .zmCancelled
                nextState = .tappingCoin
            } else if event == .zmDone {
                print("FFFFF       Send fix record for coin if, you know, enrolled")
                if fixedObject != nil && coinBeingFixedPosition != nil {
                    fixedObject?.fixedPosition = coinBeingFixedPosition!
                    fixedObject?.sendFixRecordToBridge()
                }
                coinPosition = coinBeingFixedPosition
                tapCoinViewController!.updateCoin(newPosition: coinBeingFixedPosition!)
                animationDirection = .toRight
                coinFixResults = .zmFixed
                nextState = .tappingCoin
            } else {
                print("Unexpected event in .fixingCoin")
            }
            break
            
        case .dragMoleInstruction:
            if event == .zmGoto {
                let shortInstructions = "Drag Mole Pins"
                let longInstructions = "Drag mole pins to correct placement. A sizing circle will be drawn around the mole.\n\nYou can tap to add new moles.\n\nYou can FIX size and placement. \n\nYou can CANCEL accidental taps. \n\nOK accepts the size and position."
                if childViewControllers[0] ==  instructionVC {
                    let secondaryInstructionVC = InstructionViewController(
                        shortInstruction: shortInstructions,
                        longInstruction: longInstructions,
                        optionalButtonText: nil,
                        delegate: self)
                    ContainerTransitions.switchToWithAnimation(containerVC: self, fromVC: childViewControllers[0],
                                                               toVC: secondaryInstructionVC, direction: animationDirection)
                } else {
                    instructionVC?.resetInstructions(
                        newShortInstruction: shortInstructions,
                        newLongInstruction: longInstructions,
                        newOptionalButtonText: nil)
                    ContainerTransitions.switchToWithAnimation(containerVC: self, fromVC: childViewControllers[0],
                                                               toVC: instructionVC!, direction: animationDirection)
                }
                showCancelNextNavigation()
                self.navigationItem.title = "Position Pins"
            } else if event == .zmCancel {
                cleanupAndExit()
            } else if event == .zmNext {
                // TODO: Save off everything and quit
                animationDirection = .toLeft
                nextState = .draggingMole
            } else {
                print("Unexpected event in .tapMoleInstruction")
            }
            break
            
        case .draggingMole:
            if event == .zmGoto {
                if dragMolesViewController == nil {
                    dragMolesViewController = DragMolesViewController(image: displayPhoto!, dataSource: self, delegate: self)
                }
                ContainerTransitions.switchToWithAnimation(containerVC: self, fromVC: childViewControllers[0],
                                                           toVC: dragMolesViewController!, direction: animationDirection)
                showCancelDoneNavigation()
                self.navigationItem.title = "Position Pins"
            } else if event == .zmCancel {
                cleanupAndExit()
            } else if event == .zmDone {
                saveDataAndExit()
            } else if event == .zmFix {
                animationDirection = .toLeft
                nextState = .fixMoleInstruction
            } else {
                print("Unexpected event in .tappingMole")
            }
            break
            
        case .fixMoleInstruction:
            if event == .zmGoto {
                showBackNextNavigation()
                if childViewControllers[0] ==  instructionVC {
                    let secondaryInstructionVC = InstructionViewController(shortInstruction: "Fix Mole",
                                                                           longInstruction: "Pinch to resize circle\nDrag with one finger to move the circle\nUse '+' and '-' buttons to zoom in and out\nUse target button to re-center the image around the circle",
                                                                           optionalButtonText: nil,
                                                                           delegate: self)
                    ContainerTransitions.switchToWithAnimation(containerVC: self, fromVC: childViewControllers[0],
                                                               toVC: secondaryInstructionVC, direction: animationDirection)
                } else {
                    instructionVC?.resetInstructions(newShortInstruction: "Fix Mole",
                                                     newLongInstruction: "Pinch to resize circle\nDrag with one finger to move the circle\nUse '+' and '-' buttons to zoom in and out\nUse target button to re-center the image around the circle",
                                                     newOptionalButtonText: nil)
                    ContainerTransitions.switchToWithAnimation(containerVC: self, fromVC: childViewControllers[0],
                                                               toVC: instructionVC!, direction: animationDirection)
                }
                self.navigationItem.title = "Fix Mole"
            } else if event == .zmBack {
                animationDirection = .toRight
                nextState = .draggingMole
            } else if event == .zmNext {
                animationDirection = .toLeft
                nextState = .fixingMole
            } else {
                print("Unexpected event in .fixMoleInstruction")
            }
            break
            
        case .fixingMole:
            if event == .zmGoto {
                fixedObject = FixedRecord(fixedImage: fixableData!.fixableImage,
                                          fixedObjectType: .remeasurementMoleFixed,
                                          originalPosition: fixableData!.fixableCircle,
                                          fixedPosition: nil)
                // Saved earlier from tap moles menu call
                showCancelDoneNavigation()
                let fixCircleVC = FixCircleViewController(fixableData: fixableData!, delegate: self)
                ContainerTransitions.switchToWithAnimation(containerVC: self, fromVC: childViewControllers[0], toVC: fixCircleVC, direction: animationDirection)
                self.navigationItem.title = "Fix Mole"
            } else if event == .zmCancel {
                // Undo (flush) cached changes
                animationDirection = .toRight
                nextState = .draggingMole
            } else if event == .zmDone {
                animationDirection = .toRight
                nextState = .draggingMole
                // Save cached changes to local dataset
                guard (dragMolesViewController != nil), (numericIdToPosition[moleBeingFixedID] != nil), (moleBeingFixedPosition != nil)
                    else { break }
                numericIdToPosition[moleBeingFixedID] = moleBeingFixedPosition
                print("RemeasureZVC.transitionState for .fixingMole+.zmDone moleBeingFixedPosition = \(moleBeingFixedPosition?.center)")
//                print("FFFFF       Send fix record for mole if, you know, enrolled")
                if fixedObject != nil && moleBeingFixedPosition != nil {
                    fixedObject?.fixedPosition = moleBeingFixedPosition!
                    fixedObject?.sendFixRecordToBridge()
                }
                dragMolesViewController!.updateMole(moleID: moleBeingFixedID, newPosition: moleBeingFixedPosition!)
            } else {
                print("Unexpected event in .fixingMole")
            }

            break
            
        case .reviewMole:
            if event == .zmGoto {
                showBackShareNavigation()
                self.navigationItem.title = moleToReview!.moleName ?? ""
                reviewMolesVC = ReviewMolesViewController(mole: moleToReview! , delegate: self)
                if childViewControllers.count == 0 {
                    var screenBounds = UIScreen.main.bounds
                    if let vc = self.navigationController {
                        if vc.navigationBar.isTranslucent == false {
                            screenBounds.size.height -= vc.navigationBar.bounds.size.height
                        }
                    }
                    screenBounds.size.height -= UIApplication.shared.statusBarFrame.size.height
                    self.addChildViewController(reviewMolesVC!)
                    reviewMolesVC!.view.frame = screenBounds
                    self.view.addSubview(reviewMolesVC!.view)
                    reviewMolesVC!.didMove(toParentViewController: self)
                } else {
                    if childViewControllers[0] !=  reviewMolesVC {
                        ContainerTransitions.switchToWithAnimation(containerVC: self, fromVC: childViewControllers[0], toVC: reviewMolesVC!, direction: animationDirection)
                    }
                }
                // Saved earlier from tap moles menu call
            } else if event == .zmBack {
                // Undo (flush) cached changes
                animationDirection = .toRight
                nextState = .reviewZone
            } else if event == .zmCancel {
                animationDirection = .toRight
                nextState = .reviewZone
            } else {
                print("Unexpected event in .fixingMole")
            }
            
            break
            
        default:
            fatalError("Encountered event while in undefined state")
            break
        }
        
        if currentState != nextState {
            currentState = nextState
            transitionState(event: .zmGoto)
        }
    }
    
    func handleBack() {
        self.transitionState(event: .zmBack)
    }
    
    func handleDone() {
        self.transitionState(event: .zmDone)
    }
    
    func handleCancel() {
        self.transitionState(event: .zmCancel)
    }
    
    func handleNext() {
        self.transitionState(event: .zmNext)
    }

    func handleShare() {
        if self.reviewMolesVC != nil {
            self.reviewMolesVC!.shareMole()
        }
    }
    
}

// MARK: InstructionViewControllerDelegate handlers

extension RemeasureZoneContainer: InstructionViewControllerDelegate {
    func instructionDidTapNext() {
        self.transitionState(event: .zmNext)
    }
    func instructionDidTapCancel() {
        self.transitionState(event: .zmCancel)
    }
    func instructionDidTapOptionalButton() {
        self.transitionState(event: .zmSkipCoin)
    }
}

// MARK: MoleMapperPhotoControllerDelegate handlers

extension RemeasureZoneContainer:  MoleMapperPhotoControllerDelegate {
    func moleMapperPhotoControllerDidTakePictures(_ jpegData: Data?, displayPhoto: UIImage?, lensPosition: Float) {
        self.jpegData = jpegData
        self.displayPhoto = displayPhoto
        self.lensPosition = lensPosition
        DispatchQueue.main.async {
            self.transitionState(event: .zmNext)
        }
    }
    
    func moleMapperPhotoControllerDidCancel(_ controller: MoleMapperPhotoController) {
        DispatchQueue.main.async {
            self.transitionState(event: .zmCancel)
        }
    }
}

// MARK: ReviewZoneViewDelegate handlers

extension RemeasureZoneContainer: ReviewZoneViewDelegate {
    func remeasureZoneCmd() {
        // Assume we're in the .review state
        if self.currentState == .reviewZone {
            DispatchQueue.main.async {
            self.transitionState(event: .zmNext)    // TODO: maybe add new state here
            }
        }
    }
    
    func displayMoleMenuCmd(forID: Int) {
        let ad = (UIApplication.shared.delegate as? AppDelegate)!
        let mole = numericIdToMole[forID]
        let menu = UIAlertController(title: "Mole Menu", message: mole?.moleName, preferredStyle: .actionSheet)
        
        let actionTimeMachine = UIAlertAction(title: "View history", style: .default,
            handler: {_ in self.onViewHistory(forID) })
        menu.addAction(actionTimeMachine)
        
        let actionRename = UIAlertAction(title: "Rename mole", style: .default,
            handler: {_ in self.onRename(forID) })
        menu.addAction(actionRename)

        let actionDeleted = UIAlertAction(title: "Delete mole", style: .destructive,
            handler: {_ in self.onDeleted(forID) })
        menu.addAction(actionDeleted)

        if ad.user.hasConsented && (mole?.moleWasRemoved ?? true) == false {
            let actionRemoved = UIAlertAction(title: "Mole was removed", style: .destructive,
                handler: {_ in self.onRemoved(forID) })
            menu.addAction(actionRemoved)
        }
        
        let actionCancel = UIAlertAction(title: "Cancel", style: .cancel,
            handler: nil)
        menu.addAction(actionCancel)
        
        self.present(menu, animated: true, completion: nil)
        print("Exited displayMoleMenuCmd")
    }
    
    func onViewHistory(_ moleID: Int) {
        moleToReview = numericIdToMole[moleID]
        currentState = .reviewMole
        transitionState(event: .zmGoto)
    }
    
    func onRename(_ moleID: Int) {
        print("Rename called for \(moleID)")
        let moleToRename = numericIdToMole[moleID]
        let menu = UIAlertController(title: "Rename Mole",
                                     message: nil,
                                     preferredStyle: .alert)
        
        let actionSave = UIAlertAction(title: "Save", style: .default,
                                       handler:
        { _ in
            // Save to database
            let newMoleName = menu.textFields?[0].text ?? ""
            moleToRename!.moleName = newMoleName
            V30StackFactory.createV30Stack().saveContext()
            // Update pin
            if self.reviewZoneVC != nil {
                self.reviewZoneVC?.updatePinMoleName(newName: newMoleName, forID: moleID)
            }
        })
        let actionDiscard = UIAlertAction(title: "Cancel", style: .destructive, handler: nil)
        menu.addAction(actionDiscard)
        menu.addAction(actionSave)
        menu.addTextField { (textField) in
            textField.text = moleToRename?.moleName
        }
        
        self.present(menu, animated: true, completion: nil)
    }
    
    func onDeleted(_ moleID: Int) {
        print("Deleted called for \(moleID)")
        // modally show an alert which warns the user of the consequences of
        // deleting a mole.
        let menu = UIAlertController(title: "Delete Mole",
                                     message: "WARNING: this action cannot be undone. All pictures and data for this mole will be permanently deleted.",
                                     preferredStyle: .alert)
        
        let actionKeep = UIAlertAction(title: "Keep mole", style: .default,
                                         handler: nil)
        let actionDelete = UIAlertAction(title: "Permanently delete", style: .destructive, handler:
        { _ in
            self.deleteMole(moleID)
        })
        menu.addAction(actionKeep)
        menu.addAction(actionDelete)
        
        self.present(menu, animated: true, completion: nil)
    }

    func deleteMole(_ moleID:Int) {
        if let mole = self.numericIdToMole[moleID] {
            print("Deleting all data associated with \(mole.moleName.debugDescription ?? "no name for mole")")
            
            // Remove pin
            self.reviewZoneVC?.removePin(forID: moleID)
            
            // Remove from cached lists
            var measurementToRemove: MoleMeasurement30? = nil
            for measurement in self.originalMoleMeasurements {
                if measurement.whichMole == mole {
                    measurementToRemove = measurement
                    break
                }
            }
            guard measurementToRemove != nil else {return}
            if let index = self.originalMoleMeasurements.index(of: measurementToRemove!) {
                self.originalMoleMeasurements.remove(at: index)
            }
            self.numericIdToMole.removeValue(forKey: moleID)
            self.numericIdToPosition.removeValue(forKey: moleID)
            //
            print("Temporary mole IDs after delete")
            for key in numericIdToMole.keys {
                print("\(key)")
            }

            // Delete measurements
            // -- Now done through delete integrity constraints when mole is deleted
            // Delete mole
            let stack = V30StackFactory.createV30Stack()
            stack.managedContext.delete(mole)
            stack.saveContext()
        }
    }
    
    func onRemoved(_ moleID: Int) {
        print("Removed called for \(moleID)")
        removedSurvey = MoleWasRemovedRKModule()
        if removedSurvey != nil {
            let mole = numericIdToMole[moleID]
            removedSurvey!.presentingVC = self
            removedSurvey!.removedMole = mole
            removedSurvey!.showMoleRemoved()
            // The saving of the mole removed state has been moved to the MoleWasRemovedRKModule
//            mole?.moleWasRemoved = true
//            V30StackFactory.createV30Stack().saveContext()
            // This may introduce a temporary bug: if the user aborts the showMoleRemoved survey
            // the pin will still show up semi-transparent until the next time the zone view is loaded.
            // This is because the RK survey is asynchronous to this call
            reviewZoneVC?.changePinType(forID: moleID, newType: .removedReviewPin)
        }
        print("Exited onRemoved")
    }
    
    func debugDumpMoleInfo(_ moleID: Int) {
        if let mole = numericIdToMole[moleID] {
            let zoneID = mole.whichZone!.zoneID
            print(mole.moleName.debugDescription)
            print("For Zone: \(zoneID.debugDescription)")
            print("Measurements in whichMeasurements set:")
            for case let measurement as MoleMeasurement30 in mole.moleMeasurements! {
                print("ID: \(measurement.moleMeasurementID.debugDescription)")
            }
            print("Measurements returned by allMeasurementsSorted()")
            for measurement in mole.allMeasurementsSorted() {
                print("ID: \(measurement.moleMeasurementID.debugDescription)")
            }
        }
        
        
    }
}

// MARK: TapCoinViewDelegate handlers

extension RemeasureZoneContainer: TapCoinViewDelegate {
    func positionCoin(position: CirclePosition) {
        coinPosition = position
    }
    
    func setCoinType(toType: USCoin) {
        coinType = toType
        transitionState(event: .zmNext)
    }
    
    func removeCoin() {
        coinType = nil
        coinPosition = nil
    }
    
    func fixCoin() {
        if (coinPosition != nil) {
            fixableData = FixableData(fixableImage: displayPhoto!, fixableCircle: coinPosition!)
            coinBeingFixedPosition = coinPosition!
            transitionState(event: .zmFix)
        }
    }
}

// MARK: FixableDelegate handlers

extension RemeasureZoneContainer: FixCircleDelegate {
    func updateObject(objectPosition: CirclePosition) {
        print("FFF     Fix update")
        print("RemeasureZoneContainer: FixCircleDelegate updateObject's objectPosition = \(objectPosition.center)")
        if currentState == .fixingMole {
            moleBeingFixedPosition = objectPosition
        } else if currentState == .fixingCoin {
            coinBeingFixedPosition = objectPosition
        } else {
            print("*** Unexpected updateObject")
        }
    }    
}

//func updateMoleMeasurement(_ temporaryID: Int, withPosition: CirclePosition)
//// Tell container to create new mole (or placeholder)
//func addNewMoleMeasurement(position: CirclePosition) -> Int
//// Undo the earlier add
//func removeNewMoleMeasurement(_ temporaryID: Int)
//// Tell container to fix the mole's position
//func fixMole(_ withNumericID: Int)

extension RemeasureZoneContainer: DragMolesUpdateDelegate {
    func updateMoleMeasurement(_ temporaryID: Int, withPosition: CirclePosition) {
        numericIdToPosition[temporaryID] = withPosition
        print("RemeasureZVC:DragMolesUpdateDelegate updateMoleMeasurement withPosition = \(withPosition.center)")
    }

    func addNewMoleMeasurement(position: CirclePosition) -> Int {
//        numericIdToMole[temporaryID] = forMole
        lastID += 1
        numericIdToPosition[lastID] = position
        return lastID
    }
    
    func removeNewMoleMeasurement(_ temporaryID: Int) {
        numericIdToPosition.removeValue(forKey: temporaryID)
    }

    func fixMole(_ withNumericID: Int) {
        if let molePosition = numericIdToPosition[withNumericID] {
            print("RemeasureZVC:DragMolesUpdateDelegate fixMole molePosition = \(molePosition.center)")
            // Save off mole to be fixed for when state machine gets to it
            moleBeingFixedID = withNumericID
            moleBeingFixedPosition = molePosition
            fixableData = FixableData(fixableImage: displayPhoto!, fixableCircle: molePosition)
            transitionState(event: .zmFix)
        }
    }
}

extension RemeasureZoneContainer: DragMolesDataSource {
    var initialMeasurementPositions: [Int:CirclePosition] { return numericIdToPosition }
}

extension RemeasureZoneContainer:  ReviewMolesDelegate {
    func shareMoleMeasurement(moleMeasurement: MoleMeasurement30) {
        // TODO implement sharing
    }
}

