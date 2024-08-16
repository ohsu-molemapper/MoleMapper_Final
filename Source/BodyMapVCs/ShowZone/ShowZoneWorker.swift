//
//  ShowZoneWorker.swift
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

class ShowZoneWorker
{
    func deleteMole(moleID: Int, numericIdToMole: [Int:Mole30]){
        if let mole = numericIdToMole[moleID] {
            // Delete mole
            let stack = V30StackFactory.createV30Stack()
            stack.managedContext.delete(mole)
            stack.saveContext()
        }
    }
    
    func retrieveHelp() -> (helpTitle: String, helpText: NSAttributedString) {
        let helpTitle = "Review Zone"
        let helpText = RTFHelpers.getAttributedText(fromFile: "ViewZone")
        return (helpTitle, helpText)
    }
    
    func retrieveMoles(with zoneID: String, andScrollSize scrollSize: CGSize, andScrollZoomScale scrollZoomScale: CGFloat) -> ShowZone.RetrieveMoles.Response
    {
        let displayPhoto = Zone30.latestDisplayImageForZoneID(zoneID)
        let fullImage = Zone30.latestFullImageForZoneID(zoneID)
        let moles = Zone30.allMolesInZoneForZoneID(zoneID)
        var lastID = 0
        var molePositions: MolePositionDictionary = [:]
        var numericIdToMole: [Int:Mole30] = [:]
        var originalMoleMeasurements: [Int:MoleMeasurement30] = [:]

        // These are normally (in IdentifyMoles, IdentifyCoin) set in viewDidLayoutSubviews()
        guard let largeImage = fullImage, let smallImage = displayPhoto else { fatalError() }
        IdentifySharedWorker.largeImageSize = largeImage.size
        IdentifySharedWorker.smallImageSize = smallImage.size
        
        if moles != nil {
            for mole in moles! {
                if let moleMeasurement = (mole as! Mole30).mostRecentMeasurement() {
                    let radius: CGFloat = CGFloat(truncating: moleMeasurement.moleMeasurementDiameterInPoints!) / 2.0
                    let center = CGPoint(x: (moleMeasurement.moleMeasurementX! as! CGFloat),
                                         y: (moleMeasurement.moleMeasurementY! as! CGFloat))
                    
                    let status:MoleStatus = .existingConfident
                    
                    var moleSize = NSNumber(value: 0)
                    if let moleDiameter = moleMeasurement.calculatedMoleDiameter {
                        moleSize = moleDiameter
                    }
                    
                    let moleCircle = MolePosition(withID: lastID, atLocation: center, ofRadius: radius,
                                                  withObjectName: (mole as! Mole30).moleName!,
                                                  withState: .unselected, withStatus: status)
                    moleCircle.molePhysicalSize = moleSize
                    
                    molePositions[lastID] = moleCircle
                    
                    numericIdToMole[lastID] = mole as? Mole30
                    originalMoleMeasurements[lastID] = moleMeasurement
                    lastID += 1
                }
            }
        }
        
        let response = ShowZone.RetrieveMoles.Response(molePositions: molePositions, fullImage: largeImage, lastID: lastID, numericIdToMole: numericIdToMole, originalMoleMeasurements: originalMoleMeasurements)
        return response
    }
    
    func renameMole(moleID: Int, newName:String, numericIdToMole: [Int:Mole30]){
        if let mole = numericIdToMole[moleID] {
            mole.moleName = newName
            V30StackFactory.createV30Stack().saveContext()
        }
    }
    
    func removeMoleWaitingForResults(moleID: Int, numericIdToMole: [Int:Mole30]){
        if let mole = numericIdToMole[moleID] {
            mole.waitingForResults = true
            mole.moleWasRemoved = true
            V30StackFactory.createV30Stack().saveContext()
        }
    }
    
    func removeMoleRecordResults(moleID: Int, numericIdToMole: [Int:Mole30], removedMolesToDiagnoses:[Any], removedMoleRecord:[AnyHashable : Any]){
        if let mole = numericIdToMole[moleID] {
            mole.waitingForResults = false
            mole.moleWasRemoved = true
            V30StackFactory.createV30Stack().saveContext()
            
        }
    }
    
}
