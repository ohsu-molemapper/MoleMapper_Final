//
//  TapCoinInteractor
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

protocol IdentifyCoinBusinessLogic
{
    func calculatePhotoEdges(request: IdentifyCoin.GetPhotoEdges.Request)
    func changeCoinPosition(to newPosition: CirclePosition)
    func showCoinActionMenu()
    func requestHelp(request: PopupHelp.Help.Request)
    func requestHint()
    func newCoin(at coinPosition: CGPoint)
    func selectCoin(_ selected: Bool)
    func setCoinTypeToCoin(coinType: CoinType?)
    func userZoomed()
}

class IdentifyCoinInteractor: IdentifyCoinBusinessLogic
{
    var photoData: TakePhoto.PhotoData? = nil
    var coin:CoinPosition? = nil
    var scrollSize: CGSize = CGSize.zero
    var photoEdges: PhotoEdges? = nil
    var presenter: IdentifyCoinPresentationLogic?
    var isSelected = false
    
    var userIsActive = false
    
    func calculatePhotoEdges(request: IdentifyCoin.GetPhotoEdges.Request) {
        self.photoData = request.photoData
        self.scrollSize = request.scrollSize
        photoEdges = IdentifySharedWorker.calculatePhotoEdges(scrollSize: scrollSize, displayPhoto: photoData!.displayPhoto)

    }
    
    func changeCoinPosition(to newPosition: CirclePosition) {
        let constrainedPosition = IdentifySharedWorker.positionInsideSmallImage(position: newPosition)
        presenter?.presentChangedCirclePosition(to: constrainedPosition)
    }
    
    func requestHelp(request: PopupHelp.Help.Request) {
        // As always, defer the "how" to the worker
        var requestCleared = true  // default case unless first time and autoPopup
        if (request.requestType == .autoPopup) {
            if PopupTracker.hasSeen("IdentifyCoinHelp") || UserDefaults.areHelpScreensDisabled {
                requestCleared = false
            }
        }
        if requestCleared {
            let helpData = IdentifyCoinWorker().retrieveHelp()
            let response = PopupHelp.Help.Response(title: helpData.helpTitle, text: helpData.helpText)
            presenter?.presentHelp(response: response)
        }
        else {
            presenter?.presentNoHelp()
        }
    }
    
    func requestHint() {
        // determine if the user seems to need a hint
        if !userIsActive && UserDefaults.areHintsEnabled {
            presenter?.presentHint()
        }
    }
    
    func newCoin(at coinPosition: CGPoint) {
        let defaultRadius = CGFloat(30)
        let coin = CoinPosition(withID: -1, atLocation: coinPosition, ofRadius: defaultRadius, withState: .selected, withCoinType: .penny)
        // Detect coin
        detectCoin(coin: coin)
        
        self.coin = coin
        
        userIsActive = true
        
        presenter?.presentNewCoin(at: coin)
    }
    
    func selectCoin(_ selected: Bool) {
        // TODO: is this a select-the-coin-wherever-it-is or if the tap is close enough?
        if self.coin != nil {
            isSelected = selected ? true : false
            let state: CircleState = isSelected ? .selected : .unselected
            presenter?.presentSelectedCoin(state: state)
        }
    }
    
    func showCoinActionMenu() {
        presenter?.presentCoinActionMenu()
    }
    
    func setCoinTypeToCoin(coinType: CoinType?) {
        if let newCoinType = coinType {
            presenter?.presentCoinWithCointype(coinType: newCoinType)
        }
        else {
            presenter?.presentRemoveCoin()
        }
    }
    
    func userZoomed() {
        // Fix for #344
        userIsActive = true
    }

}

// Helper methods
extension IdentifyCoinInteractor {
    func detectCoin(coin: CoinPosition){
        let newCirclePosition = IdentifySharedWorker.autoEncircleCoin(coin: coin, smallImage: photoData!.displayPhoto)
        // Update mole
        coin.center = newCirclePosition.center
        coin.radius = newCirclePosition.radius
    }
    
    func isLocationInsideTheEdges(point: CGPoint) -> Bool {
        if photoEdges != nil {
            if point.y < photoEdges!.minimumPosition.y {
                return false
            }
            if point.y > photoEdges!.maximumPosition.y {
                return false
            }
        }
        return true
    }

    func fixLocationInsideTheEdges(point: CGPoint) -> CGPoint {
        var newPoint = point
        if photoEdges != nil {
            if newPoint.y > photoEdges!.maximumPosition.y {
                newPoint.y = photoEdges!.maximumPosition.y
            }
            if newPoint.y < photoEdges!.minimumPosition.y {
                newPoint.y = photoEdges!.minimumPosition.y
            }
            if newPoint.x > photoEdges!.maximumPosition.x {
                newPoint.x = photoEdges!.maximumPosition.x
            }
            if newPoint.x < photoEdges!.minimumPosition.x {
                newPoint.x = photoEdges!.minimumPosition.x
            }
        }
        return newPoint
    }
}

