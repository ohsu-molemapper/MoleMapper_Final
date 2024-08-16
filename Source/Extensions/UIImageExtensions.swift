//
// MoleMapper
//
// Copyright (c) 2017-2022 OHSU. All rights reserved.
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
extension UIImage {
    
    func sizeAspectFit(aspectRatio:CGSize, boundingSize:CGSize) -> CGSize
    {
        var aspectFitSize = CGSize(width: boundingSize.width, height: boundingSize.height);
        let mW = boundingSize.width / aspectRatio.width;
        let mH = boundingSize.height / aspectRatio.height;
        if mH < mW {
            aspectFitSize.width = mH * aspectRatio.width;
        }else if mW < mH {
            aspectFitSize.height = mW * aspectRatio.height;
        }
        return aspectFitSize;
    }
    
    func detectOrientation() -> UIImage.Orientation {
        var newOrientation = UIImage.Orientation.up
        switch (self.imageOrientation)
        {
        case .up:
            newOrientation = UIImage.Orientation.up;
            break;
        case .down:
            newOrientation = UIImage.Orientation.down;
            break;
        case .left:
            newOrientation = UIImage.Orientation.left;
            break;
        case .right:
            newOrientation = UIImage.Orientation.right;
            break;
        case .upMirrored:
            newOrientation = UIImage.Orientation.upMirrored;
            break;
        case .downMirrored:
            newOrientation = UIImage.Orientation.downMirrored;
            break;
        case .leftMirrored:
            newOrientation = UIImage.Orientation.leftMirrored;
            break;
        case .rightMirrored:
            newOrientation = UIImage.Orientation.rightMirrored;
            break;
        }
        return newOrientation;
    }
    
    func rotate() -> UIImage{
        let degrees = CGFloat(90.0)
        let size = self.size
        let fixedSize = CGSize(width: size.height, height: size.width)
        UIGraphicsBeginImageContext(size)
        
        let bitmap: CGContext = UIGraphicsGetCurrentContext()!
        //Move the origin to the middle of the image so we will rotate and scale around the center.
        bitmap.translateBy(x: size.width / 2, y: size.height / 2)
        //Rotate the image context
        bitmap.rotate(by: (degrees * .pi / 180))
        //Now, draw the rotated/scaled image into the context
        bitmap.scaleBy(x: 1.0, y: -1.0)
        
        let origin = CGPoint(x: -size.height / 2, y: -size.width / 2)
        
        bitmap.draw(self.cgImage!, in: CGRect(origin: origin, size: fixedSize))
        
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
}
