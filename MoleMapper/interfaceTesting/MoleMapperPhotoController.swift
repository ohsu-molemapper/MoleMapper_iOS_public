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
    Inspired by AVCam
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
*/

import UIKit
import AVFoundation
import Photos

// MARK: MoleMapperControllerDelegate protocol

@objc public protocol MoleMapperPhotoControllerDelegate {
    func moleMapperPhotoControllerDidTakePictures(_ jpegData: Data?, displayPhoto: UIImage?, lensPosition: Float)
    func moleMapperPhotoControllerDidCancel(_ controller: MoleMapperPhotoController)
}

@objc public class MoleMapperPhotoController: UIViewController, UIGestureRecognizerDelegate {
    
    static private let queueName = "edu.ohsu.molemapper.photoQ"
    
    private var acceptViewer: AcceptViewController?
    private var acceptingPhotoCaptureDelegateObjectID: Int64 = 0
    private var areaChangedNotification: Bool = false
    private var currentCameraPosition: AVCaptureDevicePosition = AVCaptureDevicePosition.unspecified
    private var inProgressPhotoCaptureDelegate: PhotoCaptureDelegate?
    private var isSessionRunning = false
    private var lastLensPosition: Float = -1.0
    private var snappedLensPosition: Float = -1.0
    private let photoOutput = AVCapturePhotoOutput()
    private var previewView: PreviewView!
    private let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: queueName, attributes: [], target: nil) // Communicate with the session and other session objects on this queue.
    private var setupResult: SessionSetupResult = .success
    private var takePhotoFlag = false
    private let videoDeviceDiscoverySession = AVCaptureDeviceDiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaTypeVideo, position: .unspecified)!
    private var videoDeviceInput: AVCaptureDeviceInput!
    private var pins: [CircleAndPinView] = []
    private var pinsNeedUpdating = true
    
    
    private enum SessionSetupResult {
        case success
        case notAuthorized
        case configurationFailed
    }
    
    // MARK: Properties
    
    var controllerDelegate: MoleMapperPhotoControllerDelegate!
    var showControls = false
    var letUserApprovePhoto = true
    var showTorch = true
    
    var moleMeasurements: [MoleMeasurement30] = []
    
    func getPreviewView() -> PreviewView {
        return self.previewView
    }
    
    // MARK: View Controller Life Cycle
    
    convenience init(withDelegate delegate: MoleMapperPhotoControllerDelegate) {
        self.init(nibName: nil, bundle: nil)
        controllerDelegate = delegate
    }
    
    override public func loadView() {
        self.view = UIView(frame: UIScreen.main.bounds)
        self.view.backgroundColor = .white
        previewView = PreviewView()
        previewView.backgroundColor = .black

        
        var adjustedFrame = TranslateUtils.calculateNavigationInnerFrameSize(navigationViewController: self.navigationController)
        
        if showControls {
            let controlToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 0))
            controlToolbar.sizeToFit()
            controlToolbar.tintColor = .white
            controlToolbar.barTintColor = .black
            adjustedFrame.size.height -= controlToolbar.bounds.height
            controlToolbar.backgroundColor = .black
            controlToolbar.isTranslucent = false
            let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain,
                                               target: controllerDelegate,
                                               action: #selector(MoleMapperPhotoControllerDelegate.moleMapperPhotoControllerDidCancel))

            let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
            let rotateCameraButton = UIBarButtonItem(image: UIImage(named: "flipCamera"), style: .plain,
                                                     target: self, action: #selector(self.changeCamera))

            controlToolbar.setItems([cancelButton, spacer, rotateCameraButton], animated: false)
            controlToolbar.frame.origin.y = UIScreen.main.bounds.height - controlToolbar.frame.height
            self.view.addSubview(controlToolbar)
        }
        self.previewView.frame = adjustedFrame
        self.view.addSubview(self.previewView!)     // adding the previewView layer as a sublayer crashes the app

        if moleMeasurements.count > 0 {
            pinsNeedUpdating = true
        } else {
            pinsNeedUpdating = false
        }
        
        let gestureRecognizer = UITapGestureRecognizer(target: self,
                                                       action: #selector(MoleMapperPhotoController.focusAndExposeTap(gestureRecognizer:)))
        gestureRecognizer.delegate = self
        self.previewView.addGestureRecognizer(gestureRecognizer)
    }
    
    func updatePins(highResolutionImageSize: CMVideoDimensions) {
        if pinsNeedUpdating {
            if pins.count > 0 {
                for pin in pins {
                    pin.removeFromSuperview()
                }
                pins.removeAll()
            }
            var imageSize = UIScreen.main.bounds.size
            // hires dimensions are always landscape, our pins are always relative to portrait.
            // hence the ratio is W/H, NOT H/W
            let ratio = CGFloat(highResolutionImageSize.width) / CGFloat(highResolutionImageSize.height)
            imageSize.height = floor(imageSize.width * ratio)   // width is fixed, height is what varies
            print(previewView.frame.debugDescription)

            for (moleMeasurement) in moleMeasurements {
                let moleCenter = CGPoint(x: CGFloat(moleMeasurement.moleMeasurementX!),
                                         y: CGFloat(moleMeasurement.moleMeasurementY!))
                
                let imagePosition = CirclePosition(center: moleCenter, radius: CGFloat(moleMeasurement.moleMeasurementDiameterInPoints!) / 2.0)
                let viewPosition = TranslateUtils.imageToViewCircleTranslation(imagePosition, imageSize: imageSize, parentView: previewView)
                let newPin = CircleAndPinView(circlePosition: viewPosition, parentView: previewView, delegate: nil,
                                              pinType: CircleAndPinType.cameraPin)
                pins.append(newPin)
                previewView.addSubview(newPin)
            }
//            for pin in pins {
//                let moleCenter = pin.currentPosition().center
//                var imageSize = UIScreen.main.bounds.size
//                // hires dimensions are always landscape, our pins are always relative to portrait.
//                // hence the ratio is W/H, NOT H/W
//                let ratio = CGFloat(highResolutionImageSize.width) / CGFloat(highResolutionImageSize.height)
//                imageSize.height = floor(imageSize.width * ratio)   // width is fixed, height is what varies
//                print(previewView.frame.debugDescription)
////                let moleInImageCenter = TranslateUtils.imageToViewTranslation(moleCenter, imageSize: imageSize, parentView: previewView)
////                pin.moveTo(newMolePosition: moleInImageCenter)
//                let moleInView = TranslateUtils.imageToViewCircleTranslation(pin.currentPosition(), imageSize: imageSize, parentView: previewView)
//                pin.moveToCirclePosition(circlePosition: moleInView)
//            }
            pinsNeedUpdating = false
        }
    }
    
    override public func viewDidLoad() {
		super.viewDidLoad()

        
		// Set up the video preview view.
		previewView.session = session
		
		/*
			Check video authorization status. Video access is required and audio
			access is optional. If audio access is denied, audio is not recorded
			during movie recording.
		*/
		switch AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo) {
            case .authorized:
				// The user has previously granted access to the camera.
				break
			
			case .notDetermined:
				/*
					The user has not yet been presented with the option to grant
					video access. We suspend the session queue to delay session
					setup until the access request has completed.
				
					Note that audio access will be implicitly requested when we
					create an AVCaptureDeviceInput for audio during session setup.
				*/
				sessionQueue.suspend()
				AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo, completionHandler: { [unowned self] granted in
					if !granted {
						self.setupResult = .notAuthorized
					}
					self.sessionQueue.resume()
				})
			
			default:
				// The user has previously denied access.
				setupResult = .notAuthorized
		}
		
		/*
			Setup the capture session.
			In general it is not safe to mutate an AVCaptureSession or any of its
			inputs, outputs, or connections from multiple threads at the same time.
		
			Why not do all of this on the main queue?
			Because AVCaptureSession.startRunning() is a blocking call which can
			take a long time. We dispatch session setup to the sessionQueue so
			that the main queue isn't blocked, which keeps the UI responsive.
		*/
		sessionQueue.async { [unowned self] in
			self.configureSession()
		}
	}
	
	override public func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
        
		sessionQueue.async { [unowned self] in
            switch self.setupResult {
                case .success:
				    // Only setup observers and start the session running if setup succeeded.
                    self.addObservers(videoDevice: self.videoDeviceInput.device)
                    self.session.startRunning()
                    self.isSessionRunning = self.session.isRunning
                    do {
                        if let device = self.videoDeviceInput.device {
                            if device.hasTorch  && self.showTorch {
                                try device.lockForConfiguration()
                                if device.isExposureModeSupported(.continuousAutoExposure) {
                                    device.exposureMode = .continuousAutoExposure
                                }
                                
                                device.torchMode = .on
                                device.unlockForConfiguration()
                            }
                        }
                    } catch {
                        print(error.localizedDescription)
                    }
				
                case .notAuthorized:
                    DispatchQueue.main.async { [unowned self] in
                        let message = NSLocalizedString("MoleMapper doesn't have permission to use the camera, please change privacy settings", comment: "")
                        let alertController = UIAlertController(title: "MoleMapper", message: message, preferredStyle: .alert)
                        alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"), style: .cancel, handler: nil))
                        alertController.addAction(UIAlertAction(title: NSLocalizedString("Settings", comment: "Alert button to open Settings"), style: .`default`, handler: { action in
                            UIApplication.shared.open(URL(string: UIApplicationOpenSettingsURLString)!, options: [:], completionHandler: nil)
                        }))
                        
                        self.present(alertController, animated: true, completion: nil)
                    }
				
                case .configurationFailed:
                    DispatchQueue.main.async { [unowned self] in
                        let message = NSLocalizedString("Unable to capture media", comment: "")
                        let alertController = UIAlertController(title: "MoleMapper", message: message, preferredStyle: .alert)
                        alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"), style: .cancel, handler: nil))
                        
                        self.present(alertController, animated: true, completion: nil)
                    }
			}
		}
	}
	
	override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
		sessionQueue.async { [unowned self] in
			if self.setupResult == .success {
                self.removeObservers(videoDevice: self.videoDeviceInput.device)
				self.session.stopRunning()
				self.isSessionRunning = self.session.isRunning
			}
		}
	}
	
    override public var supportedInterfaceOrientations: UIInterfaceOrientationMask {
		return .portrait
	}
    
    // MARK: Delegate Handlers
	
    func onUsePhoto() {
        if self.acceptViewer != nil {
            self.showTorch = false
            self.acceptViewer?.dismiss(animated: false, completion: {self.acceptViewer = nil})
        }
//        self.sessionQueue.async { [unowned self] in
        self.sessionQueue.async { [] in
            if let photoCaptureDelegate = self.inProgressPhotoCaptureDelegate
            {
                self.controllerDelegate.moleMapperPhotoControllerDidTakePictures(photoCaptureDelegate.photoData,
                                                                             displayPhoto: photoCaptureDelegate.displayImage,
                                                                             lensPosition: self.snappedLensPosition)
            }
            self.inProgressPhotoCaptureDelegate = nil
        }
    }
    
    func onRetake() {
        if self.acceptViewer != nil {
            self.sessionQueue.async { [unowned self] in
                self.inProgressPhotoCaptureDelegate = nil
            }
            self.acceptViewer?.dismiss(animated: true, completion: {self.acceptViewer = nil})
            // Dismissing modal VC returns to us and causes a viewWillAppear call which
            // resets the camera session and observers
        }
    }
    
    
	// MARK: Session Management
	
	
	// Call this on the session queue.
	private func configureSession() {
		if setupResult != .success {
			return
		}
		
		
        var defaultVideoDevice: AVCaptureDevice?
        
        // Choose the back wide-angle camera if available
        if let backCameraDevice = AVCaptureDevice.defaultDevice(withDeviceType: .builtInWideAngleCamera, mediaType: AVMediaTypeVideo, position: .back) {
            // If the back dual camera is not available, default to the back wide angle camera.
            defaultVideoDevice = backCameraDevice
            currentCameraPosition = .back
        }
        else if let frontCameraDevice = AVCaptureDevice.defaultDevice(withDeviceType: .builtInWideAngleCamera, mediaType: AVMediaTypeVideo, position: .front) {
            // In some cases where users break their phones, the back wide angle camera is not available. In this case, we should default to the front wide angle camera.
            defaultVideoDevice = frontCameraDevice
            currentCameraPosition = .front
        }
        
        /*
         We do not create an AVCaptureMovieFileOutput when setting up the session because the
         AVCaptureMovieFileOutput does not support movie recording with AVCaptureSessionPresetPhoto.
         */
        session.beginConfiguration()
        session.sessionPreset = AVCaptureSessionPresetPhoto
		// Add video input.
		do {
			let videoDeviceInput = try AVCaptureDeviceInput(device: defaultVideoDevice)
			
			if session.canAddInput(videoDeviceInput) {
				session.addInput(videoDeviceInput)
				self.videoDeviceInput = videoDeviceInput
                self.previewView.videoPreviewLayer.connection.videoOrientation = .portrait

                let hiresDimensions = defaultVideoDevice!.activeFormat.highResolutionStillImageDimensions
                if self.pinsNeedUpdating {
                    DispatchQueue.main.async {
                        self.updatePins(highResolutionImageSize: hiresDimensions)
                    }
                }
			}
			else {
				print("Could not add video device input to the session")
				setupResult = .configurationFailed
				session.commitConfiguration()
				return
			}
		}
		catch {
			print("Could not create video device input: \(error)")
			setupResult = .configurationFailed
			session.commitConfiguration()
			return
		}
		
		// Add photo output.
		if session.canAddOutput(photoOutput)
		{
			session.addOutput(photoOutput)
            photoOutput.isHighResolutionCaptureEnabled = true
		}
		else {
			print("Could not add photo output to the session")
			setupResult = .configurationFailed
			session.commitConfiguration()
			return
		}
        
		
		session.commitConfiguration()
	}
			
	// MARK: Device Configuration
	
    func changeCamera() {
		
		sessionQueue.async { [unowned self] in
			let currentVideoDevice = self.videoDeviceInput.device
			let currentPosition = currentVideoDevice!.position
			
			let preferredPosition: AVCaptureDevicePosition
			let preferredDeviceType: AVCaptureDeviceType
			
			switch currentPosition {
				case .unspecified, .front:
					preferredPosition = .back
					preferredDeviceType = .builtInWideAngleCamera
				
				case .back:
					preferredPosition = .front
					preferredDeviceType = .builtInWideAngleCamera
			}
			
			let devices = self.videoDeviceDiscoverySession.devices!
			var newVideoDevice: AVCaptureDevice? = nil
			
			// First, look for a device with both the preferred position and device type. Otherwise, look for a device with only the preferred position.
			if let device = devices.filter({ $0.position == preferredPosition && $0.deviceType == preferredDeviceType }).first {
				newVideoDevice = device
			}
			else if let device = devices.filter({ $0.position == preferredPosition }).first {
				newVideoDevice = device
			}

            if let videoDevice = newVideoDevice {
                self.currentCameraPosition = preferredPosition
                do {
					let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
					
					self.session.beginConfiguration()
					
					// Remove the existing device input first, since using the front and back camera simultaneously is not supported.
					self.session.removeInput(self.videoDeviceInput)
					
					if self.session.canAddInput(videoDeviceInput) {
                        self.removeObservers(videoDevice: currentVideoDevice!)
                        self.addObservers(videoDevice: videoDeviceInput.device)
                       
						
						self.session.addInput(videoDeviceInput)
						self.videoDeviceInput = videoDeviceInput
                        
                        let hiresDimensions = videoDevice.activeFormat.highResolutionStillImageDimensions
                        if self.pinsNeedUpdating {
                            DispatchQueue.main.async {
                                self.updatePins(highResolutionImageSize: hiresDimensions)
                            }
                        }
					}
					else {
						self.session.addInput(self.videoDeviceInput);
					}
					
					self.session.commitConfiguration()

                    if let device = self.videoDeviceInput.device {
                        if device.hasTorch  && self.showTorch {
                            try device.lockForConfiguration()
                            device.torchMode = .on
                            device.unlockForConfiguration()
                        }
                    }
				}
				catch {
					print("Error occured while creating video device input: \(error)")
				}
			}
			
		}
	}
	
    // Need to make public so semi-child windows can call back to this on their Tap gestures (need a better way of propagating)
	@objc public func focusAndExposeTap(gestureRecognizer: UITapGestureRecognizer) {
        // Try adding slight delay to "debounce" the phone after user taps to improve focus, esp. on SE devices
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .milliseconds(350)) {
            self.capturePhoto()
        }
	}
	
    // TODO: Remove this function after testing on several devices
	private func focus(with focusMode: AVCaptureFocusMode, exposureMode: AVCaptureExposureMode, at devicePoint: CGPoint, monitorSubjectAreaChange: Bool) {
		sessionQueue.async { [unowned self] in
			if let device = self.videoDeviceInput.device {
				do {
                    print("focus called")
					try device.lockForConfiguration()
					
					/*
						Setting (focus/exposure)PointOfInterest alone does not initiate a (focus/exposure) operation.
						Call set(Focus/Exposure)Mode() to apply the new point of interest.
					*/
					if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(focusMode) {
						device.focusPointOfInterest = devicePoint
						device.focusMode = focusMode
					}
					
					if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(.continuousAutoExposure) {
						device.exposurePointOfInterest = devicePoint
						device.exposureMode = .continuousAutoExposure
					}
					
					device.unlockForConfiguration()
				}
				catch {
					print("Could not lock device for configuration: \(error)")
				}
			}
		}
	}
	
	// MARK: Capturing Photos

	func capturePhoto() {
		/*
			Retrieve the video preview layer's video orientation on the main queue before
			entering the session queue. We do this to ensure UI elements are accessed on
			the main thread and session configuration is done on the session queue.
		*/
        print("capturePhoto")
        if self.inProgressPhotoCaptureDelegate != nil {
            print("exiting capturePhoto because we're already in progress")
            return
        }
		sessionQueue.async {
			// Update the photo output's connection to match the video orientation of the video preview layer.
			if let photoOutputConnection = self.photoOutput.connection(withMediaType: AVMediaTypeVideo) {
                if photoOutputConnection.isVideoOrientationSupported {
                    photoOutputConnection.videoOrientation = .portrait
                } else {
                    print("Video orientation is not supported")
                }
			}
			
			// Capture a JPEG photo with high resolution photo enabled.
			let photoSettings = AVCapturePhotoSettings()
			photoSettings.isHighResolutionPhotoEnabled = true
			if photoSettings.availablePreviewPhotoPixelFormatTypes.count > 0 {
                /*
                    This is whacked. No matter what you tell iOS, it wants to treat all preview images as landscape. So we tell it
                    the landscape numbers that will give us the portrait resizing we want (i.e. flip width and height)
                 */
				photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String : photoSettings.availablePreviewPhotoPixelFormatTypes.first!,
				                                    kCVPixelBufferWidthKey as String : UIScreen.main.bounds.height,
				                                    kCVPixelBufferHeightKey as String : UIScreen.main.bounds.width
                ]
			}

            // Use a separate object for the photo capture delegate to isolate each capture life cycle.
			let photoCaptureDelegate = PhotoCaptureDelegate(with: photoSettings, willCapturePhotoAnimation: {
                    // Pushed until after the capture is complete
				}, completed: { [unowned self] photoCaptureDelegate in
                    print("complete photoCaptureDelegate")
                    self.snappedLensPosition = self.lastLensPosition
                    // Animation should occur _after_ the focus + snapshot
                    DispatchQueue.main.async { [unowned self] in
                        self.previewView.videoPreviewLayer.opacity = 0
                        UIView.animate(withDuration: 0.25) { [unowned self] in
                            self.previewView.videoPreviewLayer.opacity = 1
                        }
                        if self.letUserApprovePhoto {
                            self.acceptingPhotoCaptureDelegateObjectID = photoCaptureDelegate.requestedPhotoSettings.uniqueID
                            // is this being called twice on back-to-back taps?
                            print("Creating an AcceptViewController object")
                            self.acceptViewer = AcceptViewController(with: self, image: photoCaptureDelegate.displayImage!)
                            self.show(self.acceptViewer!, sender: self)
                            // acceptingPhotoCaptureDelegateObjectID set to nil after Accept viewer returns
                        } else {
                            self.controllerDelegate.moleMapperPhotoControllerDidTakePictures(photoCaptureDelegate.photoData,
                                                                                             displayPhoto: photoCaptureDelegate.displayImage,
                                                                                             lensPosition: self.snappedLensPosition)
                            self.inProgressPhotoCaptureDelegate = nil
                        }
                        print("inner dispatch completed")
                    }
            })
			
			/*
				The Photo Output keeps a weak reference to the photo capture delegate so
				we store it in an array to maintain a strong reference to this object
				until the capture is completed.
			*/
//			self.inProgressPhotoCaptureDelegates[photoCaptureDelegate.requestedPhotoSettings.uniqueID] = photoCaptureDelegate
            self.inProgressPhotoCaptureDelegate = photoCaptureDelegate
			self.photoOutput.capturePhoto(with: photoSettings, delegate: photoCaptureDelegate)
		}
	}
		
	// MARK: KVO and Notifications
	
	private var sessionRunningObserveContext = 0
	
    private func addObservers(videoDevice: AVCaptureDevice) {
        
        videoDevice.addObserver(self, forKeyPath: "lensPosition", options: .new, context: nil)
		
		NotificationCenter.default.addObserver(self, selector: #selector(sessionRuntimeError), name: Notification.Name("AVCaptureSessionRuntimeErrorNotification"), object: session)
		
		/*
			A session can only run when the app is full screen. It will be interrupted
			in a multi-app layout, introduced in iOS 9, see also the documentation of
			AVCaptureSessionInterruptionReason. Add observers to handle these session
			interruptions and show a preview is paused message. See the documentation
			of AVCaptureSessionWasInterruptedNotification for other interruption reasons.
		*/
		NotificationCenter.default.addObserver(self, selector: #selector(sessionWasInterrupted), name: Notification.Name("AVCaptureSessionWasInterruptedNotification"), object: session)
		NotificationCenter.default.addObserver(self, selector: #selector(sessionInterruptionEnded), name: Notification.Name("AVCaptureSessionInterruptionEndedNotification"), object: session)
	}
	
	private func removeObservers(videoDevice: AVCaptureDevice) {
		NotificationCenter.default.removeObserver(self)         // Removes all the observers (sessionWasInterrupted, sessionInterruptionEnded, sessionRuntimeError)
		
        videoDevice.removeObserver(self, forKeyPath: "lensPosition")
    }
	
	override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "lensPosition" {
            if let lensPosition = change?[.newKey] as! Float? {
//                print("lensPosition: \(lensPosition)")
                lastLensPosition = lensPosition
            }
        } else {
			super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
		}
	}
	
	func sessionRuntimeError(notification: NSNotification) {
		guard let errorValue = notification.userInfo?[AVCaptureSessionErrorKey] as? NSError else {
			return
		}
		
        let error = AVError(_nsError: errorValue)
		print("Capture session runtime error: \(error)")
		
		/*
			Automatically try to restart the session running if media services were
			reset and the last start running succeeded. Otherwise, enable the user
			to try to resume the session running.
		*/
		if error.code == .mediaServicesWereReset {
			sessionQueue.async { [unowned self] in
				if self.isSessionRunning {
					self.session.startRunning()
					self.isSessionRunning = self.session.isRunning
				}
			}
		}
	}
	
	func sessionWasInterrupted(notification: NSNotification) {
		if let userInfoValue = notification.userInfo?[AVCaptureSessionInterruptionReasonKey] as AnyObject?, let reasonIntegerValue = userInfoValue.integerValue, let reason = AVCaptureSessionInterruptionReason(rawValue: reasonIntegerValue) {
			print("Capture session was interrupted with reason \(reason)")
						
			if reason == AVCaptureSessionInterruptionReason.audioDeviceInUseByAnotherClient || reason == AVCaptureSessionInterruptionReason.videoDeviceInUseByAnotherClient {
                // TODO: handle session interruption
            }
		}
	}
	
	func sessionInterruptionEnded(notification: NSNotification) {
		print("Capture session interruption ended")
		// TODO: handle end of session interruption
	}
}

