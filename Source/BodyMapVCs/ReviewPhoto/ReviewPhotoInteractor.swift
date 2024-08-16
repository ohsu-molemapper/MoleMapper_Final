//
//  ReviewPhotoInteractor.swift
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

protocol ReviewPhotoBusinessLogic
{
    func calculateInitialViewValues(request: ReviewPhoto.InitialValues.Request)
    func calculateNewZoomScale(request: ReviewPhoto.DoubleTapZoom.Request)
    func reCenterLowerView(request: ReviewPhoto.ReCenterLowerView.Request)
    func reCenterUpperView(request: ReviewPhoto.ReCenterUpperView.Request)
    func requestHelp(request: PopupHelp.Help.Request)
    func resizeRectangle(request: ReviewPhoto.ResizeRectangle.Request)
}

class ReviewPhotoInteractor: ReviewPhotoBusinessLogic
{
    var presenter: ReviewPhotoPresentationLogic?
    
    // MARK: AcceptPhotoBusinessLogic
    
    func calculateInitialViewValues(request: ReviewPhoto.InitialValues.Request)
    {
        let response = ReviewPhoto.InitialValues.Response(separatorViewHeight: request.separatorViewHeight, toolbarHeight: request.toolbarHeight, realImageSize: request.realImageSize, lowerScrollSize: request.lowerScrollSize, upperContainerSize: request.upperContainerSize, upperScrollWidth: request.upperScrollWidth, lowerContainerSize: request.lowerContainerSize)
        presenter?.presentInitialValues(response: response)
    }
    
    func calculateNewZoomScale(request: ReviewPhoto.DoubleTapZoom.Request) {
        // While upperImage == displayResolutionImage
        // 1X = 200% and 2X = %400
        // if zoomScale < 1X -> zoomScale = 1X
        // if zoomScale == 1X -> zoomScale = 2x
        // if zoomScale > 1X -> zoomScale = 1X
        let zoom1X = CGFloat(2.0)
        let zoom2X = CGFloat(4.0)
        var newZoomScale:CGFloat
        if request.currentZoomScale == zoom1X {
            newZoomScale = zoom2X
        }else{
            newZoomScale = zoom1X
        }
        let response = ReviewPhoto.DoubleTapZoom.Response(newZoomScale: newZoomScale)
        presenter?.presentNewZoomScale(response: response)
    }
    
    func resizeRectangle(request: ReviewPhoto.ResizeRectangle.Request) {
        let response = ReviewPhoto.ResizeRectangle.Response(originalRectangleSize: request.originalRectangleSize, scrollViewZoomScale: request.scrollViewZoomScale, scrollViewSize: request.scrollViewSize)
        presenter?.presentResizedRectangle(response: response)
    }
    
    func reCenterLowerView(request: ReviewPhoto.ReCenterLowerView.Request) {
        // Verify location
        let realImageWidth = request.scrollViewZoomScale * request.imageSize.width
        var currentX = request.scrollViewContentOffset.x
        var currentY = request.scrollViewContentOffset.y
        let minX = ((request.upperContainerViewSize.width - realImageWidth)/2) - ((request.scrollViewSize.width - request.rectangleViewSize.width)/2)
        if request.scrollViewContentOffset.x < minX {
            currentX = minX
        }
        
        let maxX = request.upperContainerViewSize.width - request.scrollViewSize.width - minX
        if request.scrollViewContentOffset.x > maxX {
            currentX = maxX
        }
        
        let realImageHeight = request.scrollViewZoomScale * request.imageSize.height
        let minY = ((request.upperContainerViewSize.height - realImageHeight)/2) - ((request.scrollViewSize.height - request.rectangleViewSize.height)/2)
        if request.scrollViewContentOffset.y < minY {
            currentY = minY
        }
        
        let maxY = request.upperContainerViewSize.height - request.scrollViewSize.height - minY
        if request.scrollViewContentOffset.y > maxY {
            currentY = maxY
        }
        
        let upperScrollViewContentOffset = CGPoint(x: currentX, y: currentY)
        
        let response = ReviewPhoto.ReCenterLowerView.Response(scrollViewZoomScale: request.scrollViewZoomScale, scrollViewContentOffset: request.scrollViewContentOffset, scrollViewSize: request.scrollViewSize, rectangleViewSize: request.rectangleViewSize, originalRectangleSize: request.originalRectangleSize, lowerScrollViewZoomScale: request.lowerScrollViewZoomScale, upperScrollViewContentOffset: upperScrollViewContentOffset)
        presenter?.reCenterLowerView(response: response)
    }
    
    func reCenterUpperView(request: ReviewPhoto.ReCenterUpperView.Request) {
        // Verify location
        let realImageWidth = request.scrollViewZoomScale * request.imageSize.width
        
        var currentX = request.scrollViewContentOffset.x
        var currentY = request.scrollViewContentOffset.y
        
        let minX = (request.lowerContainerViewSize.width - realImageWidth)/2
        if request.scrollViewContentOffset.x < minX {
            currentX = minX
        }
        
        let maxX = request.lowerContainerViewSize.width - request.scrollViewSize.width - minX
        if request.scrollViewContentOffset.x > maxX {
            currentX = maxX
        }
        
        let realImageHeight = request.scrollViewZoomScale * request.imageSize.height
        
        let minY = (request.lowerContainerViewSize.height - realImageHeight)/2
        if request.scrollViewContentOffset.y < minY {
            currentY = minY
        }
        
        let maxY = request.lowerContainerViewSize.height - request.scrollViewSize.height - minY
        if request.scrollViewContentOffset.y > maxY {
            currentY = maxY
        }
        
        let lowerScrollViewContentOffset = CGPoint(x: currentX, y: currentY)
        
        let response = ReviewPhoto.ReCenterUpperView.Response(scrollViewZoomScale: request.scrollViewZoomScale, scrollViewContentOffset: request.scrollViewContentOffset, upperScrollViewSize: request.upperScrollViewSize, originalRectangleSize: request.originalRectangleSize, upperScrollViewZoomScale: request.upperScrollViewZoomScale, rectangleViewSize: request.rectangleViewSize, scrollViewSize: request.scrollViewSize, lowerScrollViewContentOffset: lowerScrollViewContentOffset)
        
        presenter?.reCenterUpperView(response: response)
        
    }
    
    func requestHelp(request: PopupHelp.Help.Request) {
        // As always, defer the "how" to the worker
        var requestCleared = true  // default case unless first time and autoPopup
        if (request.requestType == .autoPopup) {
            if PopupTracker.hasSeen("ReviewPhotoHelp") || UserDefaults.areHelpScreensDisabled {
                requestCleared = false
            }
        }
        if requestCleared {
            let helpData = ReviewPhotoWorker().retrieveHelp()
            let response = PopupHelp.Help.Response(title: helpData.helpTitle, text: helpData.helpText)
            presenter?.presentHelp(response: response)
        }
    }
}
