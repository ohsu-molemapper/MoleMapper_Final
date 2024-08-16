//
//  PopupHelpViewController.swift
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
import UIKit

protocol PopupHelpDataSource: AnyObject  {
    func getHelpText() -> NSAttributedString
    func getHelpTitle() -> String
}

class PopupHelpViewController: UIViewController {

    @IBOutlet weak var helpButton: UIButton!
    @IBOutlet weak var helpScreen: UIView!
    @IBOutlet weak var helpText: UITextView!
    @IBOutlet weak var helpTitle: UILabel!
    
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    @IBOutlet weak var rightConstraint: NSLayoutConstraint!
    @IBOutlet weak var leftConstraint: NSLayoutConstraint!
    
    
    weak var delegate : PopupHelpDataSource!
    var dismissCompletion: (() -> Void)?

    // MARK: - Override methods
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        helpText.setContentOffset(CGPoint.zero, animated: true) // doesn't work in viewDidLayoutSubviews (though that seems to work for RTFView!)
        helpText.flashScrollIndicators()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        helpScreen.layer.cornerRadius = 20.0
        
        helpScreen.layer.shadowPath =
            UIBezierPath(roundedRect: helpScreen.bounds,
                         cornerRadius: helpScreen.layer.cornerRadius).cgPath
        helpScreen.layer.shadowColor = UIColor.black.cgColor
        helpScreen.layer.shadowOpacity = 0.5
        helpScreen.layer.shadowOffset = CGSize.zero
        helpScreen.layer.shadowRadius = 8
        helpScreen.layer.masksToBounds = false
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Modify styles (tried adding a shadow but clipping to bounds
        // to get rounded corners causes shadows to fail
        helpButton.mmMakeRounded(style: .infoDark)

        // Test screen size and adjust constraints accordingly
        let screenBounds = UIScreen.main.bounds
        if screenBounds.height < 600 {
            leftConstraint.constant = 12
            rightConstraint.constant = 12
            topConstraint.constant = 54
            bottomConstraint.constant = 54
        }
        else if screenBounds.height < 700 {
            leftConstraint.constant = 24
            rightConstraint.constant = 24
            topConstraint.constant = 74
            bottomConstraint.constant = 74
        }
        
        // Set content
        helpTitle.text = delegate.getHelpTitle()
        helpText.attributedText = delegate.getHelpText()
    }
    
    // MARK: - Public methods
    
    class func getInstance() -> PopupHelpViewController {
        let sb = UIStoryboard(name: "PopupHelp", bundle: nil)
        let vc = sb.instantiateInitialViewController()! as! PopupHelpViewController
        return vc
    }
    
    func displayHelpPopup(_ presentingViewController: UIViewController, completion: @escaping ()->Void ) {
        self.modalPresentationStyle = .overFullScreen
        self.modalTransitionStyle = .crossDissolve
        self.dismissCompletion = completion
        DispatchQueue.main.async {
            presentingViewController.present(self, animated: true, completion: nil)
        }
    }


    // MARK: - IBAction methods
    
    @IBAction func handleDone(_ sender: Any) {
        self.dismiss(animated: true, completion: self.dismissCompletion)
    }
    
}
