//
//  ShowZoneViewController.swift
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
import Instructions

protocol ShowZoneDisplayLogic: class
{
    func displayActionsMenu(molePosition: MolePosition)
    func deleteMoleFromScreen(moleID: Int)
    func displayHelp(viewModel: PopupHelp.Help.ViewModel)
    func displayHint()
    func displayMoleHistory(mole30: Mole30)
    func displayMoles(viewModel: ShowZone.RetrieveMoles.ViewModel)
    func displayRenamedMole(position: MolePosition)
    func displaySelectedMole(moleID: Int)
    func displayUpdatedMoles(molePositions: MolePositionDictionary)
    func displayUpdatedMoleStatus(moleID: Int, newStatus: MoleStatus)
    func noHelp()
    func updateMolesChangedFlag()
}

class ShowZoneViewController: BaseBodyMapViewController
{
    var interactor: ShowZoneBusinessLogic?
    var router: (NSObjectProtocol & ShowZoneRoutingLogic & ShowZoneDataPassing)?
    
    fileprivate var areThereNotSavedChanges = false
    fileprivate var autoSave = true
    fileprivate var helpTitle: String?
    fileprivate var helpText: NSAttributedString?
    fileprivate var moleToShow: Mole30?
    fileprivate var moleViews = [Int:MolePin]()
    fileprivate var selectedID = -1
    var startingZoom: CGFloat = 1.0
    var startingPoints: [Int:CGPoint] = [:]
    fileprivate var userDidTapTakePhotograph = false
    fileprivate var userIsZooming = false
    fileprivate var zoneID: String = ""
    fileprivate var zoneTitle: String = ""

    @IBOutlet weak var helpButton: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var snapBtn: UIButton!
    let coachMarksController = CoachMarksController()
    var molePinButtonView: UIView!
    // Help support

    // MARK: Object lifecycle
    
    convenience init(with zoneID: String, andZoneTitle zoneTitle: String, andMoleToShow moleToShow: Mole30? = nil)
    {
        self.init(nibName: "ShowZoneViewController", bundle: nil)
        self.zoneID = zoneID
        self.zoneTitle = zoneTitle
        self.moleToShow = moleToShow
        
        setup()
    }
    
    // MARK: Setup
    
    private func setup()
    {
        let viewController = self
        let interactor = ShowZoneInteractor()
        let presenter = ShowZonePresenter()
        let router = ShowZoneRouter()
        viewController.interactor = interactor
        viewController.router = router
        interactor.presenter = presenter
        presenter.viewController = viewController
        router.viewController = viewController
        router.dataStore = interactor
    }
    
    // MARK: View lifecycle
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        coachMarksController.dataSource = self
        coachMarksController.delegate = self
        coachMarksController.overlay.allowTap = true
        coachMarksController.overlay.color = .ccTranslucentGray
        
        if moleToShow != nil {
            router?.navigateToViewMoleHistory(mole: moleToShow!, animated: false)
        }
        
        // Set title
        setBodyMapTitle()

        // set navigation buttons.
        setupNavigationMenuItems(navigationType: .backOnly)
        
        
        // If autosave is false we will show save button
        if !autoSave {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(saveTapped))
        }
        
        // Set Scroll View values
        scrollView.maximumZoomScale = 4.0
        scrollView.minimumZoomScale = 1.0
        scrollView.bounces = false
        scrollView.bouncesZoom = false

        // Configure buttons
        snapBtn.mmMakeRounded()
        helpButton.mmHelpify()
        
        // Add UIGestures
        let singleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(recognizer:)))
        singleTapRecognizer.numberOfTapsRequired = 1
        self.scrollView.addGestureRecognizer(singleTapRecognizer)
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        imageView.frame = scrollView.frame
        
        // Initialize Shared Worker
        // The image sizes are set in retrieveMoles() in ShowZoneWorker
        IdentifySharedWorker.scrollView = self.scrollView
        IdentifySharedWorker.imageView = self.imageView
        
        // Retrieve Moles and Image from CoreData
        retrieveMoles()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Show help screen...eventually make conditional
        showHelp(self)  // Let interactor decide whether to show or not
        if UserDefaults.areHelpScreensDisabled {
            noHelp()
        }
    }
    
    // MARK: Retrieve Moles
    
    func retrieveMoles()
    {
        let scrollSize = scrollView.bounds.size
        let request = ShowZone.RetrieveMoles.Request(zoneID: zoneID, zoneTitle: zoneTitle, scrollSize: scrollSize, autoSave: autoSave)
        interactor?.retrieveMoles(request: request)
    }
    
    // MARK: Navigation bar button
    
    override func onBack() {
        // If autoSave is true we will ignore the alert
        if  !autoSave && areThereNotSavedChanges {
            let menu = UIAlertController(title: "Changes Will be Lost",
                                         message: "You've tapped the Back button but have made some changes. If you continue, you'll lose those changes.",
                                         preferredStyle: .alert)
            
            let actionYes = UIAlertAction(title: "Discard changes", style: .destructive, handler:
            { _ in
                self.router?.navigateBack()
            })
            let actionNo = UIAlertAction(title: "Cancel", style: .default, handler:nil)
            menu.addAction(actionYes)
            menu.addAction(actionNo)
            
            self.present(menu, animated: true, completion: nil)
        }else{
            router?.navigateBack()
        }
    }
    
    @objc func saveTapped(){
        // Save changes in database
        interactor?.updateDataBase()
    }
    
    @IBAction func showHelp(_ sender: Any)
    {
        var request : PopupHelp.Help.Request?
        if sender is UIButton {
            request = PopupHelp.Help.Request(.userRequest)
        } else {
            request = PopupHelp.Help.Request(.autoPopup)
        }
        interactor?.requestHelp(request: request!)
    }
    
    func displayCoach(){
        if UserDefaults.firstZoneReview {
            coachMarksController.start(in: PresentationContext.currentWindow(of: self))
            UserDefaults.firstZoneReview = false
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

    @IBAction func remeasureZone(_ sender: Any) {
        // Show alert if needed
        // If autoSave is true we will ignore the alert
        if !autoSave && areThereNotSavedChanges {
            let menu = UIAlertController(title: "Changes Will be Lost",
                                         message: "You've tapped Photograph zone but have made some changes without saving them. Do you want to save your changes first?",
                                         preferredStyle: .alert)
            
            let actionYes = UIAlertAction(title: "Yes, save changes", style: .default, handler:
            { _ in
                self.userDidTapTakePhotograph = true
                // Save changes
                self.interactor?.updateDataBase()
            })
            let actionNo = UIAlertAction(title: "No, ignore changes", style: .destructive, handler:
            { _ in
                self.userDidTapTakePhotograph = true
                self.areThereNotSavedChanges = false
                // Ignore changes - Update screen with moles in dataBase
                let scrollHeigth = UIScreen.main.bounds.height - self.navigationController!.navigationBar.frame.height - UIApplication.shared.statusBarFrame.height
                let scrollSize = CGSize(width: UIScreen.main.bounds.width, height: scrollHeigth)
                let request = ShowZone.RetrieveMoles.Request(zoneID: self.zoneID, zoneTitle: self.zoneTitle, scrollSize: scrollSize, scrollZoomScale: self.scrollView.zoomScale)
                self.interactor?.retrieveMoles(request: request)
            })
            menu.addAction(actionYes)
            menu.addAction(actionNo)
            
            self.present(menu, animated: true, completion: nil)
        }else{
            router?.navigateToRephotographZone()
        }
    }
    
    // Select/Deselect mole
    @objc func handleTap(recognizer:UITapGestureRecognizer) {
        if recognizer.state == .ended {
            interactor?.selectMole(moleID: -1)
        }
    }
    
    func updateMoles(molePositions: [Int:MolePosition]) {
        selectedID = -1
        for (_, moleCircle) in molePositions {
            let widgetPosition = IdentifySharedWorker.smallImageToScrollView(position: moleCircle)
            if let moleView = moleViews[moleCircle.objectID] {
                
                if moleCircle.status != moleView.status {
                    moleView.status = moleCircle.status
                }
                
                moleView.updatePinCenter(moleCenter: widgetPosition.center)
                
                // Change state if needed
                if (moleView.state != moleCircle.state || moleCircle.state == .selected) && !userIsZooming {
                    moleView.state = moleCircle.state
                }
                
                // set selectedID
                if moleCircle.state == .selected {
                    selectedID = moleCircle.objectID
                }
                
                if moleView.moleName != moleCircle.name {
                    moleView.updateMoleName(moleName: moleCircle.name)
                }
                
            }
            else {
                let moleView = MolePin(center: widgetPosition.center,
                                       size: CGSize(width: widgetPosition.radius*2, height: widgetPosition.radius*2),
                                       status:moleCircle.status, moleName: moleCircle.name, moleID: moleCircle.objectID,
                                       delegate: self, moleSize: moleCircle.moleDetails)
                moleView.isUserInteractionEnabled = true
                //                moleView.isUserInteractionEnabled = false
                self.scrollView.addSubview(moleView)
                self.moleViews[moleCircle.objectID] = moleView
                molePinButtonView = moleView
            }
        }
        if userDidTapTakePhotograph {
            userDidTapTakePhotograph = false
            router?.navigateToRephotographZone()
        }
    }
    
}

// MARK: - ShowZoneDisplayLogic

extension ShowZoneViewController : ShowZoneDisplayLogic {
    func displayActionsMenu(molePosition: MolePosition) {
        //        guard let mole = moleViews[moleID] else { return }
        //        let mole = viewModel.mole
        
        let menu = UIAlertController(title: "Mole Menu", message: molePosition.name, preferredStyle: .actionSheet)
        
        let actionRename = UIAlertAction(title: "Rename mole", style: .default, handler: {_ in self.onRename(molePosition: molePosition) })
        
        let actionViewHistory = UIAlertAction(title: "View History", style: .default, handler: {_ in self.onViewHistory(molePosition: molePosition) })
        
        let actionDelete = UIAlertAction(title: "Delete mole", style: .destructive, handler: {_ in self.onDelete(molePosition: molePosition) })
        
        let actionDone = UIAlertAction(title: "Done", style: .cancel, handler: nil)
        
        switch molePosition.status {
        case .new:
            // There aren't new moles in this View Controller
            break
        case .existingConfident:
            menu.addAction(actionViewHistory)
            menu.addAction(actionRename)
            menu.addAction(actionDelete)
            menu.addAction(actionDone)
            break
        case .existingNotConfident:
            // There aren't existingNotConfident moles in this View Controller
            break
        default:
            fatalError(#function + " - uncaught mole status")
        }
        
        self.present(menu, animated: true, completion: nil)
    }
    

    func displayHelp(viewModel: PopupHelp.Help.ViewModel)
    {
        self.helpText = viewModel.helpText
        self.helpTitle = viewModel.helpTitle

        let vc = PopupHelpViewController.getInstance()
        vc.delegate = self
        vc.displayHelpPopup(self) {[unowned self] in
            self.displayCoach()
        }
    }
    
    func displayHint() {
        self.showToast("Tap on a mole pin to show name and menu")
    }
    
    func displayMoles(viewModel: ShowZone.RetrieveMoles.ViewModel)
    {
        imageView.image = viewModel.fullImage
        updateMoles(molePositions: viewModel.molePositions)
    }
    
    func deleteMoleFromScreen(moleID: Int) {
        selectedID = -1
        if let moleView = moleViews[moleID] {
            moleView.showPinMenu(false)
            moleView.removeFromSuperview()
        }
        moleViews.removeValue(forKey: moleID)
    }
    
    func displaySelectedMole(moleID: Int) {
        // Deselect explicitly, or "other" mole if selecting new mole
        if moleID != selectedID || moleID == -1 {
            if selectedID >= 0 {
                let selectedWidget = moleViews[selectedID]
                selectedWidget?.showPinMenu(false)
                selectedID = -1
            }
        }
        if moleID >= 0 {
            let selectedWidget = moleViews[moleID]
            if moleID == selectedID {
                selectedWidget?.showPinMenu(false)
                selectedID = -1
            }
            else {
                selectedWidget?.showPinMenu(true)
                selectedID = moleID
            }
        }
    }
    
 
    func displayMoleHistory(mole30: Mole30) {
        router?.navigateToViewMoleHistory(mole: mole30, animated: true)
    }
    
    func displayRenamedMole(position: MolePosition) {
        if let selectedWidget = moleViews[position.objectID] {
            selectedWidget.moleName = position.name
            selectedWidget.showPinMenu(false)
            selectedWidget.showPinMenu(true)
        }
    }
    
    func displayUpdatedMoles(molePositions: MolePositionDictionary) {
        updateMoles(molePositions: molePositions)
    }
    
    func displayUpdatedMoleStatus(moleID: Int, newStatus: MoleStatus) {
        if let molePin = moleViews[moleID] {
            molePin.status = newStatus  // should automatically reset pin image
        }
    }
    

    func noHelp() {
        displayCoach()
    }
    
    func updateMolesChangedFlag() {
        areThereNotSavedChanges = false
        if userDidTapTakePhotograph {
            userDidTapTakePhotograph = false
            router?.navigateToRephotographZone()
        }
    }
    
}

// MARK: - UIScrollViewDelegate
extension ShowZoneViewController : UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }

    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        userIsZooming = true
        startingZoom = scrollView.zoomScale
        for (pinID, molePin) in moleViews {
            startingPoints[pinID] = molePin.center
        }
        let moleView = moleViews[selectedID]
        moleView?.showPinMenu(false)
        
        interactor?.userZoomed()
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let incrementalScale = scrollView.zoomScale / startingZoom
        for (pinID, startingScreenPoint) in startingPoints {
            var center = startingScreenPoint
            center.x *= incrementalScale
            center.y *= incrementalScale
            
            moleViews[pinID]!.center = center
        }
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        userIsZooming = false
        if let moleView = moleViews[selectedID] {
            moleView.showPinMenu(true)
        }
    }
    
}

// MARK: - MolePinDelegate
extension ShowZoneViewController : MolePinDelegate {
    func gotTapped(widgetID: Int) {
        interactor?.selectMole(moleID: widgetID)
    }
    
    func invokeMoleMenu(widgetID: Int) {
        interactor?.showActionsMenu(moleID: widgetID)
    }
    
    func longPressed(widgetID: Int) {
        interactor?.selectMole(moleID: widgetID)
        interactor?.longPressMole(moleID: widgetID)
    }
}

// MARK: - Mole menu methods
extension ShowZoneViewController {
    
    func onViewHistory(molePosition: MolePosition){
        interactor?.retrieveMole30ForViewHistory(moleID: molePosition.objectID)
    }
    
    func onRename(molePosition: MolePosition){
        let menu = UIAlertController(title: "Rename Mole",
                                     message: nil,
                                     preferredStyle: .alert)
        
        let actionSave = UIAlertAction(title: "Save", style: .default,
                                       handler:
            { _ in
                // Change name in datasource
                let newMoleName = menu.textFields?[0].text ?? ""
                if newMoleName != molePosition.name {
                    self.areThereNotSavedChanges = true
                    let request = ShowZone.RenameMole.Request(newName: newMoleName, moleID: molePosition.objectID)
                    self.interactor?.renameMole(request: request)
                }
        })
        
        let actionDiscard = UIAlertAction(title: "Cancel", style: .destructive, handler: nil)
        menu.addAction(actionDiscard)
        menu.addAction(actionSave)
        menu.addTextField { (textField) in
            textField.text = molePosition.name
        }
        
        self.present(menu, animated: true, completion: nil)
    }
       
    func onDelete(molePosition: MolePosition){
        let alert = UIAlertController(title: "Delete Mole",
                                      message: "WARNING: this action cannot be undone. All pictures and data for this mole will be permanently deleted.",
                                      preferredStyle: .alert)
        
        let actionKeep = UIAlertAction(title: "Keep mole", style: .default,
                                       handler: nil)
        let actionDelete = UIAlertAction(title: "Permanently delete", style: .destructive, handler:
        { _ in
            self.areThereNotSavedChanges = true
            self.interactor?.deleteMole(moleID: molePosition.objectID)
        })
        alert.addAction(actionKeep)
        alert.addAction(actionDelete)
        
        self.present(alert, animated: true, completion: nil)
    }
       
}

extension ShowZoneViewController : PopupHelpDataSource {
    func getHelpText() -> NSAttributedString {
        let text = self.helpText ?? NSAttributedString(string: "No Data")
        return text
    }
    func getHelpTitle() -> String {
        let text = self.helpTitle ?? "No Title"
        return text
    }
}

// MARK:-  CoachMarksControllerDataSource

extension ShowZoneViewController : CoachMarksControllerDataSource {
    func coachMarksController(_ coachMarksController: CoachMarksController, coachMarkViewsAt index: Int, madeFrom coachMark: CoachMark) -> (bodyView: CoachMarkBodyView, arrowView: CoachMarkArrowView?) {
        let coachViews = coachMarksController.helper.makeDefaultCoachViews(withArrow: true, arrowOrientation: coachMark.arrowOrientation)
        
        switch(index) {
        case 0:
            coachViews.bodyView.hintLabel.text = "Tap on the pin to display Menu"
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
            return coachMarksController.helper.makeCoachMark(for: molePinButtonView)
        default:
            return coachMarksController.helper.makeCoachMark(for: view)
        }
    }
    
    func numberOfCoachMarks(for coachMarksController: CoachMarksController) -> Int {
        return 1
    }
}

extension ShowZoneViewController: CoachMarksControllerDelegate {
    func coachMarksController(_ coachMarksController: CoachMarksController, didEndShowingBySkipping skipped: Bool) {
        waitAndDisplayHint()
    }
}

