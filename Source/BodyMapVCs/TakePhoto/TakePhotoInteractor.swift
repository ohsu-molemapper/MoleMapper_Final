//
//  TakePhotoInteractor
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
import UIKit

enum PhotoMeasurementType {
    case newmeasurement
    case remeasurement
}

protocol TakePhotoBusinessLogic
{
    var canUpdatePins: Bool {get set}
    var measurementType: PhotoMeasurementType {get set}
    
    func configureNotAuthorized()
    func configureConfigutationFailed()
    func requestHelp(request: PopupHelp.Help.Request)
    func requestHint()
    func updatePins(dimensions: CGSize)
}

class TakePhotoInteractor: TakePhotoBusinessLogic
{
    var canUpdatePins = true
    var measurementType: PhotoMeasurementType = .newmeasurement
    var presenter: TakePhotoPresentationLogic?
    let worker = TakePhotoWorker()
    
    var userIsActive = false
 
    func configureNotAuthorized() {
        let request = TakePhoto.SetupFailed.Request(setupResult: .notAuthorized)
        let response = worker.retrieveSetupFailedMessage(request: request)
        presenter?.presentNotAuthorized(response: response)
    }
    
    func configureConfigutationFailed() {
        let request = TakePhoto.SetupFailed.Request(setupResult: .configurationFailed)
        let response = worker.retrieveSetupFailedMessage(request: request)
        presenter?.presentConfigurationFailed(response: response)
    }
    
    func requestHelp(request: PopupHelp.Help.Request) {
        // Query worker for content
        var requestCleared = true  // default case unless first time and autoPopup
        if (request.requestType == .autoPopup) {
            if measurementType == .newmeasurement {
                if PopupTracker.hasSeen("TakeNewPhotoHelp") || UserDefaults.areHelpScreensDisabled {
                    requestCleared = false
                }
            } else {
                if PopupTracker.hasSeen("RetakePhotoHelp") || UserDefaults.areHelpScreensDisabled {
                    requestCleared = false
                }
            }
        }
        if requestCleared {
            let helpData = TakePhotoWorker().retrieveHelp(measurementType: self.measurementType)
            let response = PopupHelp.Help.Response(title: helpData.helpTitle, text: helpData.helpText)
            presenter?.presentHelp(response: response)
        }
        else {
            presenter?.presentNoHelp()
        }
    }
    
    func requestHint() {
        if !userIsActive && UserDefaults.areHintsEnabled {
            presenter?.presentHint()
        }
    }
    
    func updatePins(dimensions: CGSize) {
        if (canUpdatePins) {
            let request = TakePhoto.Pins.Request(width: dimensions.width, height: dimensions.height)
            let availableImageSize = worker.calculateImageSize(request: request)
            presenter?.presentPins(response: availableImageSize)
        }
    }
}

