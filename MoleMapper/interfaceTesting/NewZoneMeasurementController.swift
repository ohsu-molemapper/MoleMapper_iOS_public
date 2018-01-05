//
//  NewZoneMeasurementController.swift
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

enum ZoneMeasurementState {
    case takePhotoInstruction
    case takingPhoto
    case tapCoinInstruction
    case tappingCoin
    case fixCoinInstruction
    case fixingCoin
    case tapMoleInstruction
    case tappingMole
    case fixMoleInstruction
    case fixingMole
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
enum ZoneMeasurementEvent {
    case zmGoto
    case zmBack
    case zmCancel
    case zmDone
    case zmNext
    case zmFix
    case zmSkipCoin
    case zmUpdateMole
}

enum ZoneMeasurementFixResults {
    case zmFixed
    case zmCancelled
    case zmNotFixing
}
/**
    Wrapper class to embed the Container Controller in a Navigation Controller (for now)
 */
@objc class NewZoneMeasurementController: UINavigationController {
    convenience init(zoneID: String, zoneTitle: String) {
        let containerVC = NewZoneMeasurementContainer()
        containerVC.zoneID = zoneID
        containerVC.zoneTitle = zoneTitle
        
        self.init(rootViewController: containerVC)
    }
    override func loadView() {
        self.navigationBar.isTranslucent = false    // Warning: this changes where subviews start!
        super.loadView()
    }
}

/**
    Main ViewController class for new zone measurements. Handles state and
    the sequencing of other view controllers managing instructions, camera control,
    mole and coin identification, and position fixing.
 */
@objc class NewZoneMeasurementContainer: UIViewController {
    // Orchestrates all the view controllers involved in a new zone measurement.
    // Manages CRUD states of new moles prior to persisting in store

    fileprivate var currentState = ZoneMeasurementState.takePhotoInstruction
    fileprivate var animationDirection = ContainerTransitionDirection.none
    
    fileprivate var instructionVC: InstructionViewController?
    fileprivate var jpegData: Data?
    fileprivate var displayPhoto: UIImage?
    fileprivate var lensPosition: Float = -1.0
    fileprivate var skipCoinStep = false
    fileprivate var mmPhotoVC: MoleMapperPhotoController?
    
    fileprivate var newMoleCache: [Int: CirclePosition] = [:]
    fileprivate var moleBeingFixedID: Int = -1
    fileprivate var moleBeingFixedPosition: CirclePosition?     // Relative to IMAGE
    fileprivate var fixableData: FixableData?
    fileprivate var tapMolesViewController: TapMolesViewControllerEx?
    
    fileprivate var coinPosition: CirclePosition?               // Relative to IMAGE
    fileprivate var coinType: USCoin?
    fileprivate var coinBeingFixedPosition: CirclePosition?     // Relative to IMAGE
    fileprivate var tapCoinViewController: TapCoinViewController?
    fileprivate var zoneMeasurement30: ZoneMeasurement30?
    fileprivate var coinFixResults: ZoneMeasurementFixResults = .zmNotFixing
    fileprivate var fixedObject: FixedRecord?
    
    fileprivate let concurrentQueue = DispatchQueue(label: "edu.ohsu.molemapper.CalibConcurrent", attributes: .concurrent)


    
    // MARK: Properties
    var zoneID: String?
    var zoneTitle: String = "New Zone"

    // MARK: Initialization
    
    override func loadView() {
        // Have to have a base view to add subviews to
        let viewFrame = TranslateUtils.calculateNavigationInnerFrameSize(navigationViewController: self.navigationController)
                
        view = UIView(frame: viewFrame)
        view.backgroundColor = .darkGray

        // TODO: what to use if not using instructions?
        instructionVC = InstructionViewController(shortInstruction: "",
                                                  longInstruction: "",
                                                  optionalButtonText: nil,
                                                  delegate: self)
        currentState = .takePhotoInstruction
        
        self.addChildViewController(instructionVC!)
        self.view.addSubview(instructionVC!.view)
        
        self.navigationItem.title = zoneTitle
    }
    
//    override func viewDidAppear(_ animated: Bool) {
//        instructionVC?.didMove(toParentViewController: self)
//        transitionState(event: .zmGoto)     // kick off state machine
//    }

    override func viewDidLoad() {
        instructionVC?.didMove(toParentViewController: self)
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

    // MARK: View management
    
    /**
        Transition from one viewcontroller to another with a pre-canned animation.
     
        - Parameters:
            - fromVC: ViewController presently being shown
            - toVC: ViewController to display
     
        - Returns: nothing
     
        - Throws: nothing
    */
    
    func cleanupAndExit() {
        // TODO: verify this is actually a good idea...
        // this may all happen automatically
//        if tapMolesViewController != nil {
//            tapMolesViewController = nil
//        }
        self.dismiss(animated: true, completion: nil)
    }

    /**
     saveDataAndExit stores the measurements that are in the displayPhoto frame of reference.
     The objects dictionaryForBridge method is responsible for converting to pixels relative
     to the Bridge-stored JPG image.
    */
    func saveDataAndExit() {
        let ad = (UIApplication.shared.delegate as? AppDelegate)!
        var measurementsToSendToBridge = ad.user.measurementsToSendBridge! // type bridging happens magically
        
        // Get Zone the measurement is for
        let zone30 = Zone30.zoneForZoneID(zoneID!)
        
        // Create Parent Zone Measurement
        let zoneMeasurement30 = ZoneMeasurement30.create()
//        zoneMeasurement30.zoneMeasurementID = NSUUID().uuidString     -- Now done as part of the create call
        zoneMeasurement30.whichZone = zone30
        zoneMeasurement30.date = NSDate()
        // TODO: finish calculating reference diameter
        zoneMeasurement30.referenceDiameterInMillimeters = NSNumber(value: 0.0)
        zoneMeasurement30.lensPosition = NSNumber(value: self.lensPosition)
        var mmPerPixel:Float = 0.0
        if self.coinPosition != nil {
            zoneMeasurement30.referenceX = (coinPosition?.center.x ?? 0)as NSNumber
            zoneMeasurement30.referenceY = (coinPosition?.center.y ?? 0) as NSNumber
            zoneMeasurement30.referenceDiameterInPoints = (coinPosition!.radius * 2) as NSNumber
            if self.coinType != nil {
                zoneMeasurement30.referenceObject = Int16(coinType!.toInt())
                if let mmCoin = TranslateUtils.coinDiametersInMillemeters[self.coinType!.toInt()] {
                    zoneMeasurement30.referenceDiameterInMillimeters = NSNumber(value: mmCoin)
                    mmPerPixel = TranslateUtils.mmPerSomething(diameter: (Float(coinPosition!.radius * 2)), coinDenomiation: coinType!.toInt())
                }
            }
        } else {
            zoneMeasurement30.referenceX = -1.0
            zoneMeasurement30.referenceY = -1.0
            zoneMeasurement30.referenceDiameterInPoints = -1.0
            zoneMeasurement30.referenceObject = 0
        }
        zoneMeasurement30.uploadSuccess = false


        // ******
        // TODO: asynchronize the calls -- Seemingly not necessary: the calls are fast enough as is
        // ******
        zoneMeasurement30.saveFullsizedDataAsJPEG(jpegData: self.jpegData!)
//        filename now implicitly set inside the save calls; the property is what they _are_ named, the method is what they _should_ be named
//        zoneMeasurement30.zoneMeasurementFullsizePhoto = zoneMeasurement30.imageFullPathNameForFullsizedPhoto()
        zoneMeasurement30.saveDisplayDataAsPNG(pngData: UIImagePNGRepresentation(self.displayPhoto!)!)
//        zoneMeasurement30.zoneMeasurementResizedPhoto = zoneMeasurement30.imageFullPathNameForResizedPhoto()
        
        // Read these
        let jpegImage = zoneMeasurement30.fullsizedImage()
        
        // Now generate new MoleMeasurements
        let mng = MoleNameGenerator()
        let moleNameGender = UserDefaults.standard.string(forKey: "moleNameGender")
        for (_, newMole) in newMoleCache {
            let mole30 = Mole30.create()
            mole30.moleName = mng.randomUniqueMoleName(withGenderSpecification: moleNameGender)
            mole30.whichZone = zone30
            
            // Create MoleMeasurement object here
            let moleMeasurement30 = MoleMeasurement30.create()
            moleMeasurement30.whichMole = mole30
            moleMeasurement30.whichZoneMeasurement = zoneMeasurement30
            if (mmPerPixel > 0) {
                moleMeasurement30.calculatedMoleDiameter = NSNumber(value: (Float(newMole.radius) * 2) * mmPerPixel)
                moleMeasurement30.calculatedSizeBasis = 1
            } else {
                moleMeasurement30.calculatedMoleDiameter = -1.0
                moleMeasurement30.calculatedSizeBasis = 0
            }
            moleMeasurement30.date = zoneMeasurement30.date
            moleMeasurement30.moleMeasurementDiameterInPoints = (newMole.radius * 2) as NSNumber
            moleMeasurement30.moleMeasurementX = newMole.center.x as NSNumber
            moleMeasurement30.moleMeasurementY = newMole.center.y as NSNumber

            if jpegImage != nil {
                // Clip image here
                // convert display coordinates to full image coordinates
                // Note: measurement coordinates are in Portrait orientation but the JPEG is in Landscape orientation
                // (and there doesn't seem to be an easy way to "treat" it differently though we could create a new
                // rotated version...but why?)

                let fullsizeCircle = TranslateUtils.translateDisplayCircleToJpegCircle(objectPosition: newMole,
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

    // MARK: State Machine
    
    /**
        This is the bulk of the intelligence for this subsystem. The state machine responds
        to events, modifies the model and possibly the view (ViewControllers) and transitions
        usually to the next state (which often finishes the transtion)
     */
    func transitionState(event: ZoneMeasurementEvent) {
        var nextState = currentState
        switch currentState {
        case .takePhotoInstruction:
            if event == .zmGoto {
                instructionVC?.resetInstructions(newShortInstruction: "Photograph Zone",
                                                 newLongInstruction: "Tap to auto-focus and take a photo. Include a US coin if possible.",
                                                 newOptionalButtonText: nil)
                if childViewControllers[0] !=  instructionVC {
                    ContainerTransitions.switchToWithAnimation(containerVC: self, fromVC: childViewControllers[0], toVC: instructionVC!, direction: animationDirection)
                }
                showCancelNextNavigation()
                self.navigationItem.title = "New Zone"
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
                instructionVC?.resetInstructions(newShortInstruction: "Tap Coin",
                                                 newLongInstruction: "Tap on coin image. A sizing circle will be drawn around the it.\n\nYou can FIX sizing circles. \n\nYou can CANCEL accidental taps. \n\nOK accepts the sizing circle.\nYou will be asked to identify the coin.",
                                                 newOptionalButtonText: "Skip coin step")
                
                self.navigationItem.title = "Tap Coin"
                if childViewControllers[0] !=  instructionVC {
                    ContainerTransitions.switchToWithAnimation(containerVC: self, fromVC: childViewControllers[0], toVC: instructionVC!, direction: animationDirection)
                }
            } else if event == .zmCancel {
                cleanupAndExit()
            } else if event == .zmNext {
                animationDirection = .toLeft
                nextState = .tappingCoin
            } else if event == .zmSkipCoin {
                animationDirection = .toLeft
                nextState = .tapMoleInstruction
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
                self.navigationItem.title = "Tap Coin"
                ContainerTransitions.switchToWithAnimation(containerVC: self, fromVC: childViewControllers[0],
                                                           toVC: tapCoinViewController!, direction: animationDirection)
                if coinFixResults == .zmCancelled {
                    tapCoinViewController?.showCircleMenu()
                } else if coinFixResults == .zmFixed {
                    tapCoinViewController?.queryForDenomination()
                }
                coinFixResults = .zmNotFixing
            } else if event == .zmCancel {
                cleanupAndExit()
            } else if event == .zmNext {
                animationDirection = .toLeft
                nextState = .tapMoleInstruction
            } else if event == .zmFix {
                animationDirection = .toLeft
                nextState = .fixCoinInstruction
            } else {
                print("Unexpected event in .tappingCoin")
            }
            break
            
        case .fixCoinInstruction:
            if event == .zmGoto {
                instructionVC?.resetInstructions(newShortInstruction: "Fix Coin",
                                                 newLongInstruction: "Pinch to resize circle\\nnDrag with one finger to move the circle.\n\nUse '+' and '-' buttons to zoom in and out.\n\nUse target button to re-center the image around the circle.",
                                                 newOptionalButtonText: nil)
                
                showBackNextNavigation()
                self.navigationItem.title = "Fix Coin"
                if childViewControllers[0] !=  instructionVC {
                    ContainerTransitions.switchToWithAnimation(containerVC: self, fromVC: childViewControllers[0], toVC: instructionVC!, direction: animationDirection)
                }
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
                                          fixedObjectType: .measurementCoinFixed,
                                          originalPosition: fixableData!.fixableCircle,
                                          fixedPosition: nil)
                let fixCircleVC = FixCircleViewController(fixableData: fixableData!, delegate: self)
                fixCircleVC.setCircleColor(UXConstants.mmRed)
                showCancelDoneNavigation()
                self.navigationItem.title = "Fix Coin"
                ContainerTransitions.switchToWithAnimation(containerVC: self, fromVC: childViewControllers[0], toVC: fixCircleVC, direction: animationDirection)
            } else if event == .zmCancel {
                animationDirection = .toRight
                coinFixResults = .zmCancelled
                nextState = .tappingCoin
            } else if event == .zmDone {
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
//                print("Unexpected event in .fixingCoin")
            }
            break
            
        case .tapMoleInstruction:
            if event == .zmGoto {
                if childViewControllers[0] ==  instructionVC {
                    let secondaryInstructionVC = InstructionViewController(shortInstruction: "Tap Mole",
                                                     longInstruction: "Tap on mole images. A sizing circle will be drawn around the mole.\n\nYou can FIX sizing circles. \n\nYou can CANCEL accidental taps. \n\nOK accepts the sizing circle.",
                                                     optionalButtonText: nil,
                                                     delegate: self)
                    ContainerTransitions.switchToWithAnimation(containerVC: self, fromVC: childViewControllers[0],
                                                               toVC: secondaryInstructionVC, direction: animationDirection)
                } else {
                    instructionVC?.resetInstructions(newShortInstruction: "Tap Mole",
                                                     newLongInstruction: "Tap on mole images. A sizing circle will be drawn around the mole.\n\nYou can FIX sizing circles. \n\nYou can CANCEL accidental taps. \n\nOK accepts the sizing circle.",
                                                     newOptionalButtonText: nil)
                    ContainerTransitions.switchToWithAnimation(containerVC: self, fromVC: childViewControllers[0],
                                                               toVC: instructionVC!, direction: animationDirection)
                }
                showCancelNextNavigation()
                self.navigationItem.title = "Tap Mole"
            } else if event == .zmCancel {
                cleanupAndExit()
            } else if event == .zmNext {
                // TODO: Save off everything and quit
                animationDirection = .toLeft
                nextState = .tappingMole
            } else {
//                print("Unexpected event in .tapMoleInstruction")
            }
            break
            
        case .tappingMole:
            if event == .zmGoto {
                if tapMolesViewController == nil {
                    tapMolesViewController = TapMolesViewControllerEx(image: displayPhoto!, delegate: self)
                }
                ContainerTransitions.switchToWithAnimation(containerVC: self, fromVC: childViewControllers[0],
                                                           toVC: tapMolesViewController!, direction: animationDirection)
                showCancelDoneNavigation()
                self.navigationItem.title = "Tap Mole"
            } else if event == .zmCancel {
                cleanupAndExit()
            } else if event == .zmDone {
                saveDataAndExit()
            } else if event == .zmFix {
                animationDirection = .toLeft
                nextState = .fixMoleInstruction
            } else {
//                print("Unexpected event in .tappingMole")
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
                nextState = .tappingMole
            } else if event == .zmNext {
                animationDirection = .toLeft
                nextState = .fixingMole
            } else {
//                print("Unexpected event in .fixMoleInstruction")
            }
            break
            
        case .fixingMole:
            if event == .zmGoto {
                // Saved earlier from tap moles menu call
                fixedObject = FixedRecord(fixedImage: fixableData!.fixableImage,
                                          fixedObjectType: .measurementMoleFixed,
                                          originalPosition: fixableData!.fixableCircle,
                                          fixedPosition: nil)
                showCancelDoneNavigation()
                let fixCircleVC = FixCircleViewController(fixableData: fixableData!, delegate: self)
                ContainerTransitions.switchToWithAnimation(containerVC: self, fromVC: childViewControllers[0], toVC: fixCircleVC, direction: animationDirection)
                self.navigationItem.title = "Fix Mole"

            } else if event == .zmCancel {
                // Undo (flush) cached changes
                animationDirection = .toRight
                nextState = .tappingMole
            } else if event == .zmDone {
//                print("FFFFF       Send fix record for mole if, you know, enrolled")
                if fixedObject != nil && moleBeingFixedPosition != nil {
                    fixedObject?.fixedPosition = moleBeingFixedPosition!
                    fixedObject?.sendFixRecordToBridge()
                }
                animationDirection = .toRight
                nextState = .tappingMole
                // Save cached changes to local dataset
                guard (tapMolesViewController != nil), (newMoleCache[moleBeingFixedID] != nil), (moleBeingFixedPosition != nil)
                    else { break }
                newMoleCache[moleBeingFixedID] = moleBeingFixedPosition
                tapMolesViewController!.updateMole(moleID: moleBeingFixedID, newPosition: moleBeingFixedPosition!)
            } else {
//                print("Unexpected event in .fixingMole")
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
        transitionState(event: .zmBack)
    }
    
    func handleDone() {
        transitionState(event: .zmDone)
    }
    
    func handleCancel() {
        transitionState(event: .zmCancel)
    }
    
    func handleNext() {
        transitionState(event: .zmNext)
    }
}

// MARK: InstructionViewControllerDelegate handlers

extension NewZoneMeasurementContainer: InstructionViewControllerDelegate {
    func instructionDidTapNext() {
        transitionState(event: .zmNext)
    }
    func instructionDidTapCancel() {
        transitionState(event: .zmCancel)
    }
    func instructionDidTapOptionalButton() {
        transitionState(event: .zmSkipCoin)
    }
}

// MARK: MoleMapperPhotoControllerDelegate handlers

extension NewZoneMeasurementContainer:  MoleMapperPhotoControllerDelegate {
    func moleMapperPhotoControllerDidTakePictures(_ jpegData: Data?, displayPhoto: UIImage?, lensPosition: Float) {
        self.jpegData = jpegData
        self.displayPhoto = displayPhoto
        self.lensPosition = lensPosition
//        print("NewZoneMeasurementContainer lensPosition = \(lensPosition)")
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


// MARK: TapMolesViewDelegate handlers

extension NewZoneMeasurementContainer: TapMolesViewDelegate {
    /**
    position is relative to image
    */
    func addMole(withID: Int, position: CirclePosition) {
        newMoleCache[withID] = position
    }
    
    func removeMole(withID: Int) {
        newMoleCache.removeValue(forKey: withID)
    }
    
    func fixMole(withID: Int) {
        if let molePosition = newMoleCache[withID] {
            // Save off mole to be fixed for when state machine gets to it
            moleBeingFixedID = withID
            moleBeingFixedPosition = molePosition
            fixableData = FixableData(fixableImage: displayPhoto!, fixableCircle: molePosition)
            transitionState(event: .zmFix)
        }
    }
    
    func tapMolesDidTapDone() {
        handleDone()
    }
    
    func tapMolesDidTapCancel() {
        handleCancel()
    }
}

// MARK: TapCoinViewDelegate handlers

extension NewZoneMeasurementContainer: TapCoinViewDelegate {
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

// MARK: FixCircleDelegate handlers

extension NewZoneMeasurementContainer: FixCircleDelegate {
    /**
    updateObject is a notification from the Fix system that the user has changed the object's size/position.
 
    Parameters:
    - objectPosition: a CirclePosition relative to the captured image
    */
    func updateObject(objectPosition: CirclePosition) {
//        print("FFF     Fix update")
        if currentState == .fixingMole {
            moleBeingFixedPosition = objectPosition
        } else if currentState == .fixingCoin {
            coinBeingFixedPosition = objectPosition
        } else {
            print("*** Unexpected updateObject")
        }
    }
}

