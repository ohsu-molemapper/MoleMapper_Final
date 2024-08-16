//
//  IdentifyMolesPresenter
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

protocol IdentifyMolesPresentationLogic
{
    func presentHelp(response: PopupHelp.Help.Response)
    func presentActionMenu(_ position: ObjectPosition)
    func presentHint()
    func presentNoHelp()
    func presentSavedMoles()
    
    // Refactoring methods
    func presentBatchUpdateMoleDetails(circles: ObjectPositionDictionary)
    func presentChangedCirclePosition(response: IdentifyMoles.ChangeCirclePosition)
    func presentDeletedMole(_ circleID: Int)
    // TODO: either rename to DeletedObject or add DeletedMole
    func presentNewMole(mole: MolePosition)
    func presentNewCoin(coin: CoinPosition)
//    func presentRemovedMole30(mole30: Mole30)
    func presentRenamedMole(moleID: Int, newName: String)
    func presentSelectedMole(_ circleID: Int)
    func presentUpdatedCoin(coinPosition: CoinPosition)
}

class IdentifyMolesPresenter: IdentifyMolesPresentationLogic
{
    
    weak var viewController: IdentifyMolesDisplayLogic?
    
    func presentChangedCirclePosition(response: IdentifyMoles.ChangeCirclePosition) {
        viewController?.updateCirclePosition(response)
    }
    
    func presentDeletedMole(_ circleID: Int) {
        viewController?.deleteCircle(circleID)
    }
    
    func presentSelectedMole(_ circleID: Int) {
        viewController?.selectCircle(circleID)
    }

    func presentDeselectedCircle(_ circleID: Int) {
        viewController?.deselectCircle(circleID)
    }
    
    func presentHelp(response: PopupHelp.Help.Response) {
        let model = PopupHelp.Help.ViewModel(title: response.helpTitle, text: response.helpText)
        viewController?.displayHelp(viewModel: model)
    }
   
    func presentHint() {
        viewController?.displayHint()
    }
    
    func presentActionMenu(_ position: ObjectPosition) {
        viewController?.displayActionMenu(position)
    }
    
    func presentNewMole(mole: MolePosition) {
        if CGFloat(truncating: mole.molePhysicalSize) > 0.0 {
            let formatter = NumberFormatter()
            formatter.maximumFractionDigits = 1
            mole.moleDetails = "Size: " + (formatter.string(from: mole.molePhysicalSize) ?? "bad")
        }else{
            mole.moleDetails = "Size: n/a"
        }
        
        viewController?.addObject(mole)
    }

    func presentNewCoin(coin: CoinPosition) {
        viewController?.addObject(coin)
    }
    
    func presentRenamedMole(moleID: Int, newName: String) {
        viewController?.updateMoleName(moleID, newName: newName)
    }

    func presentNoHelp() {
        viewController?.helpFinished()
    }
    
    func presentSavedMoles() {
        viewController?.molesSaved()
    }
    
    func presentBatchUpdateMoleDetails(circles: ObjectPositionDictionary) {
        for (_, position) in circles {
            if let moleCircle = position as? MolePosition {
                if CGFloat(truncating: moleCircle.molePhysicalSize) > 0.0 {
                    let formatter = NumberFormatter()
                    formatter.maximumFractionDigits = 1
                    moleCircle.moleDetails = "Size: " + (formatter.string(from: moleCircle.molePhysicalSize) ?? "bad")
                }else{
                    moleCircle.moleDetails = "Size: n/a"
                }
            }
        }
        viewController?.batchUpdateMoleDetails(circles)
    }
    
    func presentUpdatedCoin(coinPosition: CoinPosition) {
        viewController?.updateCoinType(coinPosition: coinPosition)
    }
}

// Helper methods
extension IdentifyMolesPresenter {
    func selectMole(circles: [ObjectPosition], selectedMole: Int) -> IdentifyMoles.ViewModel{
        
        // set new Mole as selected
        for circle in circles {
            if circle.objectID == selectedMole {
                if circle.state != .selected {
                    circle.state = .selected
                }else{
                    circle.state = .unselected
                }
            }else{
                circle.state = .unselected
            }
        }
        
        let viewModel = IdentifyMoles.ViewModel(circles: circles)
        return viewModel
    }
}
