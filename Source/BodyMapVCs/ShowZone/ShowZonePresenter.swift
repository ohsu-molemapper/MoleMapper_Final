//
//  ShowZonePresenter.swift
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

protocol ShowZonePresentationLogic
{
    func presentActionsMenu(molePosition: MolePosition)
    func presentDeletedMole(moleID: Int)
    func presentHelp(response: PopupHelp.Help.Response)
    func presentHint()
    func presentMoleHistory(mole30: Mole30)
    func presentMoles(response: ShowZone.RetrieveMoles.Response)
    func presentNoHelp()
    func presentRenamedMole(position: MolePosition)
    func presentSelectedMole(moleID: Int)
    func presentUpdatedChanges()
    func presentUpdatedMoles(response: ShowZone.ChangeMoleSizeAndLocation.Response)
}

class ShowZonePresenter: ShowZonePresentationLogic
{
    weak var viewController: ShowZoneDisplayLogic?
    
    
    func presentActionsMenu(molePosition: MolePosition) {
        viewController?.displayActionsMenu(molePosition: molePosition)
    }
    
    func presentDeletedMole(moleID: Int) {
        viewController?.deleteMoleFromScreen(moleID: moleID)
    }
    
    func presentHelp(response: PopupHelp.Help.Response) {
        // Hypothetically, the presenter could tweak the help text (e.g. choose the font, the font size, etc.)
        let model = PopupHelp.Help.ViewModel(title: response.helpTitle, text: response.helpText)
        viewController?.displayHelp(viewModel: model)
    }
    
    func presentHint() {
        viewController?.displayHint()
    }
    
    func presentMoleHistory(mole30: Mole30) {
        viewController?.displayMoleHistory(mole30: mole30)
    }
    
    func presentMoles(response: ShowZone.RetrieveMoles.Response)
    {
        for (_, mole) in response.molePositions {
            if CGFloat(truncating: mole.molePhysicalSize) > 0.0 {
                let formatter = NumberFormatter()
                formatter.maximumFractionDigits = 1
                mole.moleDetails = "Size: " + (formatter.string(from: mole.molePhysicalSize) ?? "bad") + " mm"
            } else {
                mole.moleDetails = "Size: n/a"
            }
        }
        
        let viewModel = ShowZone.RetrieveMoles.ViewModel(molePositions: response.molePositions, fullImage: response.fullImage)
        viewController?.displayMoles(viewModel: viewModel)
    }
    
    func presentNoHelp() {
        viewController?.noHelp()
    }
    
    func presentRenamedMole(position: MolePosition) {
        viewController?.displayRenamedMole(position: position)
    }
    
    func presentSelectedMole(moleID: Int) {
        viewController?.displaySelectedMole(moleID: moleID)

    }
    
    func presentUpdatedChanges(){
        viewController?.updateMolesChangedFlag()
    }
    
    func presentUpdatedMoles(response: ShowZone.ChangeMoleSizeAndLocation.Response) {
        print(#function + " - not implemented yet")
    }
}

// Helper methods
extension ShowZonePresenter {
    func selectMole(moles: [MolePosition], selectedMole: Int) -> ShowZone.ViewModel{
        let viewModel = ShowZone.ViewModel(moles: moles)
        // set new Mole as selected
        for mole in viewModel.moles {
            if mole.objectID == selectedMole {
                if mole.state != .selected {
                    mole.state = .selected
                } else {
                    mole.state = .unselected
                }
            } else {
                mole.state = .unselected
            }
        }
        return viewModel
    }
}
