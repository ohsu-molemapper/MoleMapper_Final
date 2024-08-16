//
//  ZoneMeasurement30+CoreDataClass.swift
//  MoleMapper
//
// Copyright (c) 2016, 2017 OHSU. All rights reserved.
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

import Foundation
import CoreData

@objc(ZoneMeasurement30)
@objcMembers
public class ZoneMeasurement30: NSManagedObject {

    /**
     create creates a new ZoneMeasurement30 object using the global context maintained
     by the V30Stack singleton factory and SETS ITS ID IMMEDIATELY. Other functions
     depend on this value (e.g. filenames) so it's critical to set it before any other
     uses of the object.
     
     Returns: new ZoneMeasurement30 object with its zoneMeasurementID set.
     */
    class func create() -> ZoneMeasurement30 {
        let zoneMeasurement30 = ZoneMeasurement30(context: V30StackFactory.createV30Stack().managedContext)
        zoneMeasurement30.zoneMeasurementID = NSUUID().uuidString
        return zoneMeasurement30
    }

    /**
     displayToJpegRatios returns the width and height ratios to convert X and Y display coordinates
     into X and Y full-sized JPEG image coordinates.
     
     Returns: Dictionary with "widthRatio" and "heightRatio" CGFloat values.
    */
    func displayToJpegRatios() -> [String:CGFloat] {
        var displayToJpegWidthRatio: CGFloat = 0.0
        var displayToJpegHeightRatio: CGFloat = 0.0
        let fullsizeImage = self.fullsizedImage()
        let displayImage = self.displayImage()
        if (fullsizeImage != nil) && (displayImage != nil) {
            if fullsizeImage!.imageOrientation == UIImage.Orientation.up {
                //            print("up")
                displayToJpegWidthRatio = CGFloat(fullsizeImage!.size.width) / CGFloat(displayImage!.size.width)
                displayToJpegHeightRatio = CGFloat(fullsizeImage!.size.height) / CGFloat(displayImage!.size.height)
            } else if fullsizeImage!.imageOrientation == UIImage.Orientation.right {
                //            print("right")
                displayToJpegWidthRatio = CGFloat(fullsizeImage!.size.height) / CGFloat(displayImage!.size.height)
                displayToJpegHeightRatio = CGFloat(fullsizeImage!.size.width) / CGFloat(displayImage!.size.width)
            } else {
                fatalError("Unexpected image orientation in ZoneMeasurement30.dictionaryForBridge")
            }
        }
        let ratioDictionary: [String: CGFloat] = ["widthRatio":displayToJpegWidthRatio, "heightRatio":displayToJpegHeightRatio]
        return ratioDictionary
    }
    

    private func getFullsizeFilename() -> String {
        var filename = "error.jpg"
        if self.zoneMeasurementID != nil {
            if fullsizePhotoFilename != nil {
                filename = fullsizePhotoFilename!
            } else {
                filename = "full" + zoneMeasurementID! + ".jpg"
                fullsizePhotoFilename = filename
            }
        }
        return filename
    }
    
    private func getDisplayFilename() -> String {
        var filename = "error.jpg"
        if self.zoneMeasurementID != nil {
            if displayPhotoFilename != nil {
                filename = displayPhotoFilename!
            } else {
                filename = "display" + zoneMeasurementID! + ".png"
                displayPhotoFilename = filename
            }
        }
        return filename
    }
    
    func imageFullPathNameForFullsizedPhoto() -> String {
        if self.zoneMeasurementID != nil {
            let filename = getFullsizeFilename()
            // path-based
            let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .allDomainsMask, true)[0]
            let FQFN = documents.appending("/" + filename)
            return FQFN
        } else {
            return ""
        }
    }
    
    func imageFullPathNameForDisplayPhoto() -> String {
        if self.zoneMeasurementID != nil {
            let filename = getDisplayFilename()
            // path-based
            let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .allDomainsMask, true)[0]
            let FQFN = documents.appending("/" + filename)
            return FQFN
            
        } else {
            return ""
        }
    }
    
    func fullsizedImage() -> UIImage? {
        return UIImage(contentsOfFile: imageFullPathNameForFullsizedPhoto())
    }
    
    func fullsizedImageData() -> NSData {
        var jpegData = NSData()
        do {
            try jpegData = NSData(contentsOfFile: imageFullPathNameForFullsizedPhoto())
        } catch let err as NSError {
            print("Error \(err), \(err.userInfo) fetching zone image data")
        }
        return jpegData
    }

    func displayImage() -> UIImage? {
        var resizedImg: UIImage?
        // this is required because image orientation is not preserved on file write
        let landscapeImg = UIImage(contentsOfFile: imageFullPathNameForDisplayPhoto())
        resizedImg = landscapeImg
        let imgSize = resizedImg?.size ?? CGSize.zero
        let isHorizontal = imgSize.width > imgSize.height
        if (landscapeImg?.imageOrientation == .up) && isHorizontal {
            if let img = landscapeImg {
                resizedImg = UIImage(cgImage: img.cgImage!, scale: img.scale, orientation: .right)
            }
        }
        return resizedImg
    }
    
    func saveFullsizedDataAsJPEG(jpegData: Data) {
        let fm = FileManager.default
        fm.createFile(atPath: imageFullPathNameForFullsizedPhoto(),
                      contents: jpegData,
                      attributes: nil)      // TODO: explicity type this as JPEG?
    }
    
    func saveDisplayDataAsPNG(pngData: Data) {
        let fm = FileManager.default
        fm.createFile(atPath: imageFullPathNameForDisplayPhoto(),
                      contents: pngData,
                      attributes: nil)      // TODO: explicitly type this as PNG?
    }
    
    func deleteFullsizedImageFile() {
        let fm = FileManager.default
        do {
            try fm.removeItem(atPath: imageFullPathNameForFullsizedPhoto())
        } catch {
            // nothing
        }
    }

    func deleteDisplayImageFile() {
        let fm = FileManager.default
        do {
            try fm.removeItem(atPath: imageFullPathNameForDisplayPhoto())
        } catch {
            // nothing
        }
    }
  
    class func moreRecentZoneMeasurementThan(date: Date) -> Bool {
        let context = V30StackFactory.createV30Stack().managedContext
        let zoneMeasurementFetch: NSFetchRequest<ZoneMeasurement30> = ZoneMeasurement30.fetchRequest()
        zoneMeasurementFetch.predicate = NSPredicate(format: "date > %@", date as NSDate)
        do {
            let results = try context.fetch(zoneMeasurementFetch)
            if results.count > 0 {
                return true
            }
        } catch let err as NSError {
            print("Error \(err), \(err.userInfo)")
        }
        return false
    }
}
