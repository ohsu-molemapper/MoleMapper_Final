//
//  ShowZoneModels.swift
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

enum ShowZone
{
    enum RetrieveMoles
    {
        struct Request
        {
            var zoneID: String
            var zoneTitle: String
            var scrollSize: CGSize
            var scrollZoomScale: CGFloat
            var autoSave: Bool
            init(zoneID: String, zoneTitle: String, scrollSize: CGSize, scrollZoomScale: CGFloat = 1.0, autoSave: Bool = true){
                self.zoneID = zoneID
                self.zoneTitle = zoneTitle
                self.scrollSize = scrollSize
                self.scrollZoomScale = scrollZoomScale
                self.autoSave = autoSave
            }
        }
        struct Response
        {
            var molePositions:MolePositionDictionary
            var fullImage:UIImage
            var lastID: Int
            var numericIdToMole: [Int:Mole30]
            var originalMoleMeasurements: [Int:MoleMeasurement30]
        }
        struct ViewModel
        {
            var molePositions:MolePositionDictionary
            var fullImage:UIImage
            
            init(molePositions: MolePositionDictionary, fullImage: UIImage){
                self.molePositions = molePositions
                self.fullImage = fullImage
            }
        }
    }
    
    enum ChangeMoleSizeAndLocation
    {
        struct Request
        {
            var scrollViewZoomScale: CGFloat
        }
        struct Response
        {
            var scrollViewZoomScale: CGFloat
            var moles:[MolePosition]
        }
    }
    
    enum SelectMole
    {
        struct Request {
            var atLocation: CGPoint
        }
        struct Response {
            var atLocation: CGPoint
            var moles: [MolePosition]
        }
    }
    
    enum PinTapped
    {
        struct Request
        {
            var moleID:Int
        }
        struct Response
        {
            var moleID:Int
            var moles:[MolePosition]
        }
    }
    
    enum ShowMoleMenu
    {
        struct Request
        {
            var moleID:Int
        }
        struct Response
        {
            var mole:MolePosition
        }
        struct ViewModel
        {
            var mole:MolePosition
        }
    }
    
    enum RetrieveMole30
    {
        struct Request{
            var moleID: Int
        }
        struct Response{
            var mole: Mole30
        }
        struct ViewModel{
            var mole: Mole30
        }
    }
    
    enum RenameMole
    {
        struct Request{
            var newName: String
            var moleID: Int
        }
        
        struct Response
        {
            var moles:[MolePosition]
        }
    }
    
    enum RemoveMole
    {
        struct Request
        {
            var moleID:Int
        }
        struct Response
        {
            var moles:[MolePosition]
        }
    }

    enum RecordResults
    {
        struct Request
        {
            var moleID:Int
            var removedMolesToDiagnoses:[Any]
            var removedMoleRecord:[AnyHashable : Any]
        }
        struct Response
        {
            var moles:[MolePosition]
        }
    }
    
    enum DeleteMole
    {
        struct Request{
            var moleID: Int
        }
        
        struct Response
        {
            var moleID: Int
        }
        
        struct ViewModel
        {
            var moleID: Int
        }
    }
    
    struct ViewModel
    {
        var moles:[MolePosition]
    }
    
    struct MolesData
    {
        var numericIdToMole: [Int:Mole30]
        var originalMoleMeasurements: [Int:MoleMeasurement30]
    }
}

enum ChangeType
{
    case rename, delete, markAsCoin
}

struct MoleChange
{
    let moleID:Int
    let changeType:ChangeType
    let newName:String?
    init(moleID:Int, changeType:ChangeType, newName: String? = nil) {
        self.moleID = moleID
        self.changeType = changeType
        self.newName = newName
    }
}
