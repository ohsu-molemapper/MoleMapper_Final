//
//  BaseBodyMapViewController
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
import Foundation

class BaseBodyMapViewController: UIViewController
{
    // MARK - Setup
    fileprivate var hideNavigation : Bool = false
    
    func setupNavigationMenuItems(navigationType: BodyMapNavigationTypes?) {
        
        if (navigationType != nil) {
            switch(navigationType!){
            case BodyMapNavigationTypes.backOnly:
                showBackOnlyNavigation()
                break;
            case BodyMapNavigationTypes.backNext:
                showBackNextNavigation()
                break;
            case BodyMapNavigationTypes.cancelDone:
                showCancelDoneNavigation()
                break;
            case BodyMapNavigationTypes.cancelNext:
                showCancelNextNavigation()
                break;
            case BodyMapNavigationTypes.noButtons:
                showNoNavigation()
                break;
            case BodyMapNavigationTypes.backDone:
                showBackDoneNavigation()
                break;
            }
        }
    }
    
    func setBodyMapTitle() {
        if let navViewController = navigationController as? MeasurementController {
            title = navViewController.zoneTitle
        }
    }
    
    func setNavigationBarHidden() {
        hideNavigation = true
    }
    
    fileprivate func showBackOnlyNavigation() {
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back", style: .plain,
                                                                target: self, action: #selector(onBack))
        self.navigationItem.rightBarButtonItem = nil
        
    }
    
    fileprivate func showNoNavigation() {
        self.navigationItem.leftBarButtonItem = nil
        self.navigationItem.rightBarButtonItem = nil
        self.navigationItem.setHidesBackButton(true, animated: false)
    }
    
    fileprivate func showBackDoneNavigation() {
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back", style: .plain,
                                                                target: self, action: #selector(onBack))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .done,
                                                                 target: self, action: #selector(onDone))
    }
    
    fileprivate func showCancelDoneNavigation() {
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain,
                                                                target: self, action: #selector(onCancel))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .done,
                                                                 target: self, action: #selector(onDone))
    }
    
    fileprivate func showCancelNextNavigation() {
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain,
                                                                target: self, action: #selector(onCancel))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Next", style: .plain,
                                                                 target: self, action: #selector(onNext))
    }
    
    fileprivate func showBackNextNavigation() {
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back", style: .plain,
                                                                target: self, action: #selector(onBack))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Next", style: .plain,
                                                                 target: self, action: #selector(onNext))
    }
    
    // MARK - View controller lifecycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if (hideNavigation) {
            navigationController?.setNavigationBarHidden(true, animated: false)
        }
    }
    
    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if (hideNavigation) {
            navigationController?.setNavigationBarHidden(false, animated: false)
        }
    }
    
    // MARK - Navigation methods
    
    @objc func onBack() {
        // Implement where required
    }
    
    @objc func onCancel() {
        // Implement where required
    }
    
    @objc func onDone() {
        // Implement where required
    }
    
    @objc func onNext() {
        // Implement where required
    }
    
    func navigateBackToTakePhoto() {
        let viewControllers: [UIViewController] = navigationController!.viewControllers
        
        var takePhotoIndex = 0
        for i in 0 ..< viewControllers.count {
            if let _:TakePhotoViewController = viewControllers[i] as? TakePhotoViewController{
                takePhotoIndex = i
                break
            }
        }
        navigationController!.popToViewController(viewControllers[takePhotoIndex], animated: true)
    }
}
