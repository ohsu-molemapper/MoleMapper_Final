//
//  ReviewPhotoPresenter.swift
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

protocol ReviewPhotoPresentationLogic
{
    func presentInitialValues(response: ReviewPhoto.InitialValues.Response)
    func presentHelp(response: PopupHelp.Help.Response)
    func presentResizedRectangle(response: ReviewPhoto.ResizeRectangle.Response)
    func presentNewZoomScale(response: ReviewPhoto.DoubleTapZoom.Response)
    func reCenterLowerView(response: ReviewPhoto.ReCenterLowerView.Response)
    func reCenterUpperView(response: ReviewPhoto.ReCenterUpperView.Response)
}

class ReviewPhotoPresenter: ReviewPhotoPresentationLogic
{
    weak var viewController: ReviewPhotoDisplayLogic?
    
    func presentHelp(response: PopupHelp.Help.Response) {
        let model = PopupHelp.Help.ViewModel(title: response.helpTitle, text: response.helpText)
        viewController?.displayHelp(viewModel: model)
    }
    
    func presentInitialValues(response: ReviewPhoto.InitialValues.Response)
    {
        // set separator position:
        // upper sroll view height will be 3/5 of screen and lower scroll view will be 2/5 of screen
        let separatorOriginY = 3*((UIScreen.main.bounds.height-response.separatorViewHeight-UIApplication.shared.statusBarFrame.height-response.toolbarHeight)/5)
        // calculate percentage of width we can show in lower view
        let imageWidthPercent = UIScreen.main.bounds.size.width/response.realImageSize.width
        // set rectangle width
        let rectangleWidth = UIScreen.main.bounds.size.width * imageWidthPercent // rectangle width should be 12% of image
        // set rectangle height
        let rectangleScale = rectangleWidth/response.lowerScrollSize.width
        let rectangleHeight = ((separatorOriginY*2/3) * rectangleScale) // LowerScrollHeight * rectangleScale
        // set rectangle position
        let rectangleX = (UIScreen.main.bounds.size.width/2)-(rectangleWidth/2)
        let rectangleYOffset = UIApplication.shared.statusBarFrame.height
        let rectangleY = (separatorOriginY/2)-(rectangleHeight/2)+rectangleYOffset
        // create rectangle frame
        let rectangleFrame = CGRect(x:rectangleX , y:rectangleY ,width: rectangleWidth, height: rectangleHeight)
        // set lower scroll height
        let lowerScrollScale = response.lowerScrollSize.width/rectangleWidth
        // scroll upper image to center
        let upperInitX = (response.upperContainerSize.width/2)-(response.upperScrollWidth/2)
        let upperInitY = (response.upperContainerSize.height/2)-(separatorOriginY/2)
        let upperScrollCenterOffset = CGPoint(x: upperInitX, y: upperInitY)
        // scroll lower image to center
        let lowerInitX = ((response.lowerContainerSize.width*lowerScrollScale)/2)-(response.lowerScrollSize.width/2)
        let lowerInitY = ((response.lowerContainerSize.height*lowerScrollScale)/2)-((separatorOriginY/2)/2)
        let lowerScrollCenterOffset = CGPoint(x: lowerInitX, y: lowerInitY)
        // calculate rectangle max zoom scale
        let rectangleMargin = CGFloat(20)
        let rectangleMaxZoomScale = (UIScreen.main.bounds.size.width - (rectangleMargin * 2))/rectangleWidth
        let viewModel = ReviewPhoto.InitialValues.ViewModel(separatorOriginY:separatorOriginY, lowerScrollScale:lowerScrollScale, rectangleFrame:rectangleFrame, upperScrollCenterOffset:upperScrollCenterOffset, lowerScrollCenterOffset:lowerScrollCenterOffset, rectangleMaxZoomScale: rectangleMaxZoomScale)
        
        viewController?.displayInitialPositions(viewModel: viewModel)
    }
    
    func presentResizedRectangle(response: ReviewPhoto.ResizeRectangle.Response)
    {
        let rectangleWidth = response.originalRectangleSize.width * response.scrollViewZoomScale
        let rectangleHeight = response.originalRectangleSize.height * response.scrollViewZoomScale
        let rectangleX = (response.scrollViewSize.width/2)-(rectangleWidth/2)
        let rectangleYOffset = UIApplication.shared.statusBarFrame.height
        let rectangleY = (response.scrollViewSize.height/2)-(rectangleHeight/2)+rectangleYOffset
        let rectangleFrame = CGRect(x:rectangleX, y:rectangleY, width: rectangleWidth, height: rectangleHeight)
        let viewModel = ReviewPhoto.ResizeRectangle.ViewModel(rectangleFrame: rectangleFrame)
        
        viewController?.displayResizedRectangle(viewModel: viewModel)
    }
    
    func reCenterLowerView(response: ReviewPhoto.ReCenterLowerView.Response) {
        let realOffsetX = ((response.scrollViewContentOffset.x+((response.scrollViewSize.width-response.rectangleViewSize.width)/2))/response.scrollViewZoomScale)-((response.scrollViewSize.width-response.originalRectangleSize.width)/2)
        let realOffsetY = ((response.scrollViewContentOffset.y+((response.scrollViewSize.height-response.rectangleViewSize.height)/2))/response.scrollViewZoomScale)-((response.scrollViewSize.height-response.originalRectangleSize.height)/2)
        
        let lowerScrollX = (realOffsetX+((response.scrollViewSize.width-response.originalRectangleSize.width)/2)) * response.lowerScrollViewZoomScale
        let lowerScrollY = (realOffsetY+((response.scrollViewSize.height-response.originalRectangleSize.height)/2)) * response.lowerScrollViewZoomScale
        
        let lowerScrollViewContentOffset = CGPoint(x: lowerScrollX, y: lowerScrollY)
        
        let viewModel = ReviewPhoto.ReCenterLowerView.ViewModel(upperScrollViewContentOffset: response.upperScrollViewContentOffset, lowerScrollViewContentOffset: lowerScrollViewContentOffset)
        
        viewController?.displayRecenteredLowerView(viewModel: viewModel)
    }
    
    func reCenterUpperView(response: ReviewPhoto.ReCenterUpperView.Response) {
        let upperScrollXWithoutZoom = (response.scrollViewContentOffset.x/response.scrollViewZoomScale) - ((response.upperScrollViewSize.width-response.originalRectangleSize.width)/2)
        let upperScrollYWithoutZoom = (response.scrollViewContentOffset.y/response.scrollViewZoomScale) - ((response.upperScrollViewSize.height-response.originalRectangleSize.height)/2)
        
        let upperScrollX = ((upperScrollXWithoutZoom+((response.upperScrollViewSize.width-response.originalRectangleSize.width)/2))*response.upperScrollViewZoomScale)-((response.upperScrollViewSize.width-response.rectangleViewSize.width)/2)
        let upperScrollY = ((upperScrollYWithoutZoom+((response.upperScrollViewSize.height-response.originalRectangleSize.height)/2))*response.upperScrollViewZoomScale)-((response.upperScrollViewSize.height-response.rectangleViewSize.height)/2)
        
        let upperScrollViewContentOffset = CGPoint(x: upperScrollX, y:upperScrollY)
        
        let viewModel = ReviewPhoto.ReCenterUpperView.ViewModel(upperScrollViewContentOffset: upperScrollViewContentOffset, lowerScrollViewContentOffset: response.lowerScrollViewContentOffset)
        
        viewController?.displayRecenteredUpperView(viewModel: viewModel)
    }
    
    func presentNewZoomScale(response: ReviewPhoto.DoubleTapZoom.Response) {
        let viewModel = ReviewPhoto.DoubleTapZoom.ViewModel(response: response)
        viewController?.displayNewZoomScale(viewModel: viewModel)
    }
}
