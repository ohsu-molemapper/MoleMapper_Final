//
//  IdentifyMolesWorker
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

class IdentifyMolesWorker
{
   
    // MARK: - Mole Worker Methods

    class func convertMoleToCoin(moleCircle: MolePosition, lastID:Int, coinType: CoinType) -> CoinPosition{
        let coinCircle = CoinPosition(withID: lastID, atLocation: moleCircle.center, ofRadius: moleCircle.radius, withState: .selected, withCoinType: coinType)
        
        return coinCircle
    }
    
    class func deleteMole(moleID: Int, numericIdToMole: [Int:Mole30]){
        if let mole = numericIdToMole[moleID] {
            // Delete mole
            let stack = V30StackFactory.createV30Stack()
            stack.managedContext.delete(mole)
            stack.saveContext()
        }
    }

    class func detectIfTouchIsInsideOfAnExistingMole(at imageLocation: CGPoint, circles: ObjectPositionDictionary) -> Int {
        for (circleID, circle) in circles {
            if circle.hitTest(pt: imageLocation){
                return circleID
            }
        }
        return -1
    }

    class func retrieveHelp() -> (helpTitle: String, helpText: NSAttributedString) {
        let helpTitle = "Mark Moles"
        let helpText = RTFHelpers.getAttributedText(fromFile: "IdentifyMoles")

        return (helpTitle, helpText)
    }

    class func removeMoleRecordResults(moleID: Int, numericIdToMole: [Int:Mole30], removedMolesToDiagnoses:[Any], removedMoleRecord:[AnyHashable : Any]){
        if let mole = numericIdToMole[moleID] {
            mole.waitingForResults = false
            mole.moleWasRemoved = true
            V30StackFactory.createV30Stack().saveContext()
        }
    }
    
    class func removeMoleWaitingForResults(moleID: Int, numericIdToMole: [Int:Mole30]){
        if let mole = numericIdToMole[moleID] {
            mole.waitingForResults = true
            mole.moleWasRemoved = true
            V30StackFactory.createV30Stack().saveContext()
        }
    }
    
    class func renameMole(moleID: Int, newName:String, numericIdToMole: [Int:Mole30]){
        if let mole = numericIdToMole[moleID] {
            mole.moleName = newName
            V30StackFactory.createV30Stack().saveContext()
        }
    }
   
    class func retrieveMoles(with displayPhoto:UIImage, andScrollSize scrollSize: CGSize, andMolesData molesData: ShowZone.MolesData?, andCoinData coinData: CoinPosition?) -> IdentifyMoles.InitModel.Response
    {
        var nextID = 0
        
        var circles = ObjectPositionDictionary()
        
        if let moles = molesData?.numericIdToMole, let originalMoleMeasurements = molesData?.originalMoleMeasurements {
            for (key, mole) in moles {
                if let moleMeasurement = originalMoleMeasurements[key] {
                    let radius: CGFloat = CGFloat(truncating: moleMeasurement.moleMeasurementDiameterInPoints!) / 2.0
                    let center = CGPoint(x: (moleMeasurement.moleMeasurementX! as! CGFloat),
                                         y: (moleMeasurement.moleMeasurementY! as! CGFloat))
                    // radius and center are relative to small image
                    let originalCircle = CirclePosition(center: center, radius: radius)
                    
                    let status:MoleStatus = .existingConfident
                    
                    let moleCircle = MolePosition(withID: key, atLocation: originalCircle.center, ofRadius: originalCircle.radius, withObjectName: mole.moleName!, withState: .unselected, withStatus: status)
                    circles[key] = moleCircle
                    
                    if key >= nextID
                    {
                        nextID = key + 1
                    }
                }
            }
        }
        
        var coinCircle:CoinPosition? = nil
        // Check if there is a coin
        if coinData != nil {
            coinCircle = CoinPosition(withID: nextID, atLocation: coinData!.center, ofRadius: coinData!.radius, withState: .unselected, withCoinType: coinData!.coinType)
            circles[nextID] = coinCircle
            nextID += 1
        }
        
        let response = IdentifyMoles.InitModel.Response(lastID: nextID, circles: circles, coinCircle: coinCircle)
        return response
    }
    
    class func saveMolesAndCoinInDataBase(photoData: TakePhoto.PhotoData, zoneID: String, scrollSize: CGSize, circles: ObjectPositionDictionary, molesData: ShowZone.MolesData?)
    {
        // Create MolePositions
//        let imageSize = photoData.displayPhoto.size
        var numericIdToMolePosition:MolePositionDictionary = [:]
        var numericIdToMole:[Int:Mole30] = [:]
        if let molesData = molesData {
            numericIdToMole = molesData.numericIdToMole
        }
        var coinCircle: CoinPosition? = nil
        
        // aren't the circles in the passed dictionary already translated?
        for (_, circle) in circles {
            if let mole: MolePosition = circle as? MolePosition {
                numericIdToMolePosition[mole.objectID] = mole
                
            }
            else if let coin: CoinPosition = circle as? CoinPosition {
                // Its a coin
                coinCircle = coin
            }
        }
        
        // Save in Core Data
        let zone30 = Zone30.zoneForZoneID(zoneID)
        
        // Step1: Create Parent Zone Measurement
        let zoneMeasurement30 = ZoneMeasurement30.create()
        zoneMeasurement30.whichZone = zone30
        zoneMeasurement30.date = NSDate()
        // TODO: finish calculating reference diameter
        zoneMeasurement30.referenceDiameterInMillimeters = NSNumber(value: 0.0)
        zoneMeasurement30.lensPosition = NSNumber(value: photoData.lensPosition)
        zoneMeasurement30.gravityX = Float(photoData.gravityData?.xPosition ?? 0.0)
        zoneMeasurement30.gravityY = Float(photoData.gravityData?.yPosition ?? 0.0)
        zoneMeasurement30.gravityZ = Float(photoData.gravityData?.zPosition ?? 0.0)
        var mmPerPixel:Float = 0.0
        if coinCircle != nil {
            zoneMeasurement30.referenceX = coinCircle!.center.x as NSNumber
            zoneMeasurement30.referenceY = coinCircle!.center.y as NSNumber
            zoneMeasurement30.referenceDiameterInPoints = (coinCircle!.radius * 2) as NSNumber
            if let coinType = coinCircle?.coinType {
                zoneMeasurement30.referenceObject = Int16(coinType.rawValue)
                if let mmCoin = TranslateUtils.coinDiametersInMillemeters[coinType.rawValue] {
                    zoneMeasurement30.referenceDiameterInMillimeters = NSNumber(value: mmCoin)
                    mmPerPixel = TranslateUtils.mmPerSomething(diameter: (Float(coinCircle!.radius * 2)), coinDenomiation: coinType.rawValue)
                }
            } else {
                zoneMeasurement30.referenceObject = 0
            }
        } else {
            zoneMeasurement30.referenceX = -1.0
            zoneMeasurement30.referenceY = -1.0
            zoneMeasurement30.referenceDiameterInPoints = -1.0
            zoneMeasurement30.referenceObject = 0
        }
        zoneMeasurement30.uploadSuccess = false
        
        // ******
        // TODO: asynchronize the calls
        // ******
        //        filenames implicitly set inside the save calls; the property is what they _are_ named, the method is what they _should_ be named
        zoneMeasurement30.saveFullsizedDataAsJPEG(jpegData: photoData.jpegData)
        zoneMeasurement30.saveDisplayDataAsPNG(pngData: photoData.displayPhoto.pngData()!)
        
        // Read full image into UIImage object (not Data object) for clipping
        let jpegImage = zoneMeasurement30.fullsizedImage()
        
        // Now generate new MoleMeasurements
        for (tempId , position) in numericIdToMolePosition {
            var mole30 = numericIdToMole[tempId]
            if mole30 == nil {
                mole30 = Mole30.create()
                mole30!.whichZone = zone30
            }
            mole30!.moleName = numericIdToMolePosition[tempId]?.name
            
            // Create MoleMeasurement object here
            let moleMeasurement30 = MoleMeasurement30.create()
            moleMeasurement30.whichMole = mole30
            moleMeasurement30.whichZoneMeasurement = zoneMeasurement30
            if (mmPerPixel > 0) {
                moleMeasurement30.calculatedMoleDiameter = NSNumber(value: (Float(position.radius) * 2) * mmPerPixel)
                moleMeasurement30.calculatedSizeBasis = 1
            } else {
                moleMeasurement30.calculatedMoleDiameter = -1.0
                moleMeasurement30.calculatedSizeBasis = 0
            }
            
            moleMeasurement30.calculatedSizeBasis = 0
            moleMeasurement30.date = zoneMeasurement30.date
            moleMeasurement30.moleMeasurementDiameterInPoints = (position.radius * 2) as NSNumber
            moleMeasurement30.moleMeasurementX = position.center.x as NSNumber
            moleMeasurement30.moleMeasurementY = position.center.y as NSNumber
            
            if jpegImage != nil {
                //                // Clip image here
                //                // convert display coordinates to full image coordinates
                //                // Note: measurement coordinates are in Portrait orientation but the JPEG is in Landscape orientation
                //                // (and there doesn't seem to be an easy way to "treat" it differently though we could create a new
                //                // rotated version...but why?)
                let fullsizeCircle = TranslateUtils.translateDisplayCircleToJpegCircle(objectPosition: position,
                                                                                       displaySize: photoData.displayPhoto.size,
                                                                                       jpegSize: jpegImage!.size)
                
                if let croppedImage = TranslateUtils.cropMoleInImage(sourceImage: jpegImage!, moleLocation: fullsizeCircle) {
                    //                    moleMeasurement30.saveDataAsJPEG(jpegData: UIImageJPEGRepresentation(croppedImage, 1.0)!)
                    moleMeasurement30.saveDataAsJPEG(jpegData: croppedImage.jpegData(compressionQuality: 1.0)!)
                }
            }
        }
        V30StackFactory.createV30Stack().saveContext()
        
        (UIApplication.shared.delegate as! AppDelegate).refreshBadgeForDashboard()
    }

}
