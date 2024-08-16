//
//  ExtendedCirclePosition.swift
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
import UIKit

typealias ObjectPositionDictionary = [Int:ObjectPosition]
typealias MolePositionDictionary = [Int:MolePosition]

enum CircleState {
    case unselected, selected
}

enum MoleStatus {
    case new, removedWaiting, removedRecorded, existingConfident, existingNotConfident, unspecified
}

enum MoleSizeConstants: CGFloat {
    case minimumRadius = 5.0, defaultRadius = 20.0
}

enum CoinType: Int {
    case penny = 1
    case nickle = 5
    case dime = 10
    case quarter = 25
    
    /**
     returns standard English name for US Coins
     */
    func toString() -> String {
        switch self {
        case .penny:
            return "Penny"
        case .nickle:
            return "Nickle"
        case .dime:
            return "Dime"
        case .quarter:
            return "Quarter"
        }
    }
    // Display sequence. Could be alphabetical, could be domination-value based. Going with #2 for now.
    // We should test this (though I doubt consensus would be reached).
    static let pickSequence = [penny, nickle, dime, quarter]
}

class ObjectPosition : CirclePosition {
    var objectID: Int = 0
    var state: CircleState = .unselected
//    var realRadius = CGFloat(0)
//    var realCenter: CGPoint = CGPoint()
    var name = ""
    
    init(withID objectID:Int, atLocation location:CGPoint, ofRadius radius: CGFloat,
         withObjectName name:String = "",
         withState state: CircleState = .unselected)
    {
        super.init(center: location, radius: radius)
        self.objectID = objectID
        self.name = name
        self.state = state
    }
    
    func hitTest(pt: CGPoint) -> Bool {
        let minRadius = max(24.0, radius)
        if (pt.x >= (center.x - minRadius)) && (pt.x < (center.x + minRadius)) &&
            (pt.y >= (center.y - minRadius)) && (pt.y < (center.y + minRadius)) {
            return true
        }
        return false
    }
}

class CoinPosition: ObjectPosition {
    var coinType:CoinType = .penny
    var shouldShowMenu:Bool = true  // TODO -- is this needed still?

    init(withID objectID:Int, atLocation location: CGPoint, ofRadius radius: CGFloat,
         withState state: CircleState = .unselected,
         withCoinType coinType: CoinType)
    {
        super.init(withID: objectID, atLocation: location, ofRadius: radius,
                   withObjectName: coinType.toString(),
                   withState: state)
        self.coinType = coinType
    }
}

class MolePosition: ObjectPosition {
    var status: MoleStatus = .unspecified
    var molePhysicalSize: NSNumber = 0
    var moleDetails: String = ""

    init(withID objectID:Int, atLocation location:CGPoint, ofRadius radius: CGFloat,
         withObjectName name:String = "",
         withState state: CircleState = .unselected,
         withStatus status: MoleStatus = .unspecified)
    {
        super.init(withID: objectID, atLocation: location, ofRadius: radius,
                   withObjectName: name,
                   withState: state)
        self.status = status
    }
}
