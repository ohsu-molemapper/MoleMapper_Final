//
//  TakePhotoRouter
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

protocol TakePhotoRoutingLogic
{
    var displayPhoto: UIImage? {get set}
    var jpegData: Data? {get set}
    var lensPosition: Float {get set}
    var gravityData: TakePhoto.GravityData? {get set}
    var molesData: ShowZone.MolesData? {get set}
    
    func navigateBack()
    func navigateToReviewPhoto()
}

class TakePhotoRouter: TakePhotoRoutingLogic
{
    var displayPhoto: UIImage?
    var jpegData: Data?
    var lensPosition: Float = -1.0
    var molesData: ShowZone.MolesData?
    var gravityData: TakePhoto.GravityData?
    
    weak var viewController: TakePhotoViewController?
    
    func navigateBack() {
        if (self.viewController?.navigationController?.viewControllers.count == 1) {
            self.viewController?.navigationController?.dismiss(animated: true, completion: nil)
        }
        else {
            viewController?.navigationController?.popViewController(animated: true)
        }
    }
    
    func navigateToReviewPhoto() {
        
        let photoData = TakePhoto.PhotoData(displayPhoto: self.displayPhoto!, jpegData: self.jpegData!, lensPosition: self.lensPosition, gravityData: gravityData)
        let reviewPhotoViewController = ReviewPhotoViewController(photoData: photoData)
        reviewPhotoViewController.router?.molesData = molesData
        reviewPhotoViewController.modalPresentationStyle = .overFullScreen
        viewController?.navigationController?.pushViewController(reviewPhotoViewController, animated: true)
    }
}
