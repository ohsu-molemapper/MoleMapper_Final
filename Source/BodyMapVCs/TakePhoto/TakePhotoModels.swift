//
//  TakePhotoModels.swift
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

enum TakePhoto
{
    enum SetupFailed {
        struct Request {
            
            var setupResult: TakePhotoSetupResult
            
            init (setupResult: TakePhotoSetupResult) {
                self.setupResult = setupResult
            }
        }
        
        struct Response {
            var additionalButtonText: String
            var message: String
            var title: String
            
            init(additionalButtonText: String, message: String, title: String) {
                self.additionalButtonText = additionalButtonText
                self.message = message
                self.title = title
            }
        }
        
        struct ViewModel {
            var additionalButtonText: String
            var message: String
            var title: String
            
            init(additionalButtonText: String, message: String, title: String) {
                self.additionalButtonText = additionalButtonText
                self.message = message
                self.title = title
            }
        }
    }
    
    enum Pins {
        struct Request {
            var highResolutionSize: CGSize
            
            init(width: CGFloat, height: CGFloat) {
                self.highResolutionSize = CGSize(width: width, height: height)
            }
        }
        
        struct Response {
            var availableImageSize: CGSize
            
            init(width: CGFloat, height: CGFloat) {
                self.availableImageSize = CGSize(width: width, height: height)
            }
        }
        
        struct ViewModel {
            var imageSize: CGSize
            
            init(width: CGFloat, height: CGFloat) {
                self.imageSize = CGSize(width: width, height: height)
            }
        }
    }
    
    struct PhotoData {
        var displayPhoto: UIImage
        var jpegData: Data
        var lensPosition: Float
        var gravityData: GravityData?

        
        init(displayPhoto: UIImage, jpegData: Data, lensPosition: Float, gravityData: GravityData?) {
            self.displayPhoto = displayPhoto
            self.jpegData = jpegData
            self.lensPosition = lensPosition
            self.gravityData = gravityData
        }
    }
    
    struct GravityData {
        var xPosition: Double
        var yPosition: Double
        var zPosition: Double
        
        init(xPosition: Double, yPosition: Double, zPosition : Double) {
            self.xPosition = xPosition
            self.yPosition = yPosition
            self.zPosition = zPosition
        }
    }
}
