//
//  IdentifyMolesInteractor
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

protocol IdentifyMolesBusinessLogic
{
    func initModel(request: IdentifyMoles.InitModel.Request)
    func renameMole(request: IdentifyMoles.RenameMole.Request)
    func saveMolesAndCoinInDataBase()
    func showActionMenu(objectID: Int)
    func updateCoinInfo(request: IdentifyMoles.UpdateCoin.Request)
    
    // refactored methods
    func changeCirclePosition(request: IdentifyMoles.ChangeCirclePosition)
    func deleteCircle(_ circleID: Int)
    func markMoleAsCoin(circleID: Int, coinType: CoinType)
    func newMole(at imageLocation: CGPoint)
    func requestHelp(requestType: PopupHelp.RequestType)
    func requestHint()
    
    func userZoomed()
}

class IdentifyMolesInteractor: IdentifyMolesBusinessLogic
{
    var photoData: TakePhoto.PhotoData?
    var molesData: ShowZone.MolesData?
    var zoneID: String = ""
    var scrollSize: CGSize = CGSize.zero
    var photoEdges: PhotoEdges = PhotoEdges(minimumPosition: CGPoint.zero, maximumPosition: CGPoint.zero)
    var moleChangesQueue: [MoleChange] = []
    
    var circles = ObjectPositionDictionary()
    
    fileprivate var nextID = 0
    
    var presenter: IdentifyMolesPresentationLogic?
    
    var userIsActive = false
 
    func changeCirclePosition(request: IdentifyMoles.ChangeCirclePosition) {
        // test to see if we've gone off the rails or not...
        if isLocationInsideTheEdges(point: request.centerInImage) {
            // Fix for Bug 328:
            let centerRelativeToImage = IdentifySharedWorker.imageViewToAspectFitImage(imageViewPoint: request.centerInImage)
            circles[request.widgetID]!.center = centerRelativeToImage
            circles[request.widgetID]!.radius = request.sizeInImage.width / 2.0

            presenter?.presentChangedCirclePosition(response: request)
        }
        else {
            let fixedPoint = fixLocationInsideTheEdges(point: request.centerInImage)
            let newRequest = IdentifyMoles.ChangeCirclePosition(widgetID: request.widgetID,
                                                                centerInImage: fixedPoint,
                                                                sizeInImage: request.sizeInImage)
            // Fix for Bug 328:
            circles[request.widgetID]!.center = newRequest.centerInImage
            circles[request.widgetID]!.radius = newRequest.sizeInImage.width / 2.0

            presenter?.presentChangedCirclePosition(response: newRequest)
        }
    }


    
    func deleteCircle(_ circleID: Int) {
        // Remove mole from core data cache
        if molesData != nil {
            // If this condition == true it means that the renamed mole is an existing mole in CoreData
            if let _ = molesData!.numericIdToMole[circleID]{
                let moleChange = MoleChange(moleID: circleID, changeType: .delete)
                moleChangesQueue.append(moleChange)
            }
        }
        // Remove mole from positions array
        let circle = circles[circleID]
        if circle is CoinPosition {
            // need to undo size estimates if we're removing the coin
            for (_, position) in circles {
                if let molePosition = position as? MolePosition {
                    // update model then notify VC to update widget
                    molePosition.molePhysicalSize = 0
                }
            }
            presenter?.presentBatchUpdateMoleDetails(circles: circles)
        }
        circles.removeValue(forKey: circleID)
        presenter?.presentDeletedMole(circleID)
    }
    
    func requestHelp(requestType: PopupHelp.RequestType) {
        // As always, defer the "how" to the worker
        var requestCleared = true  // default case unless first time and autoPopup
        if (requestType == .autoPopup) {
            if PopupTracker.hasSeen("IdentifyMoleHelp") || UserDefaults.areHelpScreensDisabled {
                requestCleared = false
            }
        }
        if requestCleared {
            let helpData = IdentifyMolesWorker.retrieveHelp()
            let response = PopupHelp.Help.Response(title: helpData.helpTitle, text: helpData.helpText)
            presenter?.presentHelp(response: response)
        }
        else {
            presenter?.presentNoHelp()
        }
    }
    
    func requestHint() {
        if !userIsActive && UserDefaults.areHintsEnabled {
            presenter?.presentHint()
        }
    }
    
    func initModel(request: IdentifyMoles.InitModel.Request) {
        // Need some changes for remeasure?
        photoData = request.photoData
        molesData = request.molesData
        zoneID = request.zoneID
        scrollSize = request.scrollSize
        photoEdges = IdentifySharedWorker.calculatePhotoEdges(scrollSize: scrollSize, displayPhoto: photoData!.displayPhoto)
        
        var coinPosition: CoinPosition?
        
        // Deal with coming in from a re-measurement
        if molesData != nil || request.coinData != nil {
            let initModelResponse = IdentifyMolesWorker.retrieveMoles(with: photoData!.displayPhoto, andScrollSize: scrollSize, andMolesData: molesData, andCoinData: request.coinData)
            
            circles = initModelResponse.circles
            nextID = initModelResponse.lastID

            for (_, circle) in circles {
                if let mole = circle as? MolePosition {
                    // Auto encircle if needed
                    detectMole(mole: mole)
                    // Calculate mole physical size
                    if request.coinData != nil {
                        if let coinCircle = initModelResponse.coinCircle {
                            calculateMolePhysicalSize(coinCircle: coinCircle, moleCircle: mole)
                        }
                    }
                    presenter?.presentNewMole(mole: mole)
                }
                if let coin = circle as? CoinPosition {
                    coinPosition = coin
                }
            }
        }
        else {
            nextID = 0
        }
        
        moleChangesQueue = []
        
        presenter?.presentBatchUpdateMoleDetails(circles: circles)
        if coinPosition != nil {
            presenter?.presentNewCoin(coin: coinPosition!)
        }
    }
    
    func markMoleAsCoin(circleID: Int, coinType: CoinType) {
        var newCoin: CoinPosition? = nil
        if let moleCircle = circles[circleID] as? MolePosition {
            // This can be done with new moles only
            if moleCircle.status == .new {
                newCoin = IdentifyMolesWorker.convertMoleToCoin(moleCircle: moleCircle, lastID: nextID, coinType: coinType)
                // Delete original mole
                deleteCircle(circleID)
            }
        }
        if newCoin != nil {
            // Delete existing coin if it exists
            for (_, circle) in circles {
                if let coinCircle = circle as? CoinPosition {
                    deleteCircle(coinCircle.objectID)
                    break
                }
            }
            // Add new coin to circles array
            circles[nextID] = newCoin
            nextID += 1
            for (_, circle) in circles {
                if let moleCircle = circle as? MolePosition {
                    calculateMolePhysicalSize(coinCircle: newCoin!, moleCircle: moleCircle)
                }
            }
            presenter?.presentNewCoin(coin: newCoin!)
            presenter?.presentBatchUpdateMoleDetails(circles: circles)
        }
    }
    
    func newMole(at smallImageLocation: CGPoint) {
        if isLocationInsideTheEdges(point: smallImageLocation) {
            let defaultRadius = MoleSizeConstants.defaultRadius.rawValue
            let detectedPosition = MolePosition(withID: nextID, atLocation: smallImageLocation, ofRadius: defaultRadius,
                                    withState: .selected,
                                    withStatus: .new)

            userIsActive = true
          // Detect mole (modifies mole if found in image)
            detectMole(mole: detectedPosition)
            
            // Quick check to see if this is pretty close to an already found
            // mole. If so, just select it.
            let newPosition = detectedPosition
            
            // Note: formerly (as recently as 488bef569f30263beb739c6e075fcad116428f3a) dead code was here to
            // detect overlapping moles but that is actually handled outside of this code.
            circles[nextID] = newPosition
            nextID += 1

            if let coinCircle = findCoinInCircles(circles) {
                calculateMolePhysicalSize(coinCircle: coinCircle, moleCircle: newPosition)
            }
            
            if newPosition.name == "" {
                let mng = MoleNameGenerator()
                let moleNameGender = UserDefaults.moleNameGender
                newPosition.name = mng.randomUniqueMoleName(withGenderSpecification: moleNameGender)
            }
            presenter?.presentNewMole(mole: newPosition)
        }
    }
    
    func renameMole(request: IdentifyMoles.RenameMole.Request) {
        if let mole = circles[request.moleID] as? MolePosition {
            mole.name = request.newName
            if molesData != nil {
                // If this condition == true it means that the renamed mole is an existing mole in CoreData
                if let _ = molesData!.numericIdToMole[mole.objectID]{
                    let moleChange = MoleChange(moleID: request.moleID, changeType: .rename, newName:request.newName)
                    moleChangesQueue.append(moleChange)
                }
            }
            presenter?.presentRenamedMole(moleID: mole.objectID, newName: mole.name)
        }
    }
    
    func saveMolesAndCoinInDataBase() {
        for change in moleChangesQueue {
            switch change.changeType {
            case .rename:
                if let newName = change.newName {
                    IdentifyMolesWorker.renameMole(moleID: change.moleID, newName: newName, numericIdToMole: molesData!.numericIdToMole)
                }
                break
            case .delete:
                IdentifyMolesWorker.deleteMole(moleID: change.moleID, numericIdToMole: molesData!.numericIdToMole)
                // Remove mole from arrays in molesData structure
                molesData!.numericIdToMole.removeValue(forKey: change.moleID)
                molesData!.originalMoleMeasurements.removeValue(forKey: change.moleID)
                break
            case .markAsCoin:
                // This option is not available y show zone scene
                break
            }
        }
        // clean changes queue
        moleChangesQueue = []
        
        IdentifyMolesWorker.saveMolesAndCoinInDataBase(photoData: photoData!, zoneID: zoneID, scrollSize: scrollSize, circles: circles, molesData: molesData)
        
        presenter?.presentSavedMoles()
    }

    func showActionMenu(objectID: Int) {
        presenter?.presentActionMenu(circles[objectID]!)
    }
    
    func updateCoinInfo(request: IdentifyMoles.UpdateCoin.Request) {
        if let coinCircle = findCoinInCircles(circles){
            coinCircle.coinType = request.coinType
            coinCircle.name = request.coinType.toString()
            for (_, circle) in circles {
                if let moleCircle = circle as? MolePosition {
                    calculateMolePhysicalSize(coinCircle: coinCircle, moleCircle: moleCircle)
                }
            }
            presenter?.presentUpdatedCoin(coinPosition: coinCircle)
            presenter?.presentBatchUpdateMoleDetails(circles: circles)
        }
    }
    
    func userZoomed() {
        // Fix for #344
        userIsActive = true
    }

}

// Helper methods
extension IdentifyMolesInteractor {
    func calculateMolePhysicalSize(coinCircle: CoinPosition, moleCircle: MolePosition){
        let mmPerPixel = TranslateUtils.mmPerSomething(diameter: (Float(coinCircle.radius * 2)), coinDenomiation: coinCircle.coinType.rawValue)
        let moleSize = NSNumber(value: (Float(moleCircle.radius) * 2) * mmPerPixel)
        moleCircle.molePhysicalSize = moleSize
    }

    func detectMole(mole: MolePosition) {
        let newCirclePosition = IdentifySharedWorker.autoEncircleMole(smallImage: photoData!.displayPhoto, mole: mole, scrollSize: scrollSize)
        // Update mole
        mole.center = newCirclePosition.center
        mole.radius = newCirclePosition.radius
    }
    
    func isLocationInsideTheEdges(point: CGPoint) -> Bool {
        if point.y < 0 {
            return false
        }
        if point.y > photoData!.displayPhoto.size.height {
            return false
        }
        if point.x < 0 {
            return false
        }
        if point.x > photoData!.displayPhoto.size.width {
            return false
        }
        return true
    }
    
    func findCoinInCircles(_ circles: ObjectPositionDictionary) -> CoinPosition? {
        for (_, circle) in circles {
            if let coinCircle = circle as? CoinPosition {
                return coinCircle
            }
        }
        return nil
    }
    
    func fixLocationInsideTheEdges(point: CGPoint) -> CGPoint {
        var newPoint = point
        if newPoint.y > photoEdges.maximumPosition.y {
            newPoint.y = photoEdges.maximumPosition.y
        }
        if newPoint.y < photoEdges.minimumPosition.y {
            newPoint.y = photoEdges.minimumPosition.y
        }
        if newPoint.x > photoEdges.maximumPosition.x {
            newPoint.x = photoEdges.maximumPosition.x
        }
        if newPoint.x < photoEdges.minimumPosition.x {
            newPoint.x = photoEdges.minimumPosition.x
        }
        return newPoint
    }

}
