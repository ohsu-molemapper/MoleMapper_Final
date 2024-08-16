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
import UIKit
import AVKit
import AVFoundation
import Instructions
//import ResearchKit
import CoreData

enum ZoneTransitionState {
    case ZoneTransitionStateNew
    case ZoneTransitionStateReview
    case ZoneTransitionStateDueOverdue
}

@objc class BodyMapViewController: UIViewController
{
    private var _context: NSManagedObjectContext?
    
    private var _bodyFront: BodyFrontView? = nil
    private var _bodyBack: BodyBackView? = nil
    private var _headDetail: HeadDetailView? = nil
    
    private var containerView: UIView!
    
    private var firstTimeOpen: Bool = true
    private var currentView: UIImageView? = nil
    private var currentViewTitle: String? = nil
    private var nextView: UIImageView? = nil
    private var nextViewTitle: String? = nil
    var dashboardView: UIView!
    var nMoles: UInt = 0
    var welcomeText: NSAttributedString? = nil
    var welcomeTitle = ""

    
//    @IBOutlet weak var consentButton: UIButton!
    @IBOutlet weak var demoVideosButton: UIButton!
    @IBOutlet weak var scrollView: UIScrollView!
    var zoneButton1 = OBShapedButton(type: UIButton.ButtonType.custom)
    let coachMarksController = CoachMarksController()
    let vars: VariableStore = VariableStore.shared()
    
    var userIsActive = false  // once per app invocation, not each time bodymap is displayed
    
    var bodyFront: BodyFrontView {
        get {
            
            if (_bodyFront == nil) {
                _bodyFront = BodyFrontView(frame: containerView.bounds)
            }
            
            return _bodyFront!
        }
    }
    
    var bodyBack: BodyBackView {
        get {
            
            if (_bodyBack == nil) {
                _bodyBack = BodyBackView(frame: containerView.bounds)
            }
            
            return _bodyBack!
        }
    }
    
    var headDetail: HeadDetailView {
        get {
            
            if (_headDetail == nil) {
                _headDetail = HeadDetailView(frame: containerView.bounds)
            }
            
            return _headDetail!
        }
    }
    
    // MARK: Lifecycle events
    
    override func loadView() {
        super.loadView()
        let containerFrame = CGRect(x: 0, y: 0, width: 216, height: 404)
        containerView = UIView(frame: containerFrame)
        scrollView.addSubview(containerView)
        self.scrollView.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        coachMarksController.dataSource = self
        coachMarksController.delegate = self
        coachMarksController.overlay.allowTap = true
        coachMarksController.overlay.color = .ccTranslucentGray

        self.nextView = bodyBack
        self.nextView?.alpha = 0
        
        self.currentView = self.bodyFront

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let backgroundButton = UIButton(type: UIButton.ButtonType.custom)
        backgroundButton.frame = containerView.bounds
        backgroundButton.addTarget(self, action: #selector(backgroundTapped), for: UIControl.Event.touchUpInside)
        self.containerView?.addSubview(backgroundButton)
        
        self.headDetail.alpha = 0
        self.containerView?.addSubview(headDetail)
        self.containerView?.addSubview(bodyBack)
        self.containerView?.addSubview(bodyFront)
        
        navigationItem.titleView = UIImageView(image: #imageLiteral(resourceName: "moleMapperLogo"))

        setZoomParameters(scrollView.bounds.size)
        centerImage()

        self.setUpFlipButton()
        
        dashboardView = getTabBarItemView(title: "Dashboard")
        
        self.containerView?.bringSubviewToFront(self.currentView!)
        self.headDetail.alpha = 0.0
        
        self.vars.animateTransparencyOfZones(withPhotoDataOverDuration: 1.25)
        self.vars.updateZoneButtonImages()
        
        let zoneId = "2451"
        let tz = self.vars.tagZones.object(forKey: zoneId) as! TagZone
        zoneButton1 = tz.button

        nMoles = Mole30.moleCount().uintValue
        self.tabBarController?.tabBar.isHidden = false
   }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showWelcome { [unowned self] in
            if (UserDefaults.firstTimeLogin || UserDefaults.showNotificationsCoach) { // || (nMoles >= 2 && UserDefaults.showDashboard)) {
                self.coachMarksController.start(in: PresentationContext.currentWindow(of: self))
            } else if (self.nMoles >= 2 && UserDefaults.showDashboard) {
                self.coachMarksController.start(in: PresentationContext.currentWindow(of: self))
            } else {
                self.waitAndDisplayHint()
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        userIsActive = true     // user obviously tapped on something!
        vars.clearTransparencyOfAllZones()
    }
    
    func centerImage() {
        let scrollViewSize = scrollView.bounds.size
        let imageSize = containerView.frame.size
        
        let horizontalSpace = imageSize.width < scrollViewSize.width
            ? (scrollViewSize.width - imageSize.width) / 2
            : 0
        let verticalSpace = imageSize.height < scrollViewSize.height
            ? (scrollViewSize.height - imageSize.height) / 2
            : 0
        scrollView.contentInset = UIEdgeInsets(top: verticalSpace, left: horizontalSpace, bottom: verticalSpace, right: horizontalSpace)
    }
    
    func showWelcome(withCompletion: (()-> Void)?) {
        if UserDefaults.userHasNotSeenWelcome {
            UserDefaults.userHasNotSeenWelcome = false
            self.welcomeText = RTFHelpers.getAttributedText(fromFile: "WelcomeMessage")
            self.welcomeTitle =  "Welcome to MoleMapper 3.4"

            let vc = PopupHelpViewController.getInstance()
            vc.delegate = self
            vc.displayHelpPopup(self) {
                if let completion = withCompletion {
                    completion()
                }
            }
        }
        else if let completion = withCompletion {
            completion()
        }
    }
    
    func setZoomParameters(_ scrollViewSize: CGSize) {
        let imageSize = containerView.bounds.size
        let widthScale = scrollViewSize.width / imageSize.width
        let heightScale = scrollViewSize.height / imageSize.height
        let minScale = min(widthScale, heightScale) * 0.9
        
        scrollView.minimumZoomScale = minScale
        scrollView.maximumZoomScale = 7.0
        scrollView.zoomScale = minScale
    }
    
    func displayHint() {
        self.showToast("Tap on any zone to start the measurement process...")
    }
    
    func waitAndDisplayHint() {
        HintUtils.delay(milliseconds: HintUtils.defaultDelayMilliseconds) { [unowned self] in
            if !self.userIsActive && UserDefaults.areHintsEnabled {
                self.displayHint()
            }
        }
    }

    
    // MARK: Bodymap functions
    
    @objc func backgroundTapped(sender: UIButton) {
        if (self.headDetail.alpha == 1.0) {
            self.headDetail.alpha = 0.0
            UIView.animate(withDuration: 0.5, delay: 0, options: UIView.AnimationOptions.beginFromCurrentState, animations: {
                self.scrollView.zoom(to: self.scrollView.frame, animated:false)
            }, completion: { (finished) in
                self.centerImage()
            })
        }
    }
        
    @IBAction func demoButtonTapped(_ sender: Any) {
        let sb = UIStoryboard(name: "Settings", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "SettingsViewController")
        vc.modalPresentationStyle = .fullScreen
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func firstTimeLogin() {
        let alert = UIAlertController(title: "Welcome", message: "Would you like to see some videos on how to use the app?", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Yes", style: UIAlertAction.Style.default) { (alertAction) in
            
            self.demoButtonTapped(self)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc func flipButtonTapped(sender: UIButton) {
        if (self.headDetail.alpha == 1.0) {
            self.headDetail.alpha = 0.0
        }
        
        UIView.transition(with: self.scrollView, duration: 0.4, options: UIView.AnimationOptions.transitionFlipFromLeft, animations: {
            self.containerView?.bringSubviewToFront(self.nextView!)
            let lastTitle = self.currentViewTitle
            let lastView = self.currentView
            self.currentView = self.nextView
            self.currentViewTitle = self.nextViewTitle
            self.nextView = lastView
            self.nextViewTitle = lastTitle
            self.nextView!.alpha = 0.0
            self.currentView!.alpha = 1.0
        }) { (finished) in
            self.navigationItem.title = self.currentViewTitle
        }
    }
    
    func retrieveAlertActionForVideo(title: String, resourceName: String) -> UIAlertAction {
        return UIAlertAction(title: title, style: UIAlertAction.Style.default) { (alertAction) in
            
            let videoUrl = Bundle.main.url(forResource: resourceName, withExtension:"mp4")
            let destVC = AVPlayerViewController()
            let player = AVPlayer(url: videoUrl!)
            destVC.player = player
            
            destVC.modalPresentationStyle = .fullScreen
            self.present(destVC, animated: true, completion: nil)
        }
    }
    let flipButton = UIButton(type: UIButton.ButtonType.custom)
    func setUpFlipButton() {
        let visibleBottom = scrollView.frame.origin.y + scrollView.frame.size.height
        let flipButtonSize = CGFloat(60.0)
        let margin = CGFloat(20.0)
        let bottom = visibleBottom - flipButtonSize - margin 
        let right = self.view.frame.size.width - flipButtonSize - margin
        
//        let flipButton = UIButton(type: UIButton.ButtonType.custom)
        flipButton.addTarget(self, action: #selector(self.flipButtonTapped), for: UIControl.Event.touchUpInside)
        flipButton.setBackgroundImage(UIImage(named: "flipButton"), for: UIControl.State.normal)
        flipButton.frame = CGRect(x: right, y: bottom, width: flipButtonSize, height: flipButtonSize)
        
        self.view.addSubview(flipButton)
    }
    
    @objc func segueToZoneView(zoneButton: OBShapedButton) {
        let zoneId = String(zoneButton.tag)
        let zoneTransitionState = self.zoneTransitionStateForZone(zoneId: Int(zoneId)!)
        let tz = vars.tagZones.object(forKey: zoneId) as! TagZone
        
        var destinationVC: UIViewController
        switch(zoneTransitionState) {
        case .ZoneTransitionStateNew:
            destinationVC = MeasurementController(zoneID: zoneId, zoneTitle: tz.titleBarText, moleToShow: nil, measureType: .newMeasure)
        case .ZoneTransitionStateReview:
            destinationVC = MeasurementController(zoneID: zoneId, zoneTitle: tz.titleBarText, moleToShow: nil, measureType: .remeasure)
        case .ZoneTransitionStateDueOverdue:
            destinationVC = MeasurementController(zoneID: zoneId, zoneTitle: tz.titleBarText, moleToShow: nil, measureType: .remeasure)
        }
        
        destinationVC.modalPresentationStyle = .fullScreen
        
        let transition = CATransition()
        transition.duration = 0.5
        transition.type = CATransitionType.fade
        
        self.navigationController?.view.layer.add(transition, forKey: nil)
        self.navigationController?.present(destinationVC, animated: true, completion: {
            self.scrollView.zoom(to: self.vars.contentRect, animated: false)
        })
    }
    
    @objc func zoneButtonTapped(sender: OBShapedButton) {
        let x = vars.imageRect.origin.x + sender.frame.origin.x
        let y = vars.imageRect.origin.y + sender.frame.origin.y
        let width = sender.frame.size.width
        let height = sender.frame.size.height
        
        userIsActive = true
        
        let zoomToRect = CGRect(x: x, y: y, width: width, height: height)
        
        // Front view Head or Back view Head
        if ((sender.tag == 1100) || (sender.tag == 2100))
        {
            let x = vars.imageRect.origin.x + sender.center.x - 80.0
            let y = vars.imageRect.origin.y + sender.center.y - 30.0
            let zoomRect = CGRect(x: x, y: y, width: 160, height: 160)
            
            self.scrollView.zoom(to: zoomRect, animated: true)
            self.containerView?.bringSubviewToFront(self.headDetail)
            
            UIView.transition(with: self.scrollView, duration: 0.3, options: UIView.AnimationOptions.showHideTransitionViews, animations: {
                self.headDetail.alpha = 1.0
            }, completion: nil)
        }
        else {
            
            UIView.animate(withDuration: 0.5, delay: 0, options: UIView.AnimationOptions.beginFromCurrentState, animations: {
                self.scrollView.zoom(to: zoomToRect, animated:false)
            }, completion: { (finished) in
                self.perform(#selector(self.segueToZoneView(zoneButton:)), with: sender, afterDelay: 0)
            })
        }
    }
    
    func zoneTransitionStateForZone(zoneId: Int) -> ZoneTransitionState {
        var state = ZoneTransitionState.ZoneTransitionStateNew
        if (Zone30.hasValidImageDataForZoneID(String(zoneId))) {
            
            state = Zone30.numberOfMolesNeedingRemeasurementInZone(String(zoneId)) == 0 ? .ZoneTransitionStateReview :. ZoneTransitionStateDueOverdue
        }
        
        return state
    }
}

extension BodyMapViewController : PopupHelpDataSource {
    func getHelpText() -> NSAttributedString {
        let text = self.welcomeText ?? NSAttributedString(string: "No Data")
        return text
    }
    func getHelpTitle() -> String {
        let text = self.welcomeTitle
        return text
    }
}


// MARK: Scroll view delegate

extension BodyMapViewController : UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.containerView
    }
}

// MARK: Instructions configuration

extension BodyMapViewController : CoachMarksControllerDataSource {
    func coachMarksController(_ coachMarksController: CoachMarksController, coachMarkViewsAt index: Int, madeFrom coachMark: CoachMark) -> (bodyView: CoachMarkBodyView, arrowView: CoachMarkArrowView?) {
        let coachViews = coachMarksController.helper.makeDefaultCoachViews(withArrow: true, arrowOrientation: coachMark.arrowOrientation)
        
        switch(index) {
        case 0:
            if (UserDefaults.firstTimeLogin) {
                coachViews.bodyView.hintLabel.text = "Tap on a zone to start"
                coachViews.bodyView.nextLabel.text = "OK"
                coachViews.bodyView.hintLabel.textColor = UIColor.mmBlue
            } else if (UserDefaults.showNotificationsCoach) {
                coachViews.bodyView.hintLabel.text = "Tap here to change notifications and help settings"
                coachViews.bodyView.nextLabel.text = "OK"
                coachViews.bodyView.hintLabel.textColor = UIColor.mmBlue
                UserDefaults.showNotificationsCoach = false
            } else if (UserDefaults.showDashboard && nMoles >= 2) {
                coachViews.bodyView.hintLabel.text = "Tap here for mole statistics"
                coachViews.bodyView.nextLabel.text = "OK"
                coachViews.bodyView.hintLabel.textColor = UIColor.mmBlue
                UserDefaults.showDashboard = false
            }
        case 1:
            if (UserDefaults.firstTimeLogin) {
                coachViews.bodyView.hintLabel.text = "Tap here to map moles on the back"
                coachViews.bodyView.nextLabel.text = "OK"
                coachViews.bodyView.hintLabel.textColor = UIColor.mmBlue
                UserDefaults.firstTimeLogin = false
            }
        default:
            coachViews.bodyView.hintLabel.text = ""
        }
        return (bodyView: coachViews.bodyView, arrowView: coachViews.arrowView)
    }
    
    func coachMarksController(_ coachMarksController: CoachMarksController, coachMarkAt index: Int) -> CoachMark {
        switch(index){
        case 0:
            if (UserDefaults.firstTimeLogin) {
                return coachMarksController.helper.makeCoachMark(for: zoneButton1)
            } else if (UserDefaults.showNotificationsCoach) {
                return coachMarksController.helper.makeCoachMark(for: demoVideosButton)
            } else if (UserDefaults.showDashboard && nMoles >= 2) {
                return coachMarksController.helper.makeCoachMark(for: dashboardView)
            } else {
                return coachMarksController.helper.makeCoachMark(for: view)
            }
        case 1:
            if (UserDefaults.firstTimeLogin) {
                return coachMarksController.helper.makeCoachMark(for: flipButton)
            } else {
                return coachMarksController.helper.makeCoachMark(for: view)
            }
        default:
            return coachMarksController.helper.makeCoachMark(for: view)
        }
    }
    
    func numberOfCoachMarks(for coachMarksController: CoachMarksController) -> Int {
        // Use cases match above...
        if (UserDefaults.firstTimeLogin) {
            return 2
        } else {
            if (UserDefaults.firstTimeLogin) {
                return 1
            } else if (UserDefaults.showNotificationsCoach) {
                return 1
            } else if (UserDefaults.showDashboard && nMoles >= 2) {
                return 1
            } else {
                return 0
            }
        }
    }
    
    private func getTabBarItemView(title: String) -> UIView {
        func _hasLabelWithTitle(parent: UIView, title: String) -> Bool {
            // Depth-first tree search
            // Terminating Condition:
            if "\(type(of: parent))" == "UITabBarButtonLabel" {
                if (parent as? UILabel)?.text ?? "" == title {
                    return true
                }
            } else {
                for child in parent.subviews {
                    if _hasLabelWithTitle(parent: child, title: title) {
                        return true
                    }
                }
            }
            return false
        }
        
        if let tabBarParent = self.tabBarController?.tabBar {
            for view in tabBarParent.subviews {
                // Note: the _correct_ way to do this _should_ be to compare type(of: view) == UITabBarButton.self
                // but UITabBarButton is closed (made private inside the UIKit module)
                if "\(type(of: view))" == "UITabBarButton" {
                    for child in view.subviews {
                        if "\(type(of: child))" == "UITabBarButtonLabel" {
                            if (child as? UILabel)?.text ?? "" == title {
                                return view
                            }
                        } else {
                            if _hasLabelWithTitle(parent: child, title: title) {
                                // This is needed in iOS 13 which now injects a couple of additional view classes into the
                                // hierarchy relative to iOS 12 which just had UITabBarButton -> UITabBarButtonLabel
                                return view
                            }
                        }
                    }
                }
            }
        }
        return self.tabBarController!.tabBar
    }
}

extension BodyMapViewController: CoachMarksControllerDelegate {
    func coachMarksController(_ coachMarksController: CoachMarksController, didEndShowingBySkipping skipped: Bool) {
        waitAndDisplayHint()
    }
}
