//
//  IdentifyMolesModels
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

enum IdentifyMoles
{
    enum InitModel
    {
        struct Request
        {
            var photoData: TakePhoto.PhotoData
            var coinData: CoinPosition?
            var molesData: ShowZone.MolesData?
            var zoneID: String
            var scrollSize: CGSize
        }
        struct Response
        {
            var lastID = 0
            var circles: ObjectPositionDictionary
            var coinCircle: CoinPosition? = nil
        }
    }
        
    enum SelectCircle
    {
        struct Response {
            var atLocation: CGPoint
            var circles: [ObjectPosition]
        }
    }
    
    struct ChangeCirclePosition {
        // used by VC, Interactor, and Presenter
        var widgetID: Int
        var centerInImage: CGPoint
        var sizeInImage: CGSize
    }
    
    enum RenameMole {
        struct Request {
            var newName: String
            var moleID: Int
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
    
    enum RecordResults
    {
        struct Request
        {
            var moleID:Int
            var removedMolesToDiagnoses:[Any]
            var removedMoleRecord:[AnyHashable : Any]
        }
    }
    
    enum MarkAsCoin
    {
        struct Request
        {
            var coinType: CoinType
            var selectedID: Int
        }
    }
    
    enum UpdateCoin
    {
        struct Request
        {
            var coinType: CoinType
            var selectedID: Int
        }
    }
    
    // General response that will use most of the methods of the presenter
    struct Response
    {
        var circles: [ObjectPosition]
        var selectedCircle: Int
        var photoEdges: PhotoEdges?
        
        init(circles: [ObjectPosition], selectedCircle: Int = -1, photoEdges: PhotoEdges? = nil){
            self.circles = circles
            self.selectedCircle = selectedCircle
            self.photoEdges = photoEdges
        }
    }
    
    // All the methods that call view controller from presenter will use the same ViewModel
    struct ViewModel{
        var circles: [ObjectPosition]
        var photoEdges: PhotoEdges?
        
        // Maybe at some point we will have to init the array with some circles
        init(circles: [ObjectPosition], photoEdges: PhotoEdges? = nil){
            self.circles = circles
            self.photoEdges = photoEdges
        }
    }
}


struct PhotoEdges {
    var minimumPosition:CGPoint
    var maximumPosition:CGPoint
}
