//
//  TakePhotoViewController.swift
//  MoleMapper
//
// Copyright (c) 2018 OHSU. All rights reserved.
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
import CoreMotion

protocol TakePhotoControllerDelegate {
    func didTakePicture(jpegData: Data?, displayPhoto: UIImage?, lensPosition: Float, gravityData: TakePhoto.GravityData?)
    func didCancel(controller: TakePhotoViewController)
}

protocol TakePhotoDisplayLogic: class {
    func drawPins(viewModel: TakePhoto.Pins.ViewModel)
    func displayHelp(viewModel: PopupHelp.Help.ViewModel)
    func displayNoHelp()
    func displayHint()
    func displayNotAuthorised(viewModel: TakePhoto.SetupFailed.ViewModel)
    func displayConfigurationFailed(viewModel: TakePhoto.SetupFailed.ViewModel)
}

protocol TakePhotoObserversLogic {
    func addObservers(videoDevice: AVCaptureDevice?)
    func removeObservers(videoDevice: AVCaptureDevice?)
    func sessionInterruptionEnded(notification: NSNotification)
    func sessionWasInterrupted(notification: NSNotification)
    func sessionRuntimeError(notification: NSNotification)
}

@objc public class TakePhotoViewController: UIViewController, UIGestureRecognizerDelegate {

    @IBOutlet weak var helpButton: UIButton!
    @IBOutlet weak var takePhotoView: TakePhotoView?
    
    var inProgressPhotoCaptureDelegate: TakePhotoCaptureDelegate?
    var isSessionRunning = false
    var lastLensPosition: Float = -1.0
    var helpText: NSAttributedString?
    var helpTitle: String?
    var lastMotionData: CMAcceleration?
    var letUserApprovePhoto = true
    var molesData: ShowZone.MolesData?
    var motionManager: CMMotionManager?
    var showTorch = true
    var snappedGravityData: TakePhoto.GravityData?
    var snappedLensPosition: Float = -1.0

    let session = AVCaptureSession()
    let sessionQueue = DispatchQueue(label: "edu.ohsu.molemapper.photoQ", attributes: [], target: nil)

    private var photoOutput: AVCapturePhotoOutput?
    private var setupResult: TakePhotoSetupResult = .success
    private var videoDeviceInput: AVCaptureDeviceInput!
    
    var interactor: TakePhotoBusinessLogic?
    var router: TakePhotoRoutingLogic?

    // MARK: View Controller Life Cycle
    
    convenience init(molesData: ShowZone.MolesData? = nil, showTorch: Bool, letUserApprovePhoto: Bool = true) {
        self.init(nibName: "TakePhotoView", bundle: nil)
        
        self.showTorch = showTorch
        self.molesData = molesData
        self.letUserApprovePhoto = letUserApprovePhoto
        
        setup()
    }
    
    override public func loadView() {
        super.loadView()
        
        self.motionManager = CMMotionManager()
    }
    
    private func setup() {
        let viewController = self
        let interactor = TakePhotoInteractor()
        let presenter = TakePhotoPresenter()
        let router = TakePhotoRouter()
        viewController.interactor = interactor
        viewController.router = router
        interactor.presenter = presenter
        presenter.viewController = viewController
        router.viewController = viewController
    }
    
    override public var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        if let moleMeasurements = molesData?.originalMoleMeasurements {
            interactor?.canUpdatePins = moleMeasurements.count > 0
            interactor?.measurementType = .remeasurement
        } else {
            interactor?.canUpdatePins = false
            interactor?.measurementType = .newmeasurement
        }
        
        let cameraAuthorizationStatus = CameraUtils.checkCameraAuthorization()
        if cameraAuthorizationStatus == .notDetermined {
            CameraUtils.requestCameraAuthorization({ (success) in
                if success {
                    DispatchQueue.main.async { [unowned self] in
                        self.configureCaptureSession()
                        self.configurePreviewAndObservers()
                    }
                } else {
                    self.setupResult = .notAuthorized
                }
            })
        }else if cameraAuthorizationStatus == .authorized {
            self.configureCaptureSession()
        }else{
            self.setupResult = .notAuthorized
        }
        
        helpButton.mmHelpify()
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Show help screen...eventually make conditional
        invokeHelp(self)  // Let interactor decide whether to show or not
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let cameraAuthorizationStatus = CameraUtils.checkCameraAuthorization()
        if cameraAuthorizationStatus == .authorized {
            configurePreviewAndObservers()
        }
        
        navigationController?.setNavigationBarHidden(true, animated: true)
        
        if let activeMotionManager = motionManager {
            if activeMotionManager.isAccelerometerAvailable {
                activeMotionManager.startDeviceMotionUpdates()
                activeMotionManager.startAccelerometerUpdates()
            }
        }
    }
    
    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        cleanupPreviewAndObservers()
        navigationController?.setNavigationBarHidden(false, animated: false)
        
        if let activeMotionManager = motionManager {
            if activeMotionManager.isAccelerometerAvailable {
                activeMotionManager.stopDeviceMotionUpdates()
                activeMotionManager.stopAccelerometerUpdates()
            }
        }
    }
    
    func waitAndDisplayHint() {
        HintUtils.delay(milliseconds: HintUtils.defaultDelayMilliseconds) { [weak self] in
            self?.interactor?.requestHint()
        }
    }

 
    // MARK: Button responders
    
    @IBAction func invokeHelp(_ sender: Any) {
        var request : PopupHelp.Help.Request?
        if sender is UIButton {
            request = PopupHelp.Help.Request(.userRequest)
        } else {
            request = PopupHelp.Help.Request(.autoPopup)
        }
        interactor?.requestHelp(request: request!)
    }
    
    @IBAction func onBack() {
        self.router?.navigateBack()
    }

    // MARK: Preview and take photo Configuration/Cleanup
    
    fileprivate func addPinsToPreview() {
        let hiresDimensions = self.videoDeviceInput.device.activeFormat.highResolutionStillImageDimensions
        DispatchQueue.main.async {
            self.interactor!.updatePins(dimensions: CGSize(width: CGFloat(hiresDimensions.width), height: CGFloat(hiresDimensions.height)))
        }
    }
    
    fileprivate func configureCaptureSession() {
        self.takePhotoView!.session = self.session
        
        self.sessionQueue.async { [weak self] in
            // Get video input for the default camera.
            let videoCaptureDevice = CameraUtils.defaultDevice()
            guard let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice) else {
                print("Unable to obtain video input for default camera.")
                self?.setupResult = .configurationFailed
                return
            }
            
            // Create and configure the photo output.
            let capturePhotoOutput = AVCapturePhotoOutput()
            capturePhotoOutput.isHighResolutionCaptureEnabled = true
            capturePhotoOutput.isLivePhotoCaptureEnabled = false
            
            guard self?.session.canAddOutput(capturePhotoOutput) ?? false && self?.session.canAddInput(videoInput) ?? false else {
                print("Unable to add input and output mechanisms for the session.")
                self?.setupResult = .configurationFailed
                return
            }
            
            // Configure the session.
            self?.session.beginConfiguration()
            self?.session.sessionPreset = AVCaptureSession.Preset.photo
            self?.session.addInput(videoInput)
            self?.session.addOutput(capturePhotoOutput)
            self?.session.commitConfiguration()
            
            // set session members.
            self?.videoDeviceInput = videoInput
            self?.photoOutput = capturePhotoOutput
            DispatchQueue.main.async {
                self?.takePhotoView!.videoPreviewLayer.connection!.videoOrientation = .portrait
            }
        }
    }

    fileprivate func configureTorchAndExposure() throws {
        if let device = self.videoDeviceInput?.device {
            if device.hasTorch  && self.showTorch {
                try device.lockForConfiguration()
                if device.isExposureModeSupported(.continuousAutoExposure) {
                    device.exposureMode = .continuousAutoExposure
                }
                
                device.torchMode = .on
                device.unlockForConfiguration()
            }
        }
    }
    
    fileprivate func cleanupPreviewAndObservers() {
        sessionQueue.async { [weak self] in
            if self?.setupResult == .success {
                self?.removeObservers(videoDevice: self!.videoDeviceInput.device)
                self?.session.stopRunning()
                self?.isSessionRunning = self!.session.isRunning
            }
        }
    }
    
    fileprivate func configurePreviewAndObservers() {
        sessionQueue.async { [weak self] in
            switch self!.setupResult {
            case .success:
                // Only setup observers and start the session running if setup succeeded.
                self?.addObservers(videoDevice: self?.videoDeviceInput?.device)
                self?.session.startRunning()
                self?.isSessionRunning = self!.session.isRunning
                do {
                   try self?.configureTorchAndExposure()
                } catch {
                    print(error.localizedDescription)
                }
                
            case .notAuthorized:
                self?.interactor?.configureNotAuthorized()
            case .configurationFailed:
                self?.interactor?.configureConfigutationFailed()
            }
            
            self?.addPinsToPreview()
        }
    }

    // MARK: Camera Actions
    fileprivate func capturePhoto() {
        /*
         Retrieve the video preview layer's video orientation on the main queue before
         entering the session queue. We do this to ensure UI elements are accessed on
         the main thread and session configuration is done on the session queue.
         */
        guard self.inProgressPhotoCaptureDelegate == nil else {
            print("exiting capturePhoto because we're already in progress")
            return
        }
        
        sessionQueue.async {
            // Update the photo output's connection to match the video orientation of the video preview layer.
            if let photoOutputConnection = self.photoOutput?.connection(with: AVMediaType.video) {
                if photoOutputConnection.isVideoOrientationSupported {
                    // try to force portrait.
                    photoOutputConnection.videoOrientation = .portrait
                } else {
                    print("Video orientation is not supported")
                }
            }
            
            let photoSettings = AVCapturePhotoSettings()
            photoSettings.isHighResolutionPhotoEnabled = true
            
            // standard image is far too large, we scale it down to fit correctly and use the preview view.
            if photoSettings.availablePreviewPhotoPixelFormatTypes.count > 0 {
                photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String : photoSettings.availablePreviewPhotoPixelFormatTypes.first!,
                                                    kCVPixelBufferWidthKey as String : UIScreen.main.bounds.height,
                                                    kCVPixelBufferHeightKey as String : UIScreen.main.bounds.width
                ]
            }
            
            // Use a separate object for the photo capture delegate to isolate each capture life cycle.
            let photoCaptureDelegate = TakePhotoCaptureDelegate(completed: { [unowned self] photoCaptureDelegate in
                
                self.snappedLensPosition = self.lastLensPosition
                
                if let gravityData = self.lastMotionData {
                    self.snappedGravityData = TakePhoto.GravityData(xPosition: gravityData.x, yPosition: gravityData.y, zPosition: gravityData.z)
                }
                else {
                    print("could not retrieve gravity data.")
                }
                
                // Animation should occur _after_ the focus + snapshot
                DispatchQueue.main.async { [unowned self] in
                    self.takePhotoView!.videoPreviewLayer.opacity = 0
                    UIView.animate(withDuration: 0.25) { [weak self] in
                        self?.takePhotoView!.videoPreviewLayer.opacity = 1
                    }
                    
                    self.didTakePicture(jpegData: photoCaptureDelegate.photoData, displayPhoto: photoCaptureDelegate.displayImage, lensPosition: self.snappedLensPosition, gravityData: self.snappedGravityData)
                    
                    self.inProgressPhotoCaptureDelegate = nil
                }
            })
            
            /*
             The Photo Output keeps a weak reference to the photo capture delegate so
             we maintain a strong reference to this object until the capture is completed, it will then be removed.
             */
            self.inProgressPhotoCaptureDelegate = photoCaptureDelegate
            self.photoOutput?.capturePhoto(with: photoSettings, delegate: photoCaptureDelegate)
        }
    }

    @IBAction func changeCamera() {
        
        sessionQueue.async { [weak self] in
            let currentVideoDevice = self?.videoDeviceInput.device
            let newPosition = currentVideoDevice!.position == AVCaptureDevice.Position.back ? AVCaptureDevice.Position.front : AVCaptureDevice.Position.back
            let newVideoDevice = CameraUtils.defaultDevice(position: newPosition)

            do {
                let newVideoDeviceInput = try AVCaptureDeviceInput(device: newVideoDevice)
                self?.session.beginConfiguration()
                
                // it's not possible to check if an input can be added while one exists on the session.
                self?.session.removeInput((self?.videoDeviceInput)!)
                if self?.session.canAddInput(newVideoDeviceInput) ?? false {
                    self?.removeObservers(videoDevice: currentVideoDevice!)
                    self?.addObservers(videoDevice: newVideoDeviceInput.device)
                    self?.session.addInput(newVideoDeviceInput)
                    self?.videoDeviceInput = newVideoDeviceInput
                    
                    self?.takePhotoView!.videoPreviewLayer.connection!.videoOrientation = .portrait
                    self?.addPinsToPreview()
                }
                else {
                    self?.session.addInput(self!.videoDeviceInput)
                }
                
                self?.session.commitConfiguration()
                try self?.configureTorchAndExposure()
            }
            catch {
                print("Error occured while creating video device input: \(error)")
            }
        }
    }

    @IBAction public func focusAndExposeTap() {
        // Try adding slight delay to "debounce" the phone after user taps to improve focus, esp. on SE devices
        // I've exhaustively looked into a better mechanism and it seems like we're stuck for now.
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .milliseconds(350)) {
            self.capturePhoto()
        }
    }
    
}

extension TakePhotoViewController:  TakePhotoControllerDelegate {
    func didTakePicture(jpegData: Data?, displayPhoto: UIImage?, lensPosition: Float, gravityData: TakePhoto.GravityData?) {
        
        router?.jpegData = jpegData
        router?.displayPhoto = displayPhoto
        router?.lensPosition = lensPosition
        router?.gravityData = gravityData
        router?.molesData = self.molesData
        
        if self.letUserApprovePhoto {
            router?.navigateToReviewPhoto()
        } else {
            // TODO: Do we want this to be an option - it seems like approval would always be needed when taking photos.
        }
    }
    
    func didCancel(controller: TakePhotoViewController) {
        
        router?.navigateBack()
    }
}

extension TakePhotoViewController: TakePhotoDisplayLogic {
    func displayHelp(viewModel: PopupHelp.Help.ViewModel)
    {
        self.helpText = viewModel.helpText
        self.helpTitle = viewModel.helpTitle
        
        let vc = PopupHelpViewController.getInstance()
        vc.delegate = self
        DispatchQueue.main.async {
            vc.displayHelpPopup(self) {[unowned self] in
                self.waitAndDisplayHint()
            }
        }
    }
    
    func displayHint() {
        DispatchQueue.main.async {[unowned self] in
            self.showToast("Tap anywhere to take a picture", delegate: self)
        }
       
    }
    
    func displayNoHelp() {
        // fire of wait for event
        waitAndDisplayHint()
    }
    
    
    // Note: can't use IdentifySharedWorker methods because this code doesn't use a scrollView
    // and it might muck up the globals in that module
    func getMargins(photoSize: CGSize) -> (verticalMargin: CGFloat, horizontalMargin: CGFloat) {
        // Presumes takePhotoView contentMode == aspectFit
        let viewBounds = takePhotoView!.bounds.size
        
        let imageWidthToHeightRatio = photoSize.width / photoSize.height
        let viewWidthToHeightRatio = viewBounds.width / viewBounds.height
        
        var verticalMargin: CGFloat = 0
        var horizontalMargin: CGFloat = 0
        if viewWidthToHeightRatio < imageWidthToHeightRatio {
            // Calculate height from scaled width
            let scale = viewBounds.width / photoSize.width
            let scaledHeight = scale * photoSize.height
            verticalMargin = (viewBounds.height - scaledHeight) / 2.0
        }
        else {
            // Calculate width from scaled height
            let scale = viewBounds.height / photoSize.height
            let scaledWidth = scale * photoSize.width
            horizontalMargin = (viewBounds.height - scaledWidth) / 2.0
        }
        return (verticalMargin, horizontalMargin)
    }
    
    func getAspectFitScale(photoSize: CGSize) -> CGFloat {
        let viewBounds = takePhotoView!.bounds.size
        
        let widthRatio = photoSize.width / viewBounds.width
        let heightRatio = photoSize.height / viewBounds.height
        return max(widthRatio,heightRatio)
    }

    
    func drawPins(viewModel: TakePhoto.Pins.ViewModel) {
        if let moleMeasurements = molesData?.originalMoleMeasurements {
            if moleMeasurements.count > 0 {
                
            }
        }
        if let moleMeasurements = molesData?.originalMoleMeasurements {

            if moleMeasurements.count > 0 {
                let scale = getAspectFitScale(photoSize: viewModel.imageSize)
                let margins = getMargins(photoSize: viewModel.imageSize)
                for (objectID, moleMeasurement) in (molesData?.originalMoleMeasurements)! {
                    // location/size relative to small image (this is what's stored in the database)
                    var moleCenter = CGPoint(x: CGFloat(truncating: moleMeasurement.moleMeasurementX!),
                                             y: CGFloat(truncating: moleMeasurement.moleMeasurementY!))
                    var moleRadius = CGFloat(truncating: moleMeasurement.moleMeasurementDiameterInPoints!) / 2.0
                    // convert to position in takePhotoView

                    moleCenter.x *= scale
                    moleCenter.y *= scale
                    moleCenter.x += margins.horizontalMargin
                    moleCenter.y += margins.verticalMargin
                    moleRadius *= scale
                    
                    let imagePosition = WidgetPosition(center: moleCenter,
                                                       radius: moleRadius)

                    if let mole30 = molesData?.numericIdToMole[objectID] {
                        let moleStatus: MoleStatus = .existingConfident
                        let moleWidget = MoleWidget(center: imagePosition.center, radius: imagePosition.radius,
                                                    state: .unselected, status: moleStatus,
                                                    moleName: mole30.moleName ?? "", delegate: self, moleSize: "")
                        moleWidget.isUserInteractionEnabled = false
                        takePhotoView!.addSubview(moleWidget)
                    }
                }
            }
        }
        
        interactor?.canUpdatePins = false
    }
    
    func displayNotAuthorised(viewModel: TakePhoto.SetupFailed.ViewModel) {
        
        DispatchQueue.main.async { [weak self] in
            
            let message = NSLocalizedString(viewModel.message, comment: "")
            let alertController = UIAlertController(title: viewModel.title, message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"), style: .cancel, handler: nil))
            alertController.addAction(UIAlertAction(title: NSLocalizedString("Settings", comment: viewModel.additionalButtonText), style: .`default`, handler: { action in
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
            }))
            
            self?.present(alertController, animated: true, completion: nil)
        }
    }
    
    func displayConfigurationFailed(viewModel: TakePhoto.SetupFailed.ViewModel) {
        DispatchQueue.main.async { [weak self] in
            
            let message = NSLocalizedString("Unable to capture media", comment: "")
            let alertController = UIAlertController(title: "MoleMapper", message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"), style: .cancel, handler: nil))
            
            self?.present(alertController, animated: true, completion: nil)
        }
    }
}

extension TakePhotoViewController: TakePhotoObserversLogic {
    
    func addObservers(videoDevice: AVCaptureDevice?) {
        
        videoDevice?.addObserver(self, forKeyPath: "lensPosition", options: .new, context: nil)
        
        /*
         A session can only run when the app is full screen. It will be interrupted
         in a multi-app layout, introduced in iOS 9, see also the documentation of
         AVCaptureSessionInterruptionReason. Add observers to handle these session
         interruptions and show a preview is paused message. See the documentation
         of AVCaptureSessionWasInterruptedNotification for other interruption reasons.
         */
        NotificationCenter.default.addObserver(self, selector: #selector(sessionRuntimeError), name: Notification.Name("AVCaptureSessionRuntimeErrorNotification"), object: session)
        NotificationCenter.default.addObserver(self, selector: #selector(sessionWasInterrupted), name: Notification.Name("AVCaptureSessionWasInterruptedNotification"), object: session)
        NotificationCenter.default.addObserver(self, selector: #selector(sessionInterruptionEnded), name: Notification.Name("AVCaptureSessionInterruptionEndedNotification"), object: session)
    }
    
    func removeObservers(videoDevice: AVCaptureDevice?) {
        // Removes all the observers (sessionWasInterrupted, sessionInterruptionEnded, sessionRuntimeError)
        NotificationCenter.default.removeObserver(self)
        
        videoDevice?.removeObserver(self, forKeyPath: "lensPosition")
    }
    
    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "lensPosition" {
            if let lensPosition = change?[.newKey] as! Float? {
                self.lastLensPosition = lensPosition
            }
            if motionManager != nil {
                self.lastMotionData =  motionManager!.deviceMotion?.gravity
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    @objc func sessionRuntimeError(notification: NSNotification) {
        guard let errorValue = notification.userInfo?[AVCaptureSessionErrorKey] as? NSError else {
            return
        }
        
        /*
         Automatically try to restart the session running if media services were
         reset and the last start running succeeded. Otherwise, enable the user
         to try to resume the session running.
         */
        let error = AVError(_nsError: errorValue)
        print("Capture session runtime error: \(error)")
        if error.code == .mediaServicesWereReset {
            sessionQueue.async { [weak self] in
                if self?.isSessionRunning ?? false {
                    self?.session.startRunning()
                    self?.isSessionRunning = self?.session.isRunning ?? false
                }
            }
        }
    }
    
    @objc func sessionWasInterrupted(notification: NSNotification) {
        if let userInfoValue = notification.userInfo?[AVCaptureSessionInterruptionReasonKey] as AnyObject?, let reasonIntegerValue = userInfoValue.integerValue, let reason = AVCaptureSession.InterruptionReason(rawValue: reasonIntegerValue) {
            print("Capture session was interrupted with reason \(reason)")
            
            if reason == AVCaptureSession.InterruptionReason.audioDeviceInUseByAnotherClient || reason == AVCaptureSession.InterruptionReason.videoDeviceInUseByAnotherClient {
                // TODO: handle session interruption
            }
        }
    }
    
    @objc func sessionInterruptionEnded(notification: NSNotification) {
        print("Capture session interruption ended")
        // TODO: handle end of session interruption
    }
}

extension TakePhotoViewController : PopupHelpDataSource {
    func getHelpText() -> NSAttributedString {
        let text = self.helpText ?? NSAttributedString(string: "No Data")
        return text
    }
    func getHelpTitle() -> String {
        let text = self.helpTitle ?? "No Title"
        return text
    }
}

// MARK: - make optional in MoleWidget and remove
extension TakePhotoViewController : CircleWidgetDelegate {
    func longPressed(widgetID: Int) {
        // nop
    }
    
    func invokeActionsMenu(widgetID: Int) {
        print(#function + " - not implemented yet (TakePhotoViewController)")
    }
    
    func widgetStartedMoving(widgetID: Int) {
        //
        print(#function + "-- should not get this!!")
    }
    
    func widgetIsMoving(widgetID: Int, newCenter: CGPoint, newSize: CGSize) {
        //
    }
    
    func widgetFinishedMoving(widgetID: Int) {
        //
    }
    
    
}

// MARK: - ToastNotifications
extension TakePhotoViewController : ToastNotifications {
    func passingTouch(point: CGPoint) {
        self.focusAndExposeTap()
    }
}

