//
//  IdentifyMolesViewController
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

protocol IdentifyMolesDisplayLogic: class
{
    func displayHelp(viewModel: PopupHelp.Help.ViewModel)
    func displayHint()
    func molesSaved()
    func helpFinished()
    
    // Refactored functions
    func addObject(_ position: ObjectPosition)
    func batchUpdateMoleDetails(_ circles: ObjectPositionDictionary)
    func batchUpdateObjects(_ circles: ObjectPositionDictionary)
    func deleteCircle(_ circleID: Int)
    func deselectCircle(_ circleID: Int)
    func displayActionMenu(_ circle: ObjectPosition)
    func selectCircle(_ circleID: Int)
    func updateCirclePosition(_ viewModel: IdentifyMoles.ChangeCirclePosition)
    func updateMoleName(_ circleID: Int, newName: String)
    func updateCoinType(coinPosition: CoinPosition)
}

class IdentifyMolesViewController: BaseBodyMapViewController
{
    var interactor: IdentifyMolesBusinessLogic?
    var router: (NSObjectProtocol & IdentifyMolesRoutingLogic)?
    
    private var photoData: TakePhoto.PhotoData?
    private var coinData: CoinPosition?
    private var molesData: ShowZone.MolesData?
    private var circleWidgets = [Int:CircleWidget]()
    private var selectedID = -1
    private var photoEdges: PhotoEdges? = nil
    private var unsavedChanges = false
    private var pickerPopover: UIView?
    private var helpText: NSAttributedString?
    private var helpTitle: String?
    
    var isModelInitialized = false
    
    // Tracking variables for scroll operations
    var startingPt = CGPoint.zero
    var startingZoom: CGFloat = 0

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var helpButton: UIButton!
    
    // MARK: Methods
    
    convenience init(with photoData: TakePhoto.PhotoData, andCoinData coinData: CoinPosition? = nil, andMolesData molesData: ShowZone.MolesData? = nil)
    {
        self.init(nibName: "IdentifyMolesViewController", bundle: nil)
        self.photoData = photoData
        self.coinData = coinData
        self.molesData = molesData
        setup()
    }
    
    private func setup()
    {
        let viewController = self
        let interactor = IdentifyMolesInteractor()
        let presenter = IdentifyMolesPresenter()
        let router = IdentifyMolesRouter()
        viewController.interactor = interactor
        viewController.router = router
        interactor.presenter = presenter
        presenter.viewController = viewController
        router.viewController = viewController
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        title = "Mark Moles"

        // Set image in ImageView
        guard let image = UIImage(data: photoData!.jpegData) else { fatalError("missing image") }
        imageView.image = image
        
        // Create UIGestures
        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handleScenePan(recognizer:)))
        let singleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(recognizer:)))
        let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(recognizer:)))
        // Configure gestures
        singleTapRecognizer.numberOfTapsRequired = 1
        doubleTapRecognizer.numberOfTapsRequired = 2
        singleTapRecognizer.require(toFail: doubleTapRecognizer)
        // Add gestures
        scrollView.addGestureRecognizer(panRecognizer)
        scrollView.addGestureRecognizer(singleTapRecognizer)
        scrollView.addGestureRecognizer(doubleTapRecognizer)
        
        // Init scrollView values
        scrollView.bouncesZoom = false
        scrollView.bounces = false
        scrollView.isScrollEnabled = true
        scrollView.delegate = self
        scrollView.maximumZoomScale = 7.0
        scrollView.minimumZoomScale = 1.0
        
        helpButton.mmHelpify()     // Conform to help button style
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard imageView.image != nil else { fatalError() }
        imageView.frame = scrollView.frame
        
        // Initialize Worker
        IdentifySharedWorker.largeImageSize = imageView.image!.size
        IdentifySharedWorker.smallImageSize = photoData!.displayPhoto.size
        IdentifySharedWorker.scrollView = self.scrollView
        IdentifySharedWorker.imageView = self.imageView
        
        // Init Moles model
        // Must be done _after_ the scrollView has been laid out but ONLY the first time!
        if !isModelInitialized {
            if let navViewController = navigationController as? MeasurementController {
                if let zoneID = navViewController.zoneID {
                    let scrollSize = scrollView.bounds.size
                    let request = IdentifyMoles.InitModel.Request(photoData: photoData!, coinData: coinData, molesData:molesData ,zoneID: zoneID, scrollSize: scrollSize)
                    interactor?.initModel(request: request)
                    isModelInitialized = true
                }
            }
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Show help screen...eventually make conditional
        invokeHelp(self)  // Let interactor decide whether to show or not
    }
    
    func waitAndDisplayHint() {
        HintUtils.delay(milliseconds: HintUtils.defaultDelayMilliseconds) { [weak self] in
            self?.interactor?.requestHint()
        }
    }


    @IBAction func invokeHelp(_ sender: Any) {
        var request : PopupHelp.RequestType
        if sender is UIButton {
            request = .userRequest
        } else {
            request = .autoPopup
        }
        interactor?.requestHelp(requestType: request)
    }
    
    func helpFinished() {
        waitAndDisplayHint()
    }
    
    // MARK: Navigation bar button
    override func onBack() {
        if unsavedChanges {
            let menu = UIAlertController(title: "Changes Will be Lost",
                                         message: "You've tapped the Back button but have made some changes. Continuing will cause your changes to be lost. Do you want to continue?",
                                         preferredStyle: .alert)
            
            let actionStayHere = UIAlertAction(title: "Stay here", style: .default, handler:nil)
            let actionContinue = UIAlertAction(title: "Continue", style: .destructive, handler:
            { _ in
                self.router?.navigateBack(coinUsed: self.coinData != nil)
            })
            menu.addAction(actionStayHere)
            menu.addAction(actionContinue)
            
            self.present(menu, animated: true, completion: nil)
        }else{
            self.router?.navigateBack(coinUsed: self.coinData != nil)
        }
    }
    
    override func onDone() {
        
        if (UserDefaults.askWhenDone && molesData == nil) {
            let completeMoleSelection = UIAlertController(title: "Complete Mole Selection",
                                         message: "Have you identified all the moles you want to track?",
                                         preferredStyle: .alert)
            let actionYes = UIAlertAction(title: "Yes", style: .default, handler:
            {_ in
                self.interactor?.saveMolesAndCoinInDataBase()
            })
            let actionNo = UIAlertAction(title: "No", style: .cancel, handler:nil)
            let actionDontAsk = UIAlertAction(title: "Don't ask again", style: .destructive, handler:
            { _ in
                UserDefaults.askWhenDone = false
                self.interactor?.saveMolesAndCoinInDataBase()
            })
            
            
            completeMoleSelection.addAction(actionYes)
            completeMoleSelection.addAction(actionNo)
            completeMoleSelection.addAction(actionDontAsk)
            
            self.present(completeMoleSelection, animated: true, completion: nil)
        }
        else {
            interactor?.saveMolesAndCoinInDataBase()
        }
    }    
}

// MARK: - Gestures handlers
extension IdentifyMolesViewController {
    
    // Zoom in and zoom out
    @objc func handleDoubleTap(recognizer:UITapGestureRecognizer) {
        let rememberedID = selectedID
        if selectedID >= 0 {
            deselectCircle(selectedID)
        }
        if scrollView.zoomScale == scrollView.minimumZoomScale {
            scrollView.zoom(to: zoomRectForScale(scale: scrollView.maximumZoomScale, center: recognizer.location(in: imageView)),
                            animated: true)
        } else {
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
        }
        if rememberedID >= 0 {
            selectCircle(rememberedID)
        }
    }
    
    func zoomRectForScale(scale: CGFloat, center: CGPoint) -> CGRect {
        var zoomRect = CGRect.zero
        zoomRect.size.height = imageView.frame.size.height / scale
        zoomRect.size.width  = imageView.frame.size.width  / scale
        let newCenter = scrollView.convert(center, from: imageView)
        zoomRect.origin.x = newCenter.x - (zoomRect.size.width / 2.0)
        zoomRect.origin.y = newCenter.y - (zoomRect.size.height / 2.0)
        return zoomRect
    }
    
    // Search through list and return id of item (if one exists close enough to the gesture)
    // returns -1 if none were found
    func findClosestObject(near point: CGPoint) -> Int {
        var closestCircleID: Int = -1
        var smallestDistance: CGFloat = 10000.0

        for (circleId, circleView) in circleWidgets {
            let minDistance = max(24.0, (circleView.bounds.size.width/2.0))
            let distance = point.distance(to: circleView.center)
            if distance < minDistance {
                if distance < smallestDistance {
                    closestCircleID = circleId
                    smallestDistance = distance
                }
            }
        }
        return closestCircleID
    }
    
    // Select/Deselect mole
    @objc func handleTap(recognizer:UITapGestureRecognizer) {
        let touchPt = recognizer.location(in: scrollView)
        _handleTouch(point: touchPt)
    }
    
    func _handleTouch(point: CGPoint) {
        let objectID = findClosestObject(near: point)
        if objectID >= 0 {
            if objectID == selectedID {
                deselectCircle(selectedID)
            }
            else {
                selectCircle(objectID)
            }
        } else {
            let RaviProtocol = true
            if selectedID < 0 || RaviProtocol {
                unsavedChanges = true
                // Convert recognizer location (relative to scrollView) toIdentifyMolesViewController
                // small image coordinates
                let tapPointInSmallImage = IdentifySharedWorker.scrollViewToSmallImage(at: point)
                interactor?.newMole(at: tapPointInSmallImage)
            }
            else {
                deselectCircle(selectedID)
            }
        }
    }
    
    // Drag background
    @objc func handleScenePan(recognizer:UIPanGestureRecognizer) {
        let scrollPt = recognizer.translation(in: scrollView)
        var newPt = CGPoint.zero
        
        if recognizer.state == .began {
            startingPt = scrollView.contentOffset
        }
        else {
            newPt = startingPt
            newPt.x -= scrollPt.x
            newPt.y -= scrollPt.y
            if IdentifySharedWorker.isValidOffsetPoint(point: newPt) {
                scrollView.setContentOffset(newPt, animated: false)
            }
        }
    }
}

// MARK: - IdentifyMolesDisplayLogic
extension IdentifyMolesViewController : IdentifyMolesDisplayLogic {
    
    func addObject(_ position: ObjectPosition) {
        // position coming in relative to small image; need to convert to scrollView for widget placement
        let widgetPosition = IdentifySharedWorker.smallImageToScrollView(position: position)
        if position is MolePosition {
            let molePosition = position as! MolePosition
            let moleView = MoleWidget(center: widgetPosition.center, radius: widgetPosition.radius, state: molePosition.state, status: molePosition.status, moleName: molePosition.name, delegate: self, moleSize: molePosition.moleDetails)

            moleView.widgetID = molePosition.objectID
            
            self.scrollView.addSubview(moleView)
            
            self.circleWidgets[moleView.widgetID] = moleView
        }
        if position is CoinPosition {
            let coinPosition = position as! CoinPosition
            let coinView = CoinWidget(center: widgetPosition.center, radius: widgetPosition.radius, state: coinPosition.state, shouldShowMenu: true, coinName: coinPosition.coinType.toString(), delegate: self)
            
            coinView.widgetID = position.objectID
            
            self.scrollView.addSubview(coinView)
            
            self.circleWidgets[coinView.widgetID] = coinView
        }
    }
    
    func batchUpdateMoleDetails(_ circles: ObjectPositionDictionary) {
        for (_, circle) in circles {
            if let moleCircle = circle as? MolePosition {
                if let moleView = circleWidgets[moleCircle.objectID] as? MoleWidget {
                    if moleView.moleName != moleCircle.name || moleView.moleSize != moleCircle.moleDetails {
                        moleView.updateMoleLabels(moleName: moleCircle.name, moleSize: moleCircle.moleDetails)
                    }
                }
            }
        }
    }
    
    func batchUpdateObjects(_ circles: ObjectPositionDictionary) {
        for (_, circle) in circles {
            if let moleCircle = circle as? MolePosition {
                // its a mole
                if let moleView = circleWidgets[moleCircle.objectID] as? MoleWidget{

                    // Update Mole Status
                    if moleView.status != moleCircle.status {
                        moleView.status = moleCircle.status
                    }
                    
                    // Update View
                    moleView.setNeedsDisplay()
                    moleView.transform = CGAffineTransform.identity
                    moleView.redrawCircle()
                    
                    // Change state if needed
                    if moleView.state != moleCircle.state || moleCircle.state == .selected {
                        moleView.state = moleCircle.state
                    }
                    
                    // set selectedID
                    if moleCircle.state == .selected {
                        selectedID = moleCircle.objectID
                    }
                    
                    if moleView.moleName != moleCircle.name || moleView.moleSize != moleCircle.moleDetails {
                        moleView.updateMoleLabels(moleName: moleCircle.name, moleSize: moleCircle.moleDetails)
                    }
                    
                }
                else {
                    let widgetCircle = IdentifySharedWorker.smallImageToScrollView(position: moleCircle)
                    let moleView = MoleWidget(center: widgetCircle.center, radius: widgetCircle.radius,
                                              state: moleCircle.state, status: moleCircle.status, moleName: moleCircle.name,
                                              delegate: self, moleSize: moleCircle.moleDetails)
                    
                    moleView.widgetID = moleCircle.objectID
                    
                    self.scrollView.addSubview(moleView)
                    if moleView.state == .selected {
                        self.selectedID = moleCircle.objectID
                        moleView.showWidgetMenu()
                    }
                    self.circleWidgets[moleCircle.objectID] = moleView
                }
            }
            else if let coinCircle = circle as? CoinPosition {
                // Its a coin
                if let coinWidget = circleWidgets[coinCircle.objectID] as? CoinWidget{
                    // Change location if needed
                    if coinWidget.center != coinCircle.center {
                        coinWidget.center = coinCircle.center
                    }
                    // Change size if needed
                    if coinWidget.bounds.width != coinCircle.radius*2 || coinWidget.bounds.height != coinCircle.radius*2 {
                        coinWidget.bounds = CGRect(origin: CGPoint.zero, size: CGSize(width: coinCircle.radius*2, height: coinCircle.radius*2))
                    }
                    
                    // Update View
                    coinWidget.setNeedsDisplay()
                    coinWidget.transform = CGAffineTransform.identity
                    coinWidget.redrawCircle()
                    
                    // Change state if needed
                    if coinWidget.state != coinCircle.state || coinCircle.state == .selected {
                        coinWidget.state = coinCircle.state
                    }
                    
                    // set selectedID
                    if coinWidget.state == .selected {
                        selectedID = coinCircle.objectID
                    }
                    
                    if coinWidget.currentCoinName != coinCircle.name {
                        coinWidget.updateCoinName(coinName: coinCircle.name)
                    }
                }
                else {
                    // New coin
                    let widgetPosition = IdentifySharedWorker.smallImageToScrollView(position: coinCircle)
                    let coinWidget = CoinWidget(center: widgetPosition.center, radius: widgetPosition.radius, state: .unselected, shouldShowMenu: coinCircle.shouldShowMenu, coinName: coinCircle.name, delegate: self)
                    coinWidget.widgetID = coinCircle.objectID
                    coinWidget.isUserInteractionEnabled = false
                    self.scrollView.addSubview(coinWidget)
                    self.circleWidgets[coinCircle.objectID] = coinWidget
                    // set selectedID
                    if coinWidget.state == .selected {
                        selectedID = coinCircle.objectID
                    }
                    
                    if coinWidget.state == .selected {
                        coinWidget.showWidgetMenu()
                    }
                }
            }
        }
    }
    
    func deleteCircle(_ circleID: Int) {
        selectedID = -1
        if let circleView = circleWidgets[circleID] {
            circleView.showWidgetMenu(false)
            circleView.removeFromSuperview()
        }
        circleWidgets.removeValue(forKey: circleID)
    }
    
    func deselectCircle(_ circleID: Int) {
        selectedID = -1
        let circleWidget = circleWidgets[circleID]
        circleWidget!.showWidgetMenu(false, animated: false)
    }
    
    func displayHelp(viewModel: PopupHelp.Help.ViewModel) {
        self.helpText = viewModel.helpText
        self.helpTitle = viewModel.helpTitle
        
        let vc = PopupHelpViewController.getInstance()
        vc.delegate = self
        vc.displayHelpPopup(self) {[unowned self] in
            self.helpFinished()
        }
    }
    
    func displayHint() {
        print("identifyMolesViewController view's frame: \(self.view.frame)")
        self.showToast("Tap to add a mole", delegate: self)
    }
    
    func displayActionMenu(_ circle: ObjectPosition) {
        if let mole = circle as? MolePosition {
            let menu = UIAlertController(title: "Mole Menu", message: mole.name,  preferredStyle: .actionSheet)
            let actionRename = UIAlertAction(title: "Rename mole", style: .default, handler: {_ in self.onRename(mole: mole) })
            let actionMarkAsCoin = UIAlertAction(title: "Mark as coin", style: .default, handler: {_ in self.onMarkAsCoin() })
            let actionDelete = UIAlertAction(title: "Delete mole", style: .destructive, handler: {_ in self.onDelete(mole.objectID) })
            let actionDone = UIAlertAction(title: "Done", style: .cancel, handler: nil)
            switch mole.status {
            case .new:
                menu.addAction(actionRename)
                menu.addAction(actionMarkAsCoin)
                menu.addAction(actionDelete)
                menu.addAction(actionDone)
                break
            case .existingConfident:
                menu.addAction(actionRename)
                menu.addAction(actionDelete)
                menu.addAction(actionDone)
                break
            case .existingNotConfident:
                menu.addAction(actionRename)
                menu.addAction(actionDelete)
                menu.addAction(actionDone)
                break
            default:
                fatalError(#function + " Mole status undefined")
            }
            
            self.present(menu, animated: true, completion: nil)
        } else if circle is CoinPosition {
            showDenominationPicker()
        }
    }
    
    func molesSaved() {
        NotificationsManager.requestNotificationsAuthorization(presentingViewController: self, acceptCompletion: {
            // Schedule a notification
            NotificationsManager.scheduleFutureReminders()
            // Update Badge number
            NotificationsManager.updateBadgeNumber()
            
            self.router?.navigateToBodyMap()
        }, rejectCompletion: {
            self.router?.navigateToBodyMap()
        })
        
    }
    
    func selectCircle(_ circleID: Int) {
        if selectedID >= 0 {
            let widget = circleWidgets[selectedID]
            widget?.showWidgetMenu(false)
            selectedID = -1
        }
        if circleID >= 0 {
            selectedID = circleID
            let widget = circleWidgets[circleID]
            widget?.showWidgetMenu()
        }
    }
    
    func updateCirclePosition(_ viewModel: IdentifyMoles.ChangeCirclePosition) {
        // Translate the scrollView coordinates used to place the widget to
        // image coordinates used to define the actual/real-world/stored location+size
        let widget = circleWidgets[viewModel.widgetID]
        let convertedCenter = imageView.convert(viewModel.centerInImage, to: scrollView)
        let sizePt = CGPoint(x: viewModel.sizeInImage.width, y: viewModel.sizeInImage.height)
        let convertedPt = imageView.convert(sizePt, to: scrollView)
        let convertedSize = CGSize(width: convertedPt.x, height: convertedPt.y)
        
        widget?.updateWidgetPlacement(newCenter: convertedCenter, newSize: convertedSize)
    }
    
    func updateMoleName(_ circleID: Int, newName: String) {
        if let widget = circleWidgets[circleID] as? MoleWidget {
            widget.updateMoleLabels(moleName: newName, moleSize: widget.moleSize ?? "")
        }

    }
    
    func updateCoinType(coinPosition: CoinPosition) {
        if let widget = circleWidgets[coinPosition.objectID] as? CoinWidget {
            widget.updateCoinName(coinName: coinPosition.coinType.toString())
        }
    }
    
    // MARK: - Action Menu Handlers
    func onRename(mole: MolePosition) {
        let menu = UIAlertController(title: "Rename Mole",
                                     message: nil,
                                     preferredStyle: .alert)
        
        let actionSave = UIAlertAction(title: "Save", style: .default,
                                       handler:
            { _ in
                // Change name in datasource
                let newMoleName = menu.textFields?[0].text ?? ""
                if newMoleName != mole.name {
                    self.unsavedChanges = true
                    let request = IdentifyMoles.RenameMole.Request(newName: newMoleName, moleID: mole.objectID)
                    self.interactor?.renameMole(request: request)
                }
        })
        
        let actionDiscard = UIAlertAction(title: "Cancel", style: .destructive, handler: nil)
        menu.addAction(actionDiscard)
        menu.addAction(actionSave)
        menu.addTextField { (textField) in
            textField.text = mole.name
        }
        
        self.present(menu, animated: true, completion: nil)
    }
    
    func onMarkAsCoin(){
        self.showDenominationPicker()
    }
    
    func onDelete(_ circleID: Int){
        let menu = UIAlertController(title: "Delete Mole",
                                     message: "WARNING: this action cannot be undone. All pictures and data for this mole will be permanently deleted.",
                                     preferredStyle: .alert)
        
        let actionKeep = UIAlertAction(title: "Keep mole", style: .default,
                                       handler: nil)
        let actionDelete = UIAlertAction(title: "Permanently delete", style: .destructive, handler:
        { _ in
            self.unsavedChanges = true
            self.interactor?.deleteCircle(circleID)
        })
        menu.addAction(actionKeep)
        menu.addAction(actionDelete)
        
        self.present(menu, animated: true, completion: nil)
    }
        
}

// MARK: - UIScrollViewDelegate
extension IdentifyMolesViewController : UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }
    
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        // No need to go through the VIP loop with this. There is no "business logic" associated with
        // a pan of the image, just re-calculations of the placement of the widgets on the scrollView
        startingZoom = scrollView.zoomScale
        
        if selectedID >= 0 {
            let widget = circleWidgets[selectedID]
            widget?.showWidgetMenu(false, animated: false)
        }
        interactor?.userZoomed()
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        // No need to go through the VIP loop with this. There is no "business logic" associated with
        // a pan of the image, just re-calculations of the placement of the widgets on the scrollView
        let incrementalScale = scrollView.zoomScale / startingZoom
        startingZoom = scrollView.zoomScale
        for (_, widget) in circleWidgets {
            widget.rescaleCircleLayer(incrementalScale)
        }
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        if selectedID >= 0 {
            let widget = circleWidgets[selectedID]
            widget?.showWidgetMenu()
        }
    }
    
}

// MARK: - CircleWidgetDelegate
extension IdentifyMolesViewController : CircleWidgetDelegate {
    func longPressed(widgetID: Int) {
        if selectedID >= 0 && selectedID != widgetID {
            let widget = circleWidgets[selectedID]
            widget?.showWidgetMenu(false, animated: false)
        }
        if let widget = circleWidgets[widgetID] {
            widget.showWidgetMenu()
            interactor?.showActionMenu(objectID: widgetID)
            selectedID = widgetID
        }
    }
    
    func invokeActionsMenu(widgetID: Int) {
        if selectedID >= 0 && selectedID != widgetID {
            let widget = circleWidgets[selectedID]
            widget?.showWidgetMenu(false, animated: false)
            selectedID = -1
        }
        if let widget = circleWidgets[widgetID] {
            if widgetID != selectedID {
                widget.showWidgetMenu()
                selectedID = widgetID
            }
            interactor?.showActionMenu(objectID: widgetID)
        }
    }
    
    func widgetStartedMoving(widgetID: Int) {
        if selectedID == widgetID {
            let widget = circleWidgets[widgetID]
            widget?.showWidgetMenu(false, animated: false)
        }
        else if selectedID >= 0 {
            deselectCircle(selectedID)
        }
    }
    
    func widgetIsMoving(widgetID: Int, newCenter: CGPoint, newSize: CGSize) {
        let convertedCenter = scrollView.convert(newCenter, to: imageView)
        let sizePt = CGPoint(x: newSize.width, y: newSize.height)
        let convertedPt = scrollView.convert(sizePt, to: imageView)
        let convertedSize = CGSize(width: convertedPt.x, height: convertedPt.y)

        // TODO: rework to use CirclePosition, not center + size
        let request = IdentifyMoles.ChangeCirclePosition(widgetID: widgetID, centerInImage: convertedCenter, sizeInImage: convertedSize)
        interactor?.changeCirclePosition(request: request)
    }
    
    func widgetFinishedMoving(widgetID: Int) {
        if selectedID == widgetID {
            let widget = circleWidgets[widgetID]
            widget?.showWidgetMenu(true, animated: true)
        }
        else {
            selectCircle(widgetID)
        }
    }
}

// MARK: DenominationViewDelegate
extension IdentifyMolesViewController: DenominationViewDelegate {
    func didPickDenomination(_ denomination: CoinType?) {
        if denomination != nil {
            if let _ = circleWidgets[selectedID] as? CoinWidget {
                // Change coin name
                let request = IdentifyMoles.UpdateCoin.Request(coinType: denomination!, selectedID: selectedID)
                interactor?.updateCoinInfo(request: request)
            }else{
                // Mark as coin
                interactor?.markMoleAsCoin(circleID: selectedID, coinType: denomination!)
            }
        } else {
            // Delete selected object
            interactor?.deleteCircle(selectedID)
        }
    }

    // Helper
    func showDenominationPicker() {
        let pickerView = DenominationViewController()
        pickerView.delegate = self
        self.present(pickerView, animated: true, completion: nil)
    }

}

// MARK: - PopupHelpDataSource
extension IdentifyMolesViewController : PopupHelpDataSource {
    func getHelpText() -> NSAttributedString {
        let text = self.helpText ?? NSAttributedString(string: "No Data")
        return text
    }
    func getHelpTitle() -> String {
        let text = self.helpTitle ?? "No Title"
        return text
    }
}


// MARK: - ToastNotifications
extension IdentifyMolesViewController : ToastNotifications {
    func passingTouch(point: CGPoint) {
        let ptInScrollview = self.view.convert(point, to: scrollView)
        _handleTouch(point: ptInScrollview)
    }
}

