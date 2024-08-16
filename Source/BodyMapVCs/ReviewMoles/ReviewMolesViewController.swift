//
//  ReviewMolesViewController
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
import MessageUI
import Instructions

enum BackgroundImageReference {
    case None
    case Previous
    case Next
}

protocol ReviewMolesDisplayLogic: class
{
    func displayHint()
    func showChangedMeasurement(viewModel: ReviewMoles.ChangeMeasurement.ViewModel)
    func showEmailViewController(viewModel: ReviewMoles.EmailMole.ViewModel)
    func showHelp(viewModel: PopupHelp.Help.ViewModel)
    func noHelp()
    func showInitialMeasurement(viewModel: ReviewMoles.InitWithMole.ViewModel)
    func restoreCurrentMeasurement()
}

class ReviewMolesViewController: UIViewController
{
    let alphaThreshold: CGFloat = 0.4    // completely arbitrary and empirically determined!!
    var anchor_x: CGFloat = 0.0
    var backgroundImageRef = BackgroundImageReference.None
    var currentModel: ReviewMoles.InitWithMole.ViewModel?
    var helpText: NSAttributedString?
    var helpTitle: String?
    var interactor: ReviewMolesBusinessLogic?
    var mole: Mole30?
    var nextImageCache: UIImage?
    var prevImageCache: UIImage?
//    var router: ReviewMolesRoutingLogic?
    var sortedMeasurements: [MoleMeasurement30] = []
    let swipeLenThreshold: CGFloat = 50.0
    let velocityThreshold: CGFloat = 90.0      // completely arbitrary and empirically determined!!
    let coachMarksController = CoachMarksController()
    var shareButtonView: UIView!
    
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var foregroundImageView: UIImageView!
    @IBOutlet weak var helpButton: UIButton!
    @IBOutlet weak var infoBox: UIView!
    @IBOutlet weak var moleDateLabel: UILabel!
    @IBOutlet weak var moleSizeLabel: UILabel!
    @IBOutlet weak var moleNameLabel: UILabel!
    @IBOutlet weak var zoneNameLabel: UILabel!
    @IBOutlet weak var pageControl: UIPageControl!
    
    // MARK: Lifecycle methods
    convenience init(mole: Mole30) {
        self.init(nibName: "ReviewMolesViewController", bundle: nil)
        self.mole = mole
        
        setup()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        coachMarksController.dataSource = self
        coachMarksController.delegate = self
        coachMarksController.overlay.allowTap = true
        coachMarksController.overlay.color = .ccTranslucentGray
        
        if let navController = self.navigationController {
            
            let backItem = UIBarButtonItem()
            backItem.title = "Back"
            navController.navigationBar.topItem?.backBarButtonItem = backItem
            
            self.title = mole!.moleName
            
            let shareButton = UIBarButtonItem(barButtonSystemItem: .action,
                                                                target: self,
                                                                action: #selector(shareMole))
            navigationItem.rightBarButtonItem = shareButton
            // Create UIView using CGRect around NavigationBar RightBarButtonItem
            let statusBarHeight: CGFloat = UIApplication.shared.statusBarFrame.height
            let navigationBarSize: CGSize = self.navigationController!.navigationBar.frame.size
            let rightBarButton1 = CGRect(x: navigationBarSize.width - 0.16*navigationBarSize.width, y: statusBarHeight+5, width: 0.16*navigationBarSize.width, height: navigationBarSize.height-10)
            shareButtonView = UIView(frame: rightBarButton1)
            
        }
        
        helpButton.mmHelpify()
        infoBox.layer.cornerRadius = 7.0
        moleNameLabel.text = ""
        moleDateLabel.text = ""
        moleSizeLabel.text = ""
        zoneNameLabel.text = ""
        
        if let mole = self.mole {
            interactor?.initializeWithMole(request: ReviewMoles.InitWithMole.Request(mole: mole))
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        invokeHelp(self)  // Let interactor decide whether to show or not
    }
    
    func displayCoach(){
        if UserDefaults.firstMoleReview {
            coachMarksController.start(in: PresentationContext.currentWindow(of: self))
            UserDefaults.firstMoleReview = false
        }
        else {
            waitAndDisplayHint()
        }
    }
    
    func waitAndDisplayHint() {
        HintUtils.delay(milliseconds: HintUtils.defaultDelayMilliseconds) { [weak self] in
            self?.interactor?.requestHint()
        }
    }

    // MARK: - Event handlers

    @IBAction func invokeHelp(_ sender: Any) {
        var request : PopupHelp.Help.Request?
        if sender is UIButton {
            request = PopupHelp.Help.Request(.userRequest)
        } else {
            request = PopupHelp.Help.Request(.autoPopup)
        }
        interactor?.requestHelp(request: request!)
    }
    
    @IBAction func panGesture(_ sender: UIPanGestureRecognizer) {
        let viewWidth = view.bounds.width

        switch sender.state {
        case UIGestureRecognizer.State.began:
            self.anchor_x = sender.location(in: view).x
            
        case UIGestureRecognizer.State.changed:
            let delta = sender.location(in: view).x - self.anchor_x
            if abs(delta) < 0.001 {
                // Close enough to zero. No changes worth doing anything about yet...
                return
            }

            var distanceToEdge : CGFloat = 0.0
            var newBackgroundRef = BackgroundImageReference.None
            if delta > 0 {
                distanceToEdge = viewWidth - self.anchor_x
                newBackgroundRef = BackgroundImageReference.Next
            } else {
                distanceToEdge = self.anchor_x
                newBackgroundRef = BackgroundImageReference.Previous
            }
            if newBackgroundRef != self.backgroundImageRef {
                self.backgroundImageRef = .None  // default
                if newBackgroundRef == .Previous {
                    if let image = prevImageCache {
                        self.backgroundImageView.image = image
                        self.backgroundImageRef = .Previous
                    }
                } else if newBackgroundRef == .Next {
                    if let image = nextImageCache {
                        self.backgroundImageView.image = image
                        self.backgroundImageRef = .Next
                    }
                } else {
                    self.backgroundImageView.image = nil
                    self.backgroundImageRef = .None
                }
            }
            if self.backgroundImageRef != .None {
                let fraction = abs(delta / distanceToEdge)
                let alpha = 1.0 - fraction
                foregroundImageView.alpha = alpha
            }
            
        case UIGestureRecognizer.State.ended:
            let delta = sender.location(in: view).x - self.anchor_x
            let velocity = sender.velocity(in: view).x
            let newIndex = currentModel?.currentMeasurementIndex ?? 0
            if velocity > velocityThreshold && abs(delta) > swipeLenThreshold {
                // Swipe right (go forward in time)
                // lower indexes are more recent
                let request = ReviewMoles.ChangeMeasurement.Request(newMeasurementIndex: newIndex - 1)
                interactor?.changeMeasurement(request: request)
            } else if velocity < -velocityThreshold && abs(delta) > swipeLenThreshold {
                // Swipe left (go back in time)
                let request = ReviewMoles.ChangeMeasurement.Request(newMeasurementIndex: newIndex + 1)
                interactor?.changeMeasurement(request: request)
            } else if foregroundImageView.alpha < alphaThreshold {
                if delta > 0 {
                    let request = ReviewMoles.ChangeMeasurement.Request(newMeasurementIndex: newIndex - 1)
                    interactor?.changeMeasurement(request: request)
                } else {
                    let request = ReviewMoles.ChangeMeasurement.Request(newMeasurementIndex: newIndex + 1)
                    interactor?.changeMeasurement(request: request)
                }
            } else {
                UIView.animate(withDuration: 0.15, animations: {
                    self.foregroundImageView.alpha = 1.0
                })
            }
        default: break
        }
    }

    @objc  // needed by #selector
    func shareMole() {
        // Called by button in navigator toolbar
        if let mole = mole {
            interactor?.emailMole(request: ReviewMoles.EmailMole.Request(mole: mole))
        }
    }
    
    // MARK: - Helper methods
    
    private func setup()
    {
        let viewController = self
        let interactor = ReviewMolesInteractor()
        let presenter = ReviewMolesPresenter()
        viewController.interactor = interactor
        interactor.presenter = presenter
        presenter.viewController = viewController
    }
}

extension ReviewMolesViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController,
                               didFinishWith result: MFMailComposeResult, error: Error?) {
        // Dismiss the mail compose view controller.
        controller.dismiss(animated: true, completion: nil)
    }
    
}

// MARK: ReviewMolesDisplayLogic Methods
extension ReviewMolesViewController: ReviewMolesDisplayLogic {
    func displayHint() {
        if self.pageControl.numberOfPages > 1 {
            self.showToast("Swipe left or right to see other measurements", position: .top)
        }
    }

    func noHelp() {
        displayCoach()
    }

    func restoreCurrentMeasurement() {
        UIView.animate(withDuration: 0.15, animations: {
            self.foregroundImageView.alpha = 1.0
        })
    }
    func showChangedMeasurement(viewModel: ReviewMoles.ChangeMeasurement.ViewModel) {
        if let image = viewModel.nextMeasurement?.moleMeasurementImage() {
            nextImageCache = image
        }
        if let image = viewModel.previousMeasurement?.moleMeasurementImage() {
            prevImageCache = image
        }
        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.2, delay: 0.0, options: .curveEaseOut, animations: {
            self.foregroundImageView.alpha = 0.0
        }, completion: { finalPosition in
            self.foregroundImageView.image = viewModel.currentMeasurement.moleMeasurementImage()
            self.foregroundImageView.alpha = 1.0
            if let bgimage = viewModel.previousMeasurement?.moleMeasurementImage() {
                self.backgroundImageView.image = bgimage
                self.backgroundImageRef = .Previous
            } else if let bgimage = viewModel.nextMeasurement?.moleMeasurementImage() {
                self.backgroundImageView.image = bgimage
                self.backgroundImageRef = .Next
            } else {
                self.backgroundImageRef = .None
            }
            self.pageControl.currentPage = viewModel.newMeasurementIndex
            self.currentModel?.currentMeasurement = viewModel.currentMeasurement
            self.currentModel?.previousMeasurement = viewModel.previousMeasurement
            self.currentModel?.nextMeasurement = viewModel.nextMeasurement
            self.currentModel?.currentMeasurementIndex = viewModel.newMeasurementIndex
            self.updateInfoBox()
        })
    }
    
    func showEmailViewController(viewModel: ReviewMoles.EmailMole.ViewModel) {
        let viewController = viewModel.viewControllerToPresent
        if viewController is MFMailComposeViewController {
            let vc = viewController as! MFMailComposeViewController
            vc.mailComposeDelegate = self
        }
        self.present(viewModel.viewControllerToPresent, animated: true, completion: nil)
    }
    
    func showHelp(viewModel: PopupHelp.Help.ViewModel) {
        self.helpText = viewModel.helpText
        self.helpTitle = viewModel.helpTitle
        
        let vc = PopupHelpViewController.getInstance()
        vc.delegate = self
        vc.displayHelpPopup(self) {[unowned self] in
            self.displayCoach()
        }
    }
    
    func showInitialMeasurement(viewModel: ReviewMoles.InitWithMole.ViewModel) {
        currentModel = viewModel
        foregroundImageView.image = viewModel.currentMeasurement.moleMeasurementImage()
        if let image = currentModel?.previousMeasurement?.moleMeasurementImage() {
            backgroundImageView.image = image
            backgroundImageRef = .Previous
        } else {
            backgroundImageRef = .None
        }
        pageControl.numberOfPages = currentModel!.measurementCount
        pageControl.currentPage = currentModel!.currentMeasurementIndex
        updateInfoBox()
        if let image = viewModel.nextMeasurement?.moleMeasurementImage() {
            nextImageCache = image
        }
        if let image = viewModel.previousMeasurement?.moleMeasurementImage() {
            prevImageCache = image
        }
    }
    
    // MARK: ReviewMolesDisplayLogic Helpers
    func updateInfoBox() {
        // set text in info box
        let moleMeasurement = currentModel?.currentMeasurement
        var dateString = moleMeasurement?.date?.description ?? "Unknown date"
        var sizeString = "Size: n/a"
        if let moleSize = moleMeasurement?.calculatedMoleDiameter {
            if moleSize.floatValue > 0 {
                let formatter = NumberFormatter()
                formatter.maximumFractionDigits = 1
                sizeString = "Size: " + (formatter.string(from: moleSize) ?? "bad") + " mm"
            }
        }
        if let measurementDate = moleMeasurement?.date {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .short
            dateString = "Date: " + dateFormatter.string(from: measurementDate as Date)
        }
        self.moleNameLabel?.text = self.mole?.moleName ?? "Unknown"
        self.moleDateLabel?.text = dateString
        self.moleSizeLabel?.text = sizeString
        if let zoneID = self.mole?.whichZone?.zoneID {
            self.zoneNameLabel?.text = Zone30.zoneNameForZoneID(zoneID)
        } else {
            self.zoneNameLabel?.text = "Unrecognized Zone"
        }
    }
    
}

extension ReviewMolesViewController : PopupHelpDataSource {
    func getHelpText() -> NSAttributedString {
        let text = self.helpText ?? NSAttributedString(string: "No Data")
        return text
    }
    func getHelpTitle() -> String {
        let text = self.helpTitle ?? "No Title"
        return text
    }
}

// MARK: - Instructions configuration
extension ReviewMolesViewController : CoachMarksControllerDataSource {
    func coachMarksController(_ coachMarksController: CoachMarksController, coachMarkViewsAt index: Int, madeFrom coachMark: CoachMark) -> (bodyView: CoachMarkBodyView, arrowView: CoachMarkArrowView?) {
        let coachViews = coachMarksController.helper.makeDefaultCoachViews(withArrow: true, arrowOrientation: coachMark.arrowOrientation)
        
        switch(index) {
        case 0:
            coachViews.bodyView.hintLabel.text = "Click here to share mole by email"
            coachViews.bodyView.nextLabel.text = "OK"
            coachViews.bodyView.hintLabel.textColor = UIColor.mmBlue
        default:
            coachViews.bodyView.hintLabel.text = ""
        }
        return (bodyView: coachViews.bodyView, arrowView: coachViews.arrowView)
    }
    
    func coachMarksController(_ coachMarksController: CoachMarksController, coachMarkAt index: Int) -> CoachMark {
        
        switch(index) {
        case 0:
            return coachMarksController.helper.makeCoachMark(for: shareButtonView)
        default:
            return coachMarksController.helper.makeCoachMark(for: view)
        }
    }
    
    func numberOfCoachMarks(for coachMarksController: CoachMarksController) -> Int {
        return 1
    }
}

extension ReviewMolesViewController: CoachMarksControllerDelegate {
    func coachMarksController(_ coachMarksController: CoachMarksController, didEndShowingBySkipping skipped: Bool) {
        waitAndDisplayHint()
    }
}
