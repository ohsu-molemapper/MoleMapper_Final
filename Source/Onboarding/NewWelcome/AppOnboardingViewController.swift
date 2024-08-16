//
//  AppOnboardingViewController.swift
//  OnboardingMockup
//
//  Created by Tracy Petrie on 5/7/19.
//  Copyright © 2019 Tracy Petrie. All rights reserved.
//

import UIKit

class NewWelcomeViewController: UIViewController {

    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var rightButton: UIButton!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var playVideoButton: UIButton!
    @IBOutlet weak var whatsInvolvedButton: UIButton!
    @IBOutlet weak var joinStudyButton: UIButton!
    @IBOutlet weak var laterButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    @IBAction func exitOnboarding(_ sender: Any) {
    }
    
    func setup() {
        // hook up delegates, round buttons, etc.
        scrollView.delegate = self
        pageControl.numberOfPages = 4
        leftButton.alpha = 0
        rightButton.alpha = 0
        
        // Round, recolor buttons etc.
        playVideoButton.layer.cornerRadius = 8
        whatsInvolvedButton.layer.cornerRadius = 8
        joinStudyButton.layer.cornerRadius = 10
        laterButton.layer.cornerRadius = 8
        
        laterButton.layer.borderColor = UIColor(named: "mmBlue")?.cgColor
        laterButton.layer.borderWidth = 1.5
        
        scrollToPage(page: 0, animated: false)
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
    }
    
    @IBAction func playVideo(_ sender: Any) {
        let sb = self.storyboard
        if let vc = sb?.instantiateViewController(withIdentifier: "ShowResearchYoutube") {
            self.present(vc, animated: true, completion: nil)
        }
        else {
            fatalError("missing vc")
        }
    }
    
    @IBAction func showWhatsInvolved(_ sender: Any) {
        let sb = self.storyboard
        if let vc = sb?.instantiateViewController(withIdentifier: "WhatsUpVC") {
            self.present(vc, animated: true, completion: nil)
        }
        else {
            fatalError("missing vc")
        }
    }
    
    func scrollToPage(page: Int, animated: Bool) {
        var frame: CGRect = self.scrollView.frame
        frame.origin.x = frame.size.width * CGFloat(page)
        frame.origin.y = 0
        self.scrollView.scrollRectToVisible(frame, animated: animated)
        
        didChangePages(newPage: page)
    }

    func didChangePages(newPage: Int) {
        print("swiped to \(newPage)")
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
            //            nextButton.isHidden = true
        }
        else {
            UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.1, delay: 0.0, options: .curveEaseIn, animations: {
                self.rightButton.alpha = 1.0
            }, completion: nil)
            //            nextButton.isHidden = false
        }
    }
}

extension NewWelcomeViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        //        let pageWidth = scrollView.bounds.width
        //        let currentPage = Int(scrollView.contentOffset.x / pageWidth)
        //        pageChangeDelegate.didChangePages(newPage: currentPage)
        //        print(".")
    }
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let pageWidth = scrollView.bounds.width
        let newPage = Int(scrollView.contentOffset.x / pageWidth)
        if newPage != pageControl.currentPage {
            self.didChangePages(newPage: newPage)
        }
    }
}
