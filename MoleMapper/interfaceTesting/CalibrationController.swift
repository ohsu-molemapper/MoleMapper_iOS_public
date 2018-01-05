//
// CalibrationViewContainer.swift
// MoleMapper
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
import AVFoundation

enum CalibrationStates {
    case instructions, coin1, coin2, coin3, review, fixinstructions, fixing
}

struct CalibrationData {
    var fixableData: FixableData
    var lensPosition: Float
    var phonePosition: PhonePosition      // where the camera was relative to
}

@objc class CalibrationBridgePackage: NSObject {
    var dictionary = NSDictionary()
    var photoCloseFileName = "closeCalib.jpg"
    var photoMidFileName = "midCalib.jpg"
    var photoFarFileName = "farCalib.jpg"

    func saveImage(fileName:String, image: UIImage) {
        let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .allDomainsMask, true)[0]
        let fm = FileManager.default
        let FQFN = documents.appending("/" + fileName)
        let jpegData = UIImageJPEGRepresentation(image, 1.0)
        fm.createFile(atPath: FQFN,
                      contents: jpegData,
                      attributes: nil)      // TODO: explicity type this as JPEG?

    }
    
    private func readImageData(_ fileName:String) -> NSData {
        let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .allDomainsMask, true)[0]
        let FQFN = documents.appending("/" + fileName)
        var jpegData = NSData()
        do {
            try jpegData = NSData(contentsOfFile: FQFN)
        } catch let err as NSError {
            print("Error \(err), \(err.userInfo) fetching calibration image data")
        }
        return jpegData
    }
    
    func closeImageData() -> NSData {
        return readImageData(self.photoCloseFileName)
    }

    func midImageData() -> NSData {
        return readImageData(self.photoMidFileName)
    }
    
    func farImageData() -> NSData {
        return readImageData(self.photoFarFileName)
    }
}

@objc class CalibrationController: UINavigationController {
    convenience init() {
        let containerVC = CalibrationContainer()
        self.init(rootViewController: containerVC)
    }
    override func loadView() {
        super.loadView()
        self.navigationBar.isTranslucent = false    // Warning: this changes where subviews start!
    }
}


@objc class CalibrationContainer: UIViewController {

    var currentState: CalibrationStates = .instructions
    var calibrationDataArray = [CalibrationData]()
    var keepAutosizing = true
    var currentPhonePosition: PhonePosition = .close
    var reviewingIndex = 0
    var fixRequester: CalibrationReviewAutosizedView?
    var fixingData: FixableData?
    fileprivate var fixedRecord: FixedRecord?
    
    let concurrentQueue = DispatchQueue(label: "edu.ohsu.molemapper.CalibConcurrent", attributes: .concurrent)

    
    // There are reasons... mostly we need the coinVC initialized right up front
//    var instructionVC: CalibrationInstructionViewController!
    var coinVC: CalibrationCoinViewController!
    var reviewVC: CalibrationCoinReviewController!
    fileprivate var instructionVC: InstructionViewController!
    
    override func loadView() {
        let viewFrame = TranslateUtils.calculateNavigationInnerFrameSize(navigationViewController: self.navigationController)

        view = UIView(frame: viewFrame)
        view.backgroundColor = .darkGray

        self.instructionVC = InstructionViewController(shortInstruction: "Take 3 Pictures",
                                                        longInstruction: "On the next screen, using the red rings as guides, please take three pictures of a penny on a light surface.",
                                                     optionalButtonText: nil,
                                                            delegate: self)
        self.coinVC = CalibrationCoinViewController(withDelegate: self)
        self.coinVC!.showTorch = true
        self.coinVC!.showControls = false
        self.coinVC!.letUserApprovePhoto = false
        self.reviewVC = CalibrationCoinReviewController(delegate: self)
        
        self.addChildViewController(instructionVC!)
        self.view.addSubview(instructionVC!.view)
        instructionVC!.didMove(toParentViewController: self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain,
                                                                target: self, action: #selector(didCancel))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Next", style: .plain,
                                                                 target: self, action: #selector(didNext))
        self.navigationItem.title = "Calibrate Camera"
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        keepAutosizing = false
    }
    
    /**
     sendResultsToBridge packages photos, lensPosition values, and coin segmentation values and sends to Bridge.
    */
    func sendResultsToBridge() {
//        calibrationDataArray
        guard calibrationDataArray.count == 3 else { return }

        let ad = (UIApplication.shared.delegate as? AppDelegate)!
        if ad.user.hasConsented {
        
            let bridgeDictionary = NSMutableDictionary()
            let bridgePackage = CalibrationBridgePackage()

            for calibrationDataItem in calibrationDataArray {
                switch calibrationDataItem.phonePosition {
                case .close:
                    bridgeDictionary["closeLensPosition"] = calibrationDataItem.lensPosition
                    bridgeDictionary["closeCoinX"] = calibrationDataItem.fixableData.fixableCircle.center.x
                    bridgeDictionary["closeCoinY"] = calibrationDataItem.fixableData.fixableCircle.center.y
                    bridgeDictionary["closeCoinRadius"] = calibrationDataItem.fixableData.fixableCircle.radius
                    bridgePackage.saveImage(fileName: bridgePackage.photoCloseFileName, image: calibrationDataItem.fixableData.fixableImage)
                case .midpoint:
                    bridgeDictionary["midLensPosition"] = calibrationDataItem.lensPosition
                    bridgeDictionary["midCoinX"] = calibrationDataItem.fixableData.fixableCircle.center.x
                    bridgeDictionary["midCoinY"] = calibrationDataItem.fixableData.fixableCircle.center.y
                    bridgeDictionary["midCoinRadius"] = calibrationDataItem.fixableData.fixableCircle.radius
                    bridgePackage.saveImage(fileName: bridgePackage.photoMidFileName, image: calibrationDataItem.fixableData.fixableImage)
                case .far:
                    bridgeDictionary["farLensPosition"] = calibrationDataItem.lensPosition
                    bridgeDictionary["farCoinX"] = calibrationDataItem.fixableData.fixableCircle.center.x
                    bridgeDictionary["farCoinY"] = calibrationDataItem.fixableData.fixableCircle.center.y
                    bridgeDictionary["farCoinRadius"] = calibrationDataItem.fixableData.fixableCircle.radius
                    bridgePackage.saveImage(fileName: bridgePackage.photoFarFileName, image: calibrationDataItem.fixableData.fixableImage)
                }
            }
            bridgePackage.dictionary = bridgeDictionary

            if let bridgeManager = ad.bridgeManager {
                // shouldn't be able to even get here if not consented but...just in case
                if ad.user.hasConsented {
                    bridgeManager.signInAndSendCalibrationData(calibrationPackage: bridgePackage)
                }
            }
        }
    }
    
    func calculateRegressionModel() {
        // TODO
    }
    
    // Code to navigate from one view controller to the next
    // Called by contained view controllers
    
    func onFix() {
//        let dataItem = calibrationDataArray[reviewingIndex]
//        let fixInstructionVC = CalibrationFixInstructionViewController(calibrationData: dataItem, controllerDelegate: self)
        let fixInstructionVC = InstructionViewController(shortInstruction: "Fix Coin",
                                                         longInstruction: "Pinch to resize the circle.\\nnDrag with one finger to move the circle.\n\nUse '+' and '-' buttons to zoom in and out.\n\nUse target button to re-center the image around the circle.",
                                                         optionalButtonText: nil,
                                                         delegate: self)
//        self.navigationController?.pushViewController(fixInstructionVC, animated: true)
        ContainerTransitions.switchToWithAnimation(containerVC: self, fromVC: childViewControllers[0], toVC: fixInstructionVC, direction: .toLeft)
    }

    func didCancel() {
        if (currentState == .fixing) || (currentState == .fixinstructions) {
            DispatchQueue.main.async {
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .plain,
                                                                         target: self, action: #selector(self.didNext))
                ContainerTransitions.switchToWithAnimation(containerVC: self, fromVC: self.childViewControllers[0], toVC: self.reviewVC, direction: .toLeft)
                self.reviewingIndex = 0
                self.reviewVC.loadImageData(imageDataSet: self.calibrationDataArray)
                self.currentState = .review
            }
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func didNext() {
        // Code to move "forwards" based on current state
        switch currentState {
        case .instructions:
            // Go to first coin view
            
            ContainerTransitions.switchToWithAnimation(containerVC: self, fromVC: childViewControllers[0], toVC: self.coinVC, direction: .toLeft)
            currentPhonePosition = .close
            DispatchQueue.main.async {
                self.coinVC.changeCoinPosition(phonePosition: .close)
                self.coinVC.changeInstructions(instructions: "Photo 1 of 3: Position your phone so the penny is close to the size of the red circle.\n\nTap on the penny image to auto-focus and take the picture.")
            }
            currentState = .coin1
            break
            
        case .coin1:
            // Go to second coin view
            currentPhonePosition = .midpoint
            // didNext gets called from background thread so dispatch code onto the main thread (or crashes occur)
            DispatchQueue.main.async {
                self.coinVC.changeCoinPosition(phonePosition: .midpoint)
                self.coinVC.changeInstructions(instructions: "Photo 2 of 3: Now position your phone so the penny appears close to the NEW size of the red circle.\n\nTap to take the picture.")
            }
            self.currentState = .coin2
            break
            
        case .coin2:
            // Go to third coin view
            currentPhonePosition = .far
            DispatchQueue.main.async {
                self.coinVC.changeCoinPosition(phonePosition: .far)
                self.coinVC.changeInstructions(instructions: "Photo 3 of 3: Now position your phone one last time so the penny appears close to the size of the red circle.\n\nTap to take the picture.")
            }
            self.currentState = .coin3
            break
            
        case .coin3:
//            stopCaptureSession()
            // TODO: pop up "waiting" spinner if 3 calibration objects haven't appeared yet?
            // Need to first test how long it takes for the auto-size function to complete
            var watchdog = 200
            while (calibrationDataArray.count < 3) && watchdog > 0 {
                watchdog -= 1
                usleep(20000)
            }
            
            if (calibrationDataArray.count < 3) {
                print("Never got 3 completed calibration objects (within timeout). Only got \(calibrationDataArray.count)")
//                self.dismiss(animated: true, completion: nil)
            }
            
            // Go to review
            DispatchQueue.main.async {
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .plain,
                                                                         target: self, action: #selector(self.didNext))
                ContainerTransitions.switchToWithAnimation(containerVC: self, fromVC: self.childViewControllers[0], toVC: self.reviewVC, direction: .toLeft)
                self.reviewingIndex = 0
                self.reviewVC.loadImageData(imageDataSet: self.calibrationDataArray)
                self.currentState = .review
            }
            break
            
        case .review:
            // Accept results and return
            DispatchQueue.main.async {
                self.sendResultsToBridge()
                self.dismiss(animated: true, completion: nil)
            }
            break
            
        case .fixinstructions:
            DispatchQueue.main.async {
                let dataItem = self.calibrationDataArray[self.reviewingIndex]
                self.fixedRecord = FixedRecord(fixedImage: dataItem.fixableData.fixableImage,
                                          fixedObjectType: .calibrationCoinFixed,
                                          originalPosition: dataItem.fixableData.fixableCircle,
                                          fixedPosition: nil)
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .plain,
                                                                         target: self, action: #selector(self.didNext))
                let vc = FixCircleViewController(fixableData: dataItem.fixableData, delegate: self)
                vc.setCircleColor(UXConstants.mmRed)
                ContainerTransitions.switchToWithAnimation(containerVC: self, fromVC: self.childViewControllers[0], toVC: vc, direction: .toLeft)
                self.currentState = .fixing
            }
            break
            
        case .fixing:
            // Done equivalent; go back to review
            self.fixedRecord?.fixedPosition = calibrationDataArray[self.reviewingIndex].fixableData.fixableCircle

            DispatchQueue.main.async {
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .plain,
                                                                         target: self, action: #selector(self.didNext))
                ContainerTransitions.switchToWithAnimation(containerVC: self, fromVC: self.childViewControllers[0], toVC: self.reviewVC, direction: .toLeft)
                //self.reviewingIndex = 0
                //self.reviewVC.loadImageData(imageDataSet: self.calibrationDataArray)
                if self.fixedRecord != nil {
                    self.fixedRecord!.sendFixRecordToBridge()
                }
                self.currentState = .review
            }
            break
        default:
            print("Got a Next in an unexpected state")
            break
        }
    }
    
    func didRequestFix(sender: CalibrationReviewAutosizedView) {
        fixRequester = sender
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Next", style: .plain,
                                                                 target: self, action: #selector(self.didNext))
        if currentState == .review {
            DispatchQueue.main.async {
                let fixInstructionVC = InstructionViewController(shortInstruction: "Fix Coin Size",
                                                             longInstruction: "Pinch to resize the circle.\\nnDrag with one finger to move the circle.\n\nUse '+' and '-' buttons to zoom in and out.\n\nUse target button to re-center the image around the circle.",
                                                             optionalButtonText: nil,
                                                             delegate: self)
                ContainerTransitions.switchToWithAnimation(containerVC: self, fromVC: self.childViewControllers[0], toVC: fixInstructionVC, direction: .toLeft)
                self.currentState = .fixinstructions
            }
        } else {
            print("request for Fix in unexpected state")
        }
    }
    
    /**
        addCoinImage is passed an image captured by the camera and a coin center estimate (relative
        to the current display window) as well as the captured lensPosition value.
    */
    func addCoinImage(coinImage: UIImage, coinCenter: CGPoint, lensPosition: Float, phonePosition: PhonePosition) {
        // Send off to auto-size routine in a background process; in closure, add to calibration data array
        //self.calibrationDataArray.append(calibrationData)
        concurrentQueue.async {
            print("async addCoinImage call with coinCenter at \(coinCenter) and lensPosition of \(lensPosition)")
            if self.keepAutosizing {
                let coinCenterRelativeToImage = TranslateUtils.viewToImageTranslation(coinCenter, imageSize: coinImage.size, parentView: self.coinVC!.view)
                let fixableCircle = CirclePosition(center: coinCenterRelativeToImage, radius: 25)

                let fixableData = FixableData(fixableImage: coinImage,
                                              fixableCircle: fixableCircle)
                let newCirclePosition = AutoEncircle.autoEncircleCoin(fixableData)
              
                // Store circle position relative to image
                fixableData.fixableCircle = newCirclePosition ?? CirclePosition(center: coinCenter, radius: 35)
                let newCalibrationData = CalibrationData(fixableData: fixableData, lensPosition: lensPosition, phonePosition: phonePosition)
                print("current phone position: \(self.currentPhonePosition)")
                self.calibrationDataArray.append(newCalibrationData)
            }
        }
    }

}

extension CalibrationContainer: CalibrationCoinReviewDelegate {
    func updateReviewingIndex(index: Int) {
        reviewingIndex = index
    }
}

extension CalibrationContainer: FixCircleDelegate {
    /**
    updateObject is sent modifications from the fix system.
 
    Parameters:
    - objectPosition: a CirclePosition relative to the image
    */
    func updateObject(objectPosition circlePosition: CirclePosition) {
        calibrationDataArray[self.reviewingIndex].fixableData.fixableCircle = circlePosition
        self.reviewVC.updateCirclePosition(circlePosition: circlePosition, viewIndex: self.reviewingIndex)
//        print("FFF     Fix update")
    }
}


extension CalibrationContainer: InstructionViewControllerDelegate {
    func instructionDidTapNext()
    {
        didNext()
    }
    func instructionDidTapCancel()
    {
        // future capability
    }
    func instructionDidTapOptionalButton()
    {
        // future capability
    }
}

extension CalibrationContainer: MoleMapperPhotoControllerDelegate {
    func moleMapperPhotoControllerDidTakePictures(_ jpegData: Data?, displayPhoto: UIImage?, lensPosition: Float) {
        let coinCenter = coinVC?.getCurrentCoinCenter() ?? CGPoint.zero
//        print("current coinCenter inside moleMapperPhotoControllerDidTakePictures call: \(coinCenter)")
        addCoinImage(coinImage: displayPhoto!, coinCenter: coinCenter, lensPosition: lensPosition, phonePosition:self.currentPhonePosition)
        // TODO: Capture jpegData somewhere!!
        didNext()
    }
    func moleMapperPhotoControllerDidCancel(_ controller: MoleMapperPhotoController) {
        didCancel()
    }
}

extension CalibrationContainer: CalibrationReviewAutosizedViewProtocol {
    func fixCalibrationCoin(sender: CalibrationReviewAutosizedView) {
//        print("CalibrationContainer.fixCalibrationCoin")
        didRequestFix(sender: sender)
    }
}
