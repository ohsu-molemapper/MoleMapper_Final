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

class NewWelcomeViewController: UIViewController {

    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var rightButton: UIButton!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var joinStudyButton: UIButton!
    @IBOutlet weak var startMappingButton: UIButton!
    
    func didChangePages(newPage: Int) {
        pageControl.currentPage = newPage
        if newPage == 0 {
            UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.1, delay: 0.0, options: .curveEaseOut, animations: {
                self.leftButton.alpha = 0.0
            }, completion: nil)
        }
        else {
            UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.1, delay: 0.0, options: .curveEaseIn, animations: {
                self.leftButton.alpha = 1.0
            }, completion: nil)
        }
        if newPage == 3 {
            UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.1, delay: 0.0, options: .curveEaseOut, animations: {
                self.rightButton.alpha = 0.0
            }, completion: nil)
        }
        else {
            UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.1, delay: 0.0, options: .curveEaseIn, animations: {
                self.rightButton.alpha = 1.0
            }, completion: nil)
        }
    }
    
    func scrollToPage(page: Int, animated: Bool) {
        var frame: CGRect = self.scrollView.frame
        frame.origin.x = frame.size.width * CGFloat(page)
        frame.origin.y = 0
        self.scrollView.scrollRectToVisible(frame, animated: animated)
        
        didChangePages(newPage: page)
    }
    
    func setup() {
        // hook up delegates, round buttons, etc.
        scrollView.delegate = self
        pageControl.numberOfPages = 4
        leftButton.alpha = 0
        rightButton.alpha = 0
        joinStudyButton.layer.cornerRadius = 10
        
        scrollToPage(page: 0, animated: false)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
    }
    
    // MARK: button handlers
    @IBAction func exitOnboarding(_ sender: Any) {
        // Not ready to join aka "Maybe later..."
        UserDefaults.shouldShowWelcomeScreenWithCarousel = false
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.showBodyMap()
    }
    
    @IBAction func goBack(_ sender: Any) {
        let newPage = pageControl.currentPage - 1
        if newPage < 0 {
            //fatalError("Fell off left edge")
            return
        }
        scrollToPage(page: newPage, animated: true)
    }
    
    @IBAction func goForward(_ sender: Any) {
        let newPage = pageControl.currentPage + 1
        if newPage >= pageControl.numberOfPages {
            //fatalError("Fell off right edge")
            return
        }
        scrollToPage(page: newPage, animated: true)
    }
    
    @IBAction func joinStudy(_ sender: Any) {
        print(#function)
        print("Need to jump to OHSU War on Melanoma page")
        
        UserDefaults.shouldShowWelcomeScreenWithCarousel = false
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.routeToWarOnMelanoma()
    }
    
}

extension NewWelcomeViewController: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let pageWidth = scrollView.bounds.width
        let newPage = Int(scrollView.contentOffset.x / pageWidth)
        if newPage != pageControl.currentPage {
            self.didChangePages(newPage: newPage)
        }
    }
}
