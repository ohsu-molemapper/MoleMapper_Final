//
//  TapCoinPresenter
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

protocol IdentifyCoinPresentationLogic
{
    func presentCoinActionMenu()
    func presentCoinWithCointype(coinType: CoinType)
    func presentHelp(response: PopupHelp.Help.Response)
    func presentHint()
    func presentNewCoin(at coinPosition: CoinPosition)
    func presentNoHelp()
    func presentRemoveCoin()
    func presentSelectedCoin(state: CircleState)
    func presentChangedCirclePosition(to newPosition: CirclePosition)
}

class IdentifyCoinPresenter: IdentifyCoinPresentationLogic
{
    weak var viewController: IdentifyCoinDisplayLogic?
    
    func presentCoinActionMenu() {
        viewController?.displayActionMenu()
    }
    
    func presentCoinWithCointype(coinType: CoinType) {
        viewController?.changeCoinType(newType: coinType)
    }
    
    func presentHelp(response: PopupHelp.Help.Response) {
        let model = PopupHelp.Help.ViewModel(title: response.helpTitle, text: response.helpText)
        viewController?.displayHelp(viewModel: model)
    }
    
    func presentHint() {
        viewController?.displayHint()
    }
    
    func presentNewCoin(at coinPosition: CoinPosition) {
        viewController!.displayNewCoin(at: coinPosition)
    }
    
    func presentChangedCirclePosition(to newPosition: CirclePosition) {
        viewController!.displayCoin(at: newPosition)
    }
    
    func presentNoHelp() {
        viewController?.noHelp()
    }
    
    func presentRemoveCoin() {
        viewController?.removeCoin()
    }
    
    func presentSelectedCoin(state: CircleState){
        viewController?.displaySelectedCoin(state: state)
    }
}

