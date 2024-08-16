//
//  IdentifySharedWorker
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

class IdentifySharedWorker
{
    // MARK: Worker Properties
    // to be initialized early...but not in viewDidLoad (try viewDidLayoutSubviews)
    static weak var imageView: UIImageView?
    static weak var scrollView: UIScrollView?
    static var largeImageSize = CGSize.zero
    static var smallImageSize = CGSize.zero
    
    // MARK: - Universal Worker Methods

    /// Attempt to detect coin at some position with checks to prevent "out of range" detections.
    ///
    /// - Parameters:
    ///   - coin: position relative to small image (with default radius) of suspected coin image
    ///   - smallImage: UIImage to detect coin in
    /// - Returns: position of detected coin image
    class func autoEncircleCoin(coin: CoinPosition, smallImage: UIImage) -> CirclePosition {
        let originalPosition = coin as CirclePosition  // relative to imageView
        let fixableData = FixableData(fixableImage: smallImage,
                                      fixableCircle: originalPosition)
        //        let fixableData = FixableData(fixableImage: image,
        //                                      fixableCircle: mole)
        
        if let foundCircle = AutoEncircle.autoEncircleCoin(fixableData) {
            // Note: AutoEncircle already tests to see if the resulting estimate is too far from the seed value
            // and returns the default size at the seed value location if so.
            
            if isNewPositionTooDifferent(newPosition: foundCircle, oldPosition: originalPosition) {
                return originalPosition
            }
            return foundCircle
        }
        // not sure how we ever get to this path...
        return originalPosition
    }
    
    class func autoEncircleMole(smallImage: UIImage, mole: MolePosition, scrollSize: CGSize) -> CirclePosition {
        //        let imageSize = smallImage.size
        let originalPosition = mole as CirclePosition  // relative to imageView
        let fixableData = FixableData(fixableImage: smallImage,
                                      fixableCircle: originalPosition)
        
        if let foundCircle = AutoEncircle.autoEncircleMole(fixableData) {
            // Note: AutoEncircle.autoEncircleMole already tests to see if the resulting estimate is too far from the seed value
            // and returns the default size at the seed value location if so.
            
            // Similarly, the newMole method in IdentifyMolesInteractor takes care of trying to add new moles on top of an existing mole.
            //            let circledPosition = smallImagePositionToImageView(circle: fixedCircle)
            if mole.status != .new {
                if isNewPositionTooDifferent(newPosition: foundCircle, oldPosition: originalPosition)  ||
                    isNewRadiusTooDifferent(newPosition: foundCircle, oldPosition: originalPosition) {
                    mole.status = .existingNotConfident
                    return originalPosition
                }
            } else {
                if isNewPositionTooDifferent(newPosition: foundCircle, oldPosition: originalPosition) {
                    return originalPosition
                }
            }
            return foundCircle
        }
        // not sure how we ever get to this path...
        return originalPosition
    }
    
    
    /// Converts a point relative to the displayed image in a UIImageView
    /// to one relative to the containing view.
    ///
    /// - Parameter aspectFitPoint: CGPoint relative to the resized, repositioned image
    /// - Returns: CGPoint relative to the UIImageView
    class func aspectFitImageToImageView(aspectFitPoint: CGPoint) -> CGPoint {
        // Presumes imageView contentMode == aspectFit
        let aspectMargins = getAspectFitMargins()
        var newPoint = aspectFitPoint
        newPoint.x += aspectMargins.horizontalMargin
        newPoint.y += aspectMargins.verticalMargin
        return newPoint
    }
    
    class func calculatePhotoEdges(scrollSize: CGSize, displayPhoto: UIImage, scrollViewScale: CGFloat = 1.0) -> PhotoEdges {
        
        let scrollContentSize = CGSize(width: scrollSize.width*scrollViewScale, height: scrollSize.height*scrollViewScale)
        let photoRealSize = displayPhoto.sizeAspectFit(aspectRatio: displayPhoto.size, boundingSize: scrollContentSize)
        
        let minX = CGFloat(0)
        let maxX = CGFloat(scrollContentSize.width)
        let minY = CGFloat((scrollContentSize.height - photoRealSize.height)/2)
        let maxY = CGFloat(scrollContentSize.height - ((scrollContentSize.height - photoRealSize.height)/2))
        
        return PhotoEdges(minimumPosition: CGPoint(x: minX, y: minY), maximumPosition: CGPoint(x: maxX, y: maxY))
    }
    

    /// Calculate margins around resized and offset image in UIImageView with the
    /// contentMode set to aspectFit.
    ///
    /// - Returns: a tuple with named values for the vertical margin and horizontal margin
    class func getAspectFitMargins() -> (verticalMargin: CGFloat, horizontalMargin: CGFloat) {
        // Presumes imageView contentMode == aspectFit
        guard let view = imageView, view.contentMode == .scaleAspectFit else { return (0,0) }
        let viewBounds = view.bounds
        
        // What would we need to multiply the image by to fit into
        // the frame in an aspectFit kind of way? (either image will work, by the way)
        let imageWidthToHeightRatio = largeImageSize.width / largeImageSize.height
        let viewWidthToHeightRatio = viewBounds.width / viewBounds.height
        
        var verticalMargin: CGFloat = 0
        var horizontalMargin: CGFloat = 0
        if viewWidthToHeightRatio < imageWidthToHeightRatio {
            // Calculate height from scaled width
            let scale = viewBounds.width / largeImageSize.width
            let scaledHeight = scale * largeImageSize.height
            verticalMargin = (viewBounds.height - scaledHeight) / 2.0
        }
        else {
            // Calculate width from scaled height
            let scale = viewBounds.height / largeImageSize.height
            let scaledWidth = scale * largeImageSize.width
            horizontalMargin = (viewBounds.height - scaledWidth) / 2.0
        }
        return (verticalMargin, horizontalMargin)
    }
    
    /// Conversion helper between aspectFit images and small images
    ///
    /// - Returns: value to scale points (multiply) in aspectFit image relative to small image
    class func getAspectFitScaleForSmallImage() -> CGFloat {
        guard let view = imageView, view.contentMode == .scaleAspectFit else { return 1 }
        let viewBounds = view.bounds
        
        let widthRatio = smallImageSize.width / viewBounds.width
        let heightRatio = smallImageSize.height / viewBounds.height
        return max(widthRatio,heightRatio)
    }
    
    /// Conversion helper between aspectFit images and large images
    ///
    /// - Returns: value to scale points (multiply) in aspectFit image relative to large image
    class func getAspectFitScaleForLargeImage() -> CGFloat {
        guard let view = imageView, view.contentMode == .scaleAspectFit else { return 1 }
        let viewBounds = view.bounds
        
        let widthRatio = largeImageSize.width / viewBounds.width
        let heightRatio = largeImageSize.height / viewBounds.height
        return max(widthRatio,heightRatio)
    }
    
    /// Converts a point relative to the imageView to relative to the
    /// scaled image displayed inside the imageView.
    ///
    /// - Parameter imageViewPoint: point relative to the UIImageView
    /// - Returns: point relative to (possibly) resized and offset image in view
    class func imageViewToAspectFitImage(imageViewPoint: CGPoint) -> CGPoint {
        // Presumes imageView contentMode == aspectFit
        let aspectMargins = getAspectFitMargins()
        
        var newPoint = imageViewPoint
        newPoint.x -= aspectMargins.horizontalMargin
        newPoint.y -= aspectMargins.verticalMargin
        return newPoint
    }

    /// Test if CirclePosition object would fall more than half-way out of the
    /// reference small image.
    ///
    /// - Parameter newPosition: CirclePosition to test
    /// - Returns: true if it is more outside than inside
    class func isNewPositionOutsideSmallImage(newPosition: CirclePosition) -> Bool {
        if newPosition.center.x < 0 || newPosition.center.y < 0 {
            return true
        }
        if newPosition.center.x  > smallImageSize.width || newPosition.center.y > smallImageSize.height {
            return true
        }
        return false
    }
    

    /// Check to see if new position is outside of "tap" tolerance
    class func isNewPositionTooDifferent(newPosition: CirclePosition, oldPosition: CirclePosition) -> Bool {
        let distance = newPosition.distance(to: oldPosition)
        let testDistance: CGFloat = (48 > newPosition.radius) ? 48.0 : newPosition.radius
        if distance > testDistance {
            // Too far, not in right place
            return true
        }
        return false
    }
    
    /// Check to see if radius is too small or too large relative to original (or default) radius
    class func isNewRadiusTooDifferent(newPosition: CirclePosition, oldPosition: CirclePosition) -> Bool {
        if ((newPosition.radius < (oldPosition.radius * 0.8)) || (newPosition.radius > (oldPosition.radius * 1.2))){
            return true
        }
        return false
    }
    
    class func isValidOffsetPoint(point: CGPoint) -> Bool {
        guard imageView != nil, scrollView != nil else { return false }
        if point.x < 0 || point.y < 0 {
            return false
        }
        if point.x + scrollView!.bounds.width > imageView!.frame.width {
            return false
        }
        if point.y + scrollView!.bounds.height > imageView!.frame.height {
            return false
        }
        return true
    }


    /// Converts the center and radius of a CirclePosition relative to the imageView
    /// to the "small" image (previously referred to as the "display" image).
    ///
    /// - Parameter circle: CirclePosition relative to imageView
    /// - Returns: CirclePosition relative to small image
    class func imageViewPositionToSmallImage(circle: CirclePosition) -> CirclePosition {
        // translate to aspect fit then scale to image
        var aspectFitCenter = imageViewToAspectFitImage(imageViewPoint: circle.center)
        
        let scale = getAspectFitScaleForSmallImage()
        // rescale (only really needed if user changed phones and an old image is in a different size)
        aspectFitCenter.x *= scale
        aspectFitCenter.y *= scale
        let radius = circle.radius * scale
        
        
        return CirclePosition(center: aspectFitCenter, radius: radius)
    }
    
    /// Convert widget location to CirclePosition
    ///
    /// - Parameter widget: CircleWidget (or derived class) object relative to scrollView
    /// - Returns: CirclePosition relative to small image
    class func positionFromWidget(widget: CircleWidget) -> CirclePosition {
        //        let center = scrollView?.convert(widget.center, to: imageView)
        let center = scrollViewToSmallImage(at: widget.center)
        
        let scale = getAspectFitScaleForSmallImage()
        let radius = (widget.bounds.size.width / 2.0)
        // the Radius is trickier
        let scrollViewRadiusPt = CGPoint(x: radius, y: 0)
        let imageViewRadiusPt = scrollView!.convert(scrollViewRadiusPt, to: imageView)
        let scaledRadius = imageViewRadiusPt.x * scale
        
        let position = CirclePosition(center: center, radius: scaledRadius)
        return position
    }
    
    /// Modify CirclePosition if it would fall more than half-way out of the
    /// reference small image.
    ///
    /// - Parameter position: CirclePosition to modify
    /// - Returns: position moved inside small image space (at least center is)
    class func positionInsideSmallImage(position: CirclePosition) -> CirclePosition {
        let correctedPosition = position
        
        if correctedPosition.center.x < 0 {
            correctedPosition.center.x = 0
        }
        if correctedPosition.center.y < 0 {
            correctedPosition.center.y = 0
        }
        if correctedPosition.center.x  > smallImageSize.width {
            correctedPosition.center.x = smallImageSize.width
        }
        if correctedPosition.center.y > smallImageSize.height {
            correctedPosition.center.y = smallImageSize.height
        }
        return correctedPosition
    }
    
    /// Convert point from scrollView coordinates to small image coordinates
    ///
    /// - Parameter scrollViewPoint: CGPoint relative to scrollView
    /// - Returns: CGPoint relative to small image
    class func scrollViewToSmallImage(at scrollViewPoint: CGPoint) -> CGPoint {
        let scale = getAspectFitScaleForSmallImage()
        let aspectMargins = getAspectFitMargins()
        // convert
        var imagePt = scrollView!.convert(scrollViewPoint, to: imageView)
        // translate
        imagePt.x -= aspectMargins.horizontalMargin
        imagePt.y -= aspectMargins.verticalMargin
        // then scale
        imagePt.x *= scale
        imagePt.y *= scale
        return imagePt
    }
    
    /// Convert position from scrollView coordinates to small image coordinates
    ///
    /// - Parameter position: WidgetPosition relative to scrollView
    /// - Returns: CirclePosition relative to small image
    class func scrollViewToSmallImage(position: WidgetPosition) -> CirclePosition {
        let scale = getAspectFitScaleForSmallImage()
        
        let imageCenter = scrollViewToSmallImage(at: position.center)
        // the Radius is trickier
        let scrollViewRadiusPt = CGPoint(x: position.radius, y: 0)
        let imageViewRadiusPt = scrollView!.convert(scrollViewRadiusPt, to: imageView)
        let scaledRadius = imageViewRadiusPt.x * scale
        return CirclePosition(center: imageCenter, radius: scaledRadius)
    }
    
    /// Convert position from small image coordinates to imageView coordinates
    ///
    /// - Parameter circle: CirclePosition relative to small image
    /// - Returns: CirclePosition relative to imageView
    class func smallImagePositionToImageView(circle: CirclePosition) -> CirclePosition {
        // scale to aspect fit then translate to image view
        let scale = getAspectFitScaleForSmallImage()
        // rescale (only really needed if user changed phones and an old image is in a different size)
        circle.center.x /= scale
        circle.center.y /= scale
        let radius = circle.radius / scale
        
        let centerRelativeToAspectImage = aspectFitImageToImageView(aspectFitPoint: circle.center)
        return CirclePosition(center: centerRelativeToAspectImage, radius: radius)
    }
    
    /// Convert point from small image coordinates to scrollView coordinates
    ///
    /// - Parameter imagePoint: CGPoint relative to small image
    /// - Returns: CGPoint relative to scrollView
    class func smallImageToScrollView(at imagePoint: CGPoint) -> CGPoint {
        var aspectPt = imagePoint
        let scale = getAspectFitScaleForSmallImage()
        let aspectMargins = getAspectFitMargins()
        // scale
        aspectPt.x /= scale
        aspectPt.y /= scale
        // then translate
        aspectPt.x += aspectMargins.horizontalMargin
        aspectPt.y += aspectMargins.verticalMargin
        // and convert
        return imageView!.convert(aspectPt, to: scrollView)
    }
    
    /// Convert position from small view coordinates to scrollView coordinates
    ///
    /// - Parameter position: CirclePosition relative to small view
    /// - Returns: WidgetPosition relative to scrollView
    class func smallImageToScrollView(position: CirclePosition) -> WidgetPosition {
        let scale = getAspectFitScaleForSmallImage()
        
        let scrollCenter = smallImageToScrollView(at: position.center)
        // radius
        let imageViewRadiusPt = CGPoint(x: position.radius, y: 0)
        let scrollViewRadiusPt = imageView!.convert(imageViewRadiusPt, to: scrollView)
        let scaledRadius = scrollViewRadiusPt.x / scale
        return WidgetPosition(center: scrollCenter, radius: scaledRadius)
    }
    
}
