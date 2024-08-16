//
//  TakePhotoPresenter
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

protocol TakePhotoPresentationLogic
{
    func presentPins(response: TakePhoto.Pins.Response)
    func presentConfigurationFailed(response: TakePhoto.SetupFailed.Response)
    func presentHelp(response: PopupHelp.Help.Response)
    func presentHint()
    func presentNoHelp()
    func presentNotAuthorized(response: TakePhoto.SetupFailed.Response)
}

class TakePhotoPresenter: TakePhotoPresentationLogic
{
    weak var viewController: TakePhotoDisplayLogic?
    
    func presentConfigurationFailed(response: TakePhoto.SetupFailed.Response) {
        let viewModel = TakePhoto.SetupFailed.ViewModel(additionalButtonText: response.additionalButtonText, message: response.message, title: response.title)
        viewController?.displayConfigurationFailed(viewModel: viewModel)
    }

    func presentHelp(response: PopupHelp.Help.Response) {
        // Hypothetically, the presenter could tweak the help text (e.g. choose the font, the font size, etc.)
        let model = PopupHelp.Help.ViewModel(title: response.helpTitle, text: response.helpText)
        viewController?.displayHelp(viewModel: model)
    }
    
    func presentHint() {
        viewController!.displayHint()
    }
    
    func presentNoHelp() {
        viewController!.displayNoHelp()
    }

    func presentNotAuthorized(response: TakePhoto.SetupFailed.Response) {
        let viewModel = TakePhoto.SetupFailed.ViewModel(additionalButtonText: response.additionalButtonText, message: response.message, title: response.title)
        viewController?.displayNotAuthorised(viewModel: viewModel)
    }
    
    func presentPins(response: TakePhoto.Pins.Response) {
        let viewModel = TakePhoto.Pins.ViewModel(width: response.availableImageSize.width, height: response.availableImageSize.height)
        viewController?.drawPins(viewModel: viewModel)
    }
}

