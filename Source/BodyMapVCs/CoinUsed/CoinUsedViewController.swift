//
// MoleMapper
//
// Copyright (c) 2017-2022 OHSU. All rights reserved.
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
import UIKit

class CoinUsedViewController: BaseBodyMapViewController
{
    var router: CoinUsedRoutingLogic?
    
    @IBOutlet weak var buttonCoinNotUsed: UIButton!
    @IBOutlet weak var buttonCoinUsed: UIButton!
    @IBOutlet weak var buttonTryAgain: UIButton!
    
    // MARK: Object lifecycle
    
    convenience init()
    {
        self.init(nibName: "CoinUsedView", bundle: nil)
        setup()
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()

        buttonCoinNotUsed.addTarget(self, action: #selector(onCoinNotUsed(_:)), for: .touchUpInside)
        buttonCoinUsed.addTarget(self, action: #selector(OnCoinUsed(_:)), for: .touchUpInside)
        buttonTryAgain.addTarget(self, action: #selector(OnTryAgain(_:)), for: .touchUpInside)
        buttonTryAgain.titleLabel?.lineBreakMode = .byWordWrapping
        buttonTryAgain.titleLabel?.textAlignment = .center
        buttonTryAgain.setTitle("I meant to!\n(let me try again)", for: .normal)
    }
    
    @objc func onCoinNotUsed(_ sender: Any) {
        router?.navigateToIdentifyMole()
    }
    
    @objc func OnCoinUsed(_ sender: Any) {
        router?.navigateToIdentifyCoin()
    }
    
    @objc func OnTryAgain(_ sender: Any) {
        router?.retakePhoto() 
    }

    override func onBack() {
        router?.navigateBack()
    }
    
    // MARK: Setup
    
    private func setup()
    {
        let viewController = self
        let router = CoinUsedRouter()
        viewController.router = router
        router.viewController = viewController
    }
}
