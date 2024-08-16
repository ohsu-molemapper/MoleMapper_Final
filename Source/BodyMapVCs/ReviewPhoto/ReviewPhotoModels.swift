//
//  ReviewPhotoModels.swift
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

enum ReviewPhoto
{
    enum InitialValues
    {
        struct Request
        {
            let separatorViewHeight:CGFloat
            let toolbarHeight:CGFloat
            let realImageSize:CGSize
            let lowerScrollSize:CGSize
            let upperContainerSize:CGSize
            let upperScrollWidth:CGFloat
            let lowerContainerSize:CGSize
            init(separatorViewHeight:CGFloat, toolbarHeight:CGFloat, realImageSize:CGSize, lowerScrollSize:CGSize, upperContainerSize:CGSize, upperScrollWidth:CGFloat, lowerContainerSize:CGSize){
                self.separatorViewHeight = separatorViewHeight
                self.toolbarHeight = toolbarHeight
                self.realImageSize = realImageSize
                self.lowerScrollSize = lowerScrollSize
                self.upperContainerSize = upperContainerSize
                self.upperScrollWidth = upperScrollWidth
                self.lowerContainerSize = lowerContainerSize
            }
        }
        struct Response
        {
            let separatorViewHeight:CGFloat
            let toolbarHeight:CGFloat
            let realImageSize:CGSize
            let lowerScrollSize:CGSize
            let upperContainerSize:CGSize
            let upperScrollWidth:CGFloat
            let lowerContainerSize:CGSize
            init(separatorViewHeight:CGFloat, toolbarHeight:CGFloat, realImageSize:CGSize, lowerScrollSize:CGSize, upperContainerSize:CGSize, upperScrollWidth:CGFloat, lowerContainerSize:CGSize){
                self.separatorViewHeight = separatorViewHeight
                self.toolbarHeight = toolbarHeight
                self.realImageSize = realImageSize
                self.lowerScrollSize = lowerScrollSize
                self.upperContainerSize = upperContainerSize
                self.upperScrollWidth = upperScrollWidth
                self.lowerContainerSize = lowerContainerSize
            }
        }
        struct ViewModel
        {
            let separatorOriginY:CGFloat
            let lowerScrollScale:CGFloat
            let rectangleFrame:CGRect
            let upperScrollCenterOffset:CGPoint
            let lowerScrollCenterOffset:CGPoint
            let rectangleMaxZoomScale: CGFloat
            init(separatorOriginY:CGFloat, lowerScrollScale:CGFloat, rectangleFrame:CGRect, upperScrollCenterOffset:CGPoint, lowerScrollCenterOffset:CGPoint, rectangleMaxZoomScale: CGFloat){
                self.separatorOriginY = separatorOriginY
                self.lowerScrollScale = lowerScrollScale
                self.rectangleFrame = rectangleFrame
                self.upperScrollCenterOffset = upperScrollCenterOffset
                self.lowerScrollCenterOffset = lowerScrollCenterOffset
                self.rectangleMaxZoomScale = rectangleMaxZoomScale
            }
        }
    }
    
    enum ResizeRectangle
    {
        struct Request
        {
            let originalRectangleSize:CGSize
            let scrollViewZoomScale:CGFloat
            let scrollViewSize:CGSize
            init(originalRectangleSize:CGSize, scrollViewZoomScale:CGFloat, scrollViewSize:CGSize){
                self.originalRectangleSize = originalRectangleSize
                self.scrollViewZoomScale = scrollViewZoomScale
                self.scrollViewSize = scrollViewSize
            }
        }
        struct Response
        {
            let originalRectangleSize:CGSize
            let scrollViewZoomScale:CGFloat
            let scrollViewSize:CGSize
            init(originalRectangleSize:CGSize, scrollViewZoomScale:CGFloat, scrollViewSize:CGSize){
                self.originalRectangleSize = originalRectangleSize
                self.scrollViewZoomScale = scrollViewZoomScale
                self.scrollViewSize = scrollViewSize
            }
        }
        struct ViewModel
        {
            let rectangleFrame:CGRect
            init(rectangleFrame:CGRect){
                self.rectangleFrame = rectangleFrame
            }
        }
    }
    
    enum ReCenterLowerView
    {
        struct Request
        {
            let scrollViewZoomScale:CGFloat
            let scrollViewContentOffset:CGPoint
            let imageSize:CGSize
            let upperContainerViewSize:CGSize
            let scrollViewSize:CGSize
            let rectangleViewSize:CGSize
            let originalRectangleSize:CGSize
            let lowerScrollViewZoomScale:CGFloat
            init(scrollViewZoomScale:CGFloat, scrollViewContentOffset:CGPoint, imageSize:CGSize, upperContainerViewSize:CGSize, scrollViewSize:CGSize, rectangleViewSize:CGSize, originalRectangleSize:CGSize, lowerScrollViewZoomScale:CGFloat){
                self.scrollViewZoomScale = scrollViewZoomScale
                self.scrollViewContentOffset = scrollViewContentOffset
                self.imageSize = imageSize
                self.upperContainerViewSize = upperContainerViewSize
                self.scrollViewSize = scrollViewSize
                self.rectangleViewSize = rectangleViewSize
                self.originalRectangleSize = originalRectangleSize
                self.lowerScrollViewZoomScale = lowerScrollViewZoomScale
            }
        }
        struct Response
        {
            let scrollViewZoomScale:CGFloat
            let scrollViewContentOffset:CGPoint
            let scrollViewSize:CGSize
            let rectangleViewSize:CGSize
            let originalRectangleSize:CGSize
            let lowerScrollViewZoomScale:CGFloat
            let upperScrollViewContentOffset:CGPoint
            init(scrollViewZoomScale:CGFloat, scrollViewContentOffset:CGPoint,  scrollViewSize:CGSize, rectangleViewSize:CGSize, originalRectangleSize:CGSize, lowerScrollViewZoomScale:CGFloat, upperScrollViewContentOffset:CGPoint){
                self.scrollViewZoomScale = scrollViewZoomScale
                self.scrollViewContentOffset = scrollViewContentOffset
                self.scrollViewSize = scrollViewSize
                self.rectangleViewSize = rectangleViewSize
                self.originalRectangleSize = originalRectangleSize
                self.lowerScrollViewZoomScale = lowerScrollViewZoomScale
                self.upperScrollViewContentOffset = upperScrollViewContentOffset
            }
        }
        struct ViewModel
        {
            let upperScrollViewContentOffset:CGPoint
            let lowerScrollViewContentOffset:CGPoint
            init(upperScrollViewContentOffset:CGPoint, lowerScrollViewContentOffset:CGPoint){
                self.upperScrollViewContentOffset = upperScrollViewContentOffset
                self.lowerScrollViewContentOffset = lowerScrollViewContentOffset
            }
        }
    }
    
    enum ReCenterUpperView
    {
        struct Request
        {
            let scrollViewZoomScale:CGFloat
            let imageSize:CGSize
            let scrollViewContentOffset:CGPoint
            let lowerContainerViewSize:CGSize
            let upperScrollViewSize:CGSize
            let originalRectangleSize:CGSize
            let upperScrollViewZoomScale:CGFloat
            let rectangleViewSize:CGSize
            let scrollViewSize:CGSize
            init(scrollViewZoomScale:CGFloat, imageSize:CGSize, scrollViewContentOffset:CGPoint, lowerContainerViewSize:CGSize, upperScrollViewSize:CGSize, originalRectangleSize:CGSize, upperScrollViewZoomScale:CGFloat, rectangleViewSize:CGSize, scrollViewSize:CGSize){
                self.scrollViewZoomScale = scrollViewZoomScale
                self.imageSize = imageSize
                self.scrollViewContentOffset = scrollViewContentOffset
                self.lowerContainerViewSize = lowerContainerViewSize
                self.upperScrollViewSize = upperScrollViewSize
                self.originalRectangleSize = originalRectangleSize
                self.upperScrollViewZoomScale = upperScrollViewZoomScale
                self.rectangleViewSize = rectangleViewSize
                self.scrollViewSize = scrollViewSize
            }
            
        }
        struct Response{
            let scrollViewZoomScale:CGFloat
            let scrollViewContentOffset:CGPoint
            let upperScrollViewSize:CGSize
            let originalRectangleSize:CGSize
            let upperScrollViewZoomScale:CGFloat
            let rectangleViewSize:CGSize
            let scrollViewSize:CGSize
            let lowerScrollViewContentOffset:CGPoint
            init(scrollViewZoomScale:CGFloat, scrollViewContentOffset:CGPoint, upperScrollViewSize:CGSize, originalRectangleSize:CGSize, upperScrollViewZoomScale:CGFloat, rectangleViewSize:CGSize, scrollViewSize:CGSize, lowerScrollViewContentOffset:CGPoint){
                self.scrollViewZoomScale = scrollViewZoomScale
                self.scrollViewContentOffset = scrollViewContentOffset
                self.upperScrollViewSize = upperScrollViewSize
                self.originalRectangleSize = originalRectangleSize
                self.upperScrollViewZoomScale = upperScrollViewZoomScale
                self.rectangleViewSize = rectangleViewSize
                self.scrollViewSize = scrollViewSize
                self.lowerScrollViewContentOffset = lowerScrollViewContentOffset
            }
        }
        struct ViewModel{
            let upperScrollViewContentOffset:CGPoint
            let lowerScrollViewContentOffset:CGPoint
            init(upperScrollViewContentOffset:CGPoint, lowerScrollViewContentOffset:CGPoint){
                self.upperScrollViewContentOffset = upperScrollViewContentOffset
                self.lowerScrollViewContentOffset = lowerScrollViewContentOffset
            }
        }
    }
    
    enum DoubleTapZoom{
        struct Request{
            let currentZoomScale:CGFloat
            init(currentZoomScale:CGFloat){
                self.currentZoomScale = currentZoomScale
            }
        }
        struct Response{
            let newZoomScale:CGFloat
            init(newZoomScale:CGFloat){
                self.newZoomScale = newZoomScale
            }
        }
        struct ViewModel{
            let zoomScale:CGFloat
            init(response: Response){
                self.zoomScale = response.newZoomScale
            }
        }
    }
}

