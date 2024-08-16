//
//  IdentifyCoinViewController.swift
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

enum IdentifyObjectTypes {
    case backgroundImage
    case coin
    case mole
}

protocol IdentifyCoinDisplayLogic: class
{
    func changeCoinType(newType: CoinType)
    func displayCoin(at newPosition: CirclePosition)
    func displayHelp(viewModel: PopupHelp.Help.ViewModel)
    func displayHint()
    func displayNewCoin(at: CoinPosition)
    func displaySelectedCoin(state: CircleState)
    func displayActionMenu()
    func noHelp()
    func removeCoin()
}

class IdentifyCoinViewController: BaseBodyMapViewController
{
    var interactor: IdentifyCoinBusinessLogic?
    var router: IdentifyCoinRoutingLogic?
    let coachMarksController = CoachMarksController()
    var photoData: TakePhoto.PhotoData?
    
    var image: UIImage!
    var coinType: CoinType = .penny
    var pickedCoinType: CoinType? = nil
    fileprivate var coinWidget:CoinWidget? = nil
    
    fileprivate var photoEdges: PhotoEdges? = nil
    fileprivate var unsavedChanges = false
    fileprivate var pickerPopover: UIView?
    fileprivate var helpText: NSAttributedString?
    fileprivate var helpTitle: String?
    
    // Tracking variables for scroll operations
    var startingPt = CGPoint.zero
    var startingZoom: CGFloat = 0

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var helpButton: UIButton!
    var point: CGPoint!
    var rightBarButton: UIView!

    convenience init(photoData: TakePhoto.PhotoData) {
        self.init(nibName: "IdentifyCoinViewController", bundle: nil)
        self.photoData = photoData
        setup()
    }
    
    // MARK: View Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        coachMarksController.dataSource = self
        coachMarksController.overlay.allowTap = true
        coachMarksController.overlay.color = .ccTranslucentGray
        coachMarksController.delegate = self
        title = "Mark Coin"
        
        // Set image in ImageView
        guard let image = UIImage(data: photoData!.jpegData) else { fatalError("missing image") }
        imageView.image = image
        
        // Add UIGestures
        let singleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(recognizer:)))
        let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(recognizer:)))
        singleTapRecognizer.numberOfTapsRequired = 1
        doubleTapRecognizer.numberOfTapsRequired = 2
        singleTapRecognizer.require(toFail: doubleTapRecognizer)
        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(recognizer:)))
        
        // Init scrollView values
        scrollView.addGestureRecognizer(panRecognizer)
        scrollView.addGestureRecognizer(singleTapRecognizer)
        scrollView.addGestureRecognizer(doubleTapRecognizer)
        scrollView.bouncesZoom = false
        scrollView.bounces = false
        scrollView.isScrollEnabled = true
        scrollView.delegate = self
        scrollView.maximumZoomScale = 7.0
        scrollView.minimumZoomScale = 1.0

        helpButton.mmHelpify()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard imageView.image != nil else { fatalError("missing image") }
        imageView.frame = scrollView.frame
        
        // Initialize Worker
        IdentifySharedWorker.largeImageSize = imageView.image!.size
        IdentifySharedWorker.smallImageSize = photoData!.displayPhoto.size
        IdentifySharedWorker.scrollView = self.scrollView
        IdentifySharedWorker.imageView = self.imageView

        let request = IdentifyCoin.GetPhotoEdges.Request(photoData: self.photoData!, scrollSize: scrollView.bounds.size)
        interactor?.calculatePhotoEdges(request: request)
        
        // Create UIView for Coach Card using CGRect around NavigationBar RightBarButtonItem
        let statusBarHeight: CGFloat = UIApplication.shared.statusBarFrame.height
        let navigationBarSize: CGSize = self.navigationController!.navigationBar.frame.size
        let rightBarButton1 = CGRect(x: navigationBarSize.width - 0.16*navigationBarSize.width, y: statusBarHeight+5, width: 0.16*navigationBarSize.width, height: navigationBarSize.height-8)
        rightBarButton = UIView(frame: rightBarButton1)

    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        invokeHelp(self)  // Let interactor decide whether to show or not
    }
    
    func displayCoach() {
        if UserDefaults.firstTimeIdentifyCoinOpened {
            coachMarksController.start(in: PresentationContext.currentWindow(of: self))
            UserDefaults.firstTimeIdentifyCoinOpened = false
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
    
    override func onBack() {
        if unsavedChanges {
            let menu = UIAlertController(title: "Changes Will be Lost",
                                         message: "You've tapped the Back button but have made some changes. Continuing will cause your changes to be lost. Do you want to continue?",
                                         preferredStyle: .alert)
            
            let actionStayHere = UIAlertAction(title: "Stay here", style: .default, handler:nil)
            let actionContinue = UIAlertAction(title: "Continue", style: .destructive, handler:
            { _ in
                self.router?.navigateBack()
            })
            menu.addAction(actionStayHere)
            menu.addAction(actionContinue)
            
            self.present(menu, animated: true, completion: nil)
        }else{
            self.router?.navigateBack()
        }
    }
    
    override func onNext() {
        if coinWidget != nil {
            let position = IdentifySharedWorker.positionFromWidget(widget: coinWidget!)
            let coinPosition = CoinPosition(withID: 0, atLocation: position.center, ofRadius: position.radius, withCoinType: coinType)
            
            router?.coinData = coinPosition
        }
        router?.navigateToIdentifyMole()
    }
    
    private func setup()
    {
        let viewController = self
        let interactor = IdentifyCoinInteractor()
        let presenter = IdentifyCoinPresenter()
        let router = IdentifyCoinRouter()
        viewController.interactor = interactor
        viewController.router = router
        interactor.presenter = presenter
        presenter.viewController = viewController
        router.viewController = viewController
        router.photoData = photoData
    }
    
    // Check if coin will be inside the photo
    
    func viewWillBeInsideTheEdges(center: CGPoint, radius: CGFloat) -> Bool {
        let futureMinX = center.x - radius
        let futureMinY = center.y - radius
        let futureMaxX = center.x + radius
        let futureMaxY = center.y + radius
        if let photoEdges = self.photoEdges {
            if futureMinX < photoEdges.minimumPosition.x || futureMaxX > photoEdges.maximumPosition.x || futureMinY < photoEdges.minimumPosition.y || futureMaxY > photoEdges.maximumPosition.y {
                return false
            }
        }
        return true
    }
}

// MARK: UIGesture handlers
extension IdentifyCoinViewController {
    
    // Zoom in and zoom out
    @objc func handleDoubleTap(recognizer:UITapGestureRecognizer) {
        if coinWidget != nil {
            coinWidget?.showWidgetMenu(false, animated: false)
        }
        if self.scrollView.zoomScale == self.scrollView.minimumZoomScale {
            self.scrollView.zoom(to: self.zoomRectForScale(scale: self.scrollView.maximumZoomScale,
                                                           center: recognizer.location(in: recognizer.view)),
                                 animated: true)
        } else {
            self.scrollView.setZoomScale(self.scrollView.minimumZoomScale, animated: true)
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
    
    // Select/Deselect coin
    @objc func handleTap(recognizer:UITapGestureRecognizer) {
        let touchPt = recognizer.location(in: scrollView)
        _handleTouch(point: touchPt)
    }
    
    func _handleTouch(point: CGPoint) {
        if coinWidget == nil {
            let tapPointInImage = IdentifySharedWorker.scrollViewToSmallImage(at: point)
            interactor?.newCoin(at: tapPointInImage)
        }
        else {
            let tapPoint = scrollView.convert(point, to: coinWidget!)
            if coinWidget?.hitTest(tapPoint, with: nil) != nil {
                interactor?.selectCoin(true)
            }
            else {
                interactor?.selectCoin(false)
            }
        }
    }
    
    // Drag background
    @objc func handlePan(recognizer:UIPanGestureRecognizer) {
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

// MARK: IdentifyCoinDisplayLogic
extension IdentifyCoinViewController : IdentifyCoinDisplayLogic {
    func changeCoinType(newType: CoinType) {
        // change type (if it's different)
        if coinType != newType {
            coinWidget?.updateCoinName(coinName: newType.toString())
            coinType = newType
        }
    }
    
    func displayCoin(at newPosition: CirclePosition) {
        if coinWidget != nil {
            let convertedPosition = IdentifySharedWorker.smallImageToScrollView(position: newPosition)
//            print("actual position: \(newPosition.center), widget position: \(convertedPosition.center)")
            let convertedSize = CGSize(width: convertedPosition.radius*2, height: convertedPosition.radius*2)
            coinWidget?.updateWidgetPlacement(newCenter: convertedPosition.center,
                                              newSize: convertedSize)
        }
    }
    
    func displayHelp(viewModel: PopupHelp.Help.ViewModel) {
        self.helpText = viewModel.helpText
        self.helpTitle = viewModel.helpTitle
        
        let vc = PopupHelpViewController.getInstance()
        vc.delegate = self
        vc.displayHelpPopup(self) {[unowned self] in
            self.displayCoach()
        }
    }

    func displayHint() {
        self.showToast("Tap to add a coin", delegate: self)
    }
    
    func displayNewCoin(at position: CoinPosition) {
        let widgetPosition = IdentifySharedWorker.smallImageToScrollView(position: position)

        coinWidget = CoinWidget(center: widgetPosition.center, radius: widgetPosition.radius, state: position.state, shouldShowMenu: false, coinName: position.coinType.toString(), delegate: self)
        
        coinWidget?.widgetID = 0
        self.scrollView.addSubview(coinWidget!)
        interactor?.selectCoin(true)
        interactor?.showCoinActionMenu()
    }
    
    func displaySelectedCoin(state: CircleState) {
        if state == .selected {
            coinWidget?.animateCircle()
            coinWidget?.showWidgetMenu()
        }
        else {
            coinWidget?.stopAnimatingCircle()
            coinWidget?.showWidgetMenu(false, animated: true)
        }
    }
    
    func displayActionMenu() {
        let pickerView = DenominationViewController()
        pickerView.delegate = self
        self.present(pickerView, animated: true, completion: nil)
    }
    
    func noHelp() {
        displayCoach()
    }
    
    func removeCoin() {
        coinWidget?.showWidgetMenu(false, animated: false)
        coinWidget?.removeFromSuperview()
        coinWidget = nil
    }
}

// MARK: UIScrollViewDelegate
extension IdentifyCoinViewController : UIScrollViewDelegate {
    // These don't change the actual object position relative to the small image, just the View object
    // relative to the containing scrollView
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }
    
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        // No need to go through the VIP loop with this. There is no "business logic" associated with
        // a pan of the image, just re-calculations of the placement of the widgets on the scrollView
        startingZoom = scrollView.zoomScale
        
        if coinWidget != nil {
            coinWidget?.showWidgetMenu(false, animated: false)
        }
        
        interactor?.userZoomed()
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        // No need to go through the VIP loop with this. There is no "business logic" associated with
        // a pan of the image, just re-calculations of the placement of the widgets on the scrollView
        let incrementalScale = scrollView.zoomScale / startingZoom
        startingZoom = scrollView.zoomScale
        if coinWidget != nil {
            coinWidget!.rescaleCircleLayer(incrementalScale)
        }
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        if coinWidget != nil {
            coinWidget!.showWidgetMenu()
        }
    }
}


// MARK: CircleWidgetDelegate

extension IdentifyCoinViewController : CircleWidgetDelegate {
    func longPressed(widgetID: Int) {
        interactor?.showCoinActionMenu()
    }
    
    func invokeActionsMenu(widgetID: Int) {
        interactor?.showCoinActionMenu()
    }
    
    func invokeActionsMenu() {
        interactor?.showCoinActionMenu()
    }
    
    func widgetStartedMoving(widgetID: Int) {
        if coinWidget != nil {
            interactor?.selectCoin(false)
        }
    }
    
    func widgetIsMoving(widgetID: Int, newCenter: CGPoint, newSize: CGSize) {
        let widgetPosition = WidgetPosition(center: newCenter, radius: newSize.width / 2.0)
        let newPosition = IdentifySharedWorker.scrollViewToSmallImage(position: widgetPosition)
        
        interactor?.changeCoinPosition(to: newPosition)
    }
    
    func widgetFinishedMoving(widgetID: Int) {
        if coinWidget != nil  {
            interactor?.selectCoin(true)
        }
    }
}

// MARK: DenominationViewDelegate
extension IdentifyCoinViewController: DenominationViewDelegate {
    func didPickDenomination(_ denomination: CoinType?) {
        interactor?.setCoinTypeToCoin(coinType: denomination)
    }
}

extension IdentifyCoinViewController : PopupHelpDataSource {
    func getHelpText() -> NSAttributedString {
        let text = self.helpText ?? NSAttributedString(string: "No Data")
        return text
    }
    func getHelpTitle() -> String {
        let text = self.helpTitle ?? "No Title"
        return text
    }
}

// RAVI - Instructions configuration
extension IdentifyCoinViewController : CoachMarksControllerDataSource {
    func coachMarksController(_ coachMarksController: CoachMarksController, coachMarkViewsAt index: Int, madeFrom coachMark: CoachMark) -> (bodyView: CoachMarkBodyView, arrowView: CoachMarkArrowView?) {
        let coachViews = coachMarksController.helper.makeDefaultCoachViews(withArrow: true, arrowOrientation: .top)
        
        switch(index) {
        case 0:
            coachViews.bodyView.hintLabel.text = "Click Next after you have placed a circle around the coin"
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
            return coachMarksController.helper.makeCoachMark(for: rightBarButton)
        default:
            return coachMarksController.helper.makeCoachMark(for: view)
        }
    }
    
    func numberOfCoachMarks(for coachMarksController: CoachMarksController) -> Int {
        return 1
    }
}

extension IdentifyCoinViewController: CoachMarksControllerDelegate {
    func coachMarksController(_ coachMarksController: CoachMarksController, didEndShowingBySkipping skipped: Bool) {
        waitAndDisplayHint()
    }
}


// MARK: - ToastNotifications
extension IdentifyCoinViewController : ToastNotifications {
    func passingTouch(point: CGPoint) {
        let ptInScrollview = self.view.convert(point, to: scrollView)
        _handleTouch(point: ptInScrollview)
    }
}

