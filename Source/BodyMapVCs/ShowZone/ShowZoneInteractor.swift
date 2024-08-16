//
//  ShowZoneInteractor.swift
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

protocol ShowZoneBusinessLogic
{
    func deleteMole(moleID: Int)
    func longPressMole(moleID: Int)
    func renameMole(request: ShowZone.RenameMole.Request)
    func requestHelp(request: PopupHelp.Help.Request)
    func requestHint()
    func retrieveMole30ForViewHistory(moleID: Int)
    func retrieveMoles(request: ShowZone.RetrieveMoles.Request)
    func selectMole(moleID: Int)
    func showActionsMenu(moleID: Int)
    func updateDataBase()
    func userZoomed()
}

protocol ShowZoneDataStore
{
    var molesData: ShowZone.MolesData { get set }
}

class ShowZoneInteractor: ShowZoneBusinessLogic, ShowZoneDataStore
{
    var presenter: ShowZonePresentationLogic?
    var worker: ShowZoneWorker?
    var molesData: ShowZone.MolesData = ShowZone.MolesData(numericIdToMole: [:], originalMoleMeasurements: [:])
    var molePositions: MolePositionDictionary = [:]
    var lastID = 0
    var moleChangesQueue: [MoleChange] = []
    var autoSave = true
    
    var userIsActive = false
    
    func addMoleChangeToQueue(moleChange: MoleChange){
        // if autoSave == true, we will do the change in Core Data
        // if autoSave is false, we will add the change to the queue
        if autoSave {
            saveChangeInCoreData(change: moleChange)
        }else{
            moleChangesQueue.append(moleChange)
        }
    }
    
    func deleteMole(moleID: Int) {
        if molePositions[moleID] != nil {
            let moleChange = MoleChange(moleID: moleID, changeType: .delete)
            addMoleChangeToQueue(moleChange: moleChange)
            molePositions.removeValue(forKey: moleID)
        }
        presenter?.presentDeletedMole(moleID: moleID)
    }
    
    func retrieveMoles(request: ShowZone.RetrieveMoles.Request)
    {
        worker = ShowZoneWorker()
        let response = worker!.retrieveMoles(with: request.zoneID, andScrollSize: request.scrollSize, andScrollZoomScale: request.scrollZoomScale)
        molePositions = response.molePositions
        lastID = response.lastID
        molesData.numericIdToMole = response.numericIdToMole
        molesData.originalMoleMeasurements = response.originalMoleMeasurements
        moleChangesQueue = []
        autoSave = request.autoSave
        
        presenter?.presentMoles(response: response)
    }
    
 
    func retrieveMole30ForViewHistory(moleID: Int) {
        if let mole30 = molesData.numericIdToMole[moleID] {
            presenter?.presentMoleHistory(mole30: mole30)
        }
    }
    
    func renameMole(request: ShowZone.RenameMole.Request) {
        if let molePosition = molePositions[request.moleID] {
            molePosition.name = request.newName
            let moleChange = MoleChange(moleID: request.moleID, changeType: .rename, newName:request.newName)
            addMoleChangeToQueue(moleChange: moleChange)
            presenter?.presentRenamedMole(position: molePosition)
        }

    }

    func requestHelp(request: PopupHelp.Help.Request) {
        // Query worker for content
        var requestCleared = true  // default case unless first time and autoPopup
        if (request.requestType == .autoPopup) {
            if PopupTracker.hasSeen("ZoneHelp") || UserDefaults.areHelpScreensDisabled {
                requestCleared = false
            }
        }
        if requestCleared {
            let helpData = ShowZoneWorker().retrieveHelp()
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
        
    func selectMole(moleID: Int) {
        userIsActive = true
        presenter?.presentSelectedMole(moleID: moleID)
    }
    
    func longPressMole(moleID: Int) {
        if let molePosition = molePositions[moleID] {
            presenter?.presentActionsMenu(molePosition: molePosition)
        }
    }

    func showActionsMenu(moleID: Int) {
        
        if let molePosition = molePositions[moleID] {
            presenter?.presentActionsMenu(molePosition: molePosition)
        }
    }
    
    func updateDataBase(){
        for change in moleChangesQueue {
            saveChangeInCoreData(change: change)
        }
        // clean changes queue
        moleChangesQueue = []
        
        presenter?.presentUpdatedChanges()
    }
    
    func saveChangeInCoreData(change: MoleChange){
        switch change.changeType {
        case .rename:
            if let newName = change.newName {
                worker?.renameMole(moleID: change.moleID, newName: newName, numericIdToMole: molesData.numericIdToMole)
            }
            break
        case .delete:
            worker?.deleteMole(moleID: change.moleID, numericIdToMole: molesData.numericIdToMole)
            // Remove mole from arrays in molesData structure
            molesData.numericIdToMole.removeValue(forKey: change.moleID)
            molesData.originalMoleMeasurements.removeValue(forKey: change.moleID)
            break
        case .markAsCoin:
            // This option is not available y show zone scene
            break
        }
    }
    
    func userZoomed() {
        // Fix for #344
        userIsActive = true
    }
}
