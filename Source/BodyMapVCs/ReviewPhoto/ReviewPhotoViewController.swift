//
//  ReviewPhotoViewController.swift
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

enum ReviewPhotoScrollViews : Int {
    case upperView = 1
    case lowerView = 2
}

protocol ReviewPhotoDisplayLogic: class
{
    func displayHelp(viewModel: PopupHelp.Help.ViewModel)
    func displayInitialPositions(viewModel: ReviewPhoto.InitialValues.ViewModel)
    func displayResizedRectangle(viewModel: ReviewPhoto.ResizeRectangle.ViewModel)
    func displayRecenteredLowerView(viewModel: ReviewPhoto.ReCenterLowerView.ViewModel)
    func displayRecenteredUpperView(viewModel: ReviewPhoto.ReCenterUpperView.ViewModel)
    func displayNewZoomScale(viewModel: ReviewPhoto.DoubleTapZoom.ViewModel)
}

extension ReviewPhotoViewController: ReviewPhotoDisplayLogic {
    func displayHelp(viewModel: PopupHelp.Help.ViewModel) {
        self.helpText = viewModel.helpText
        self.helpTitle = viewModel.helpTitle
        
        let vc = PopupHelpViewController.getInstance()
        vc.delegate = self
        vc.displayHelpPopup(self) {
//            print("ReviewMolesViewController -> Help returned")
        }
    }
    
    func displayInitialPositions(viewModel: ReviewPhoto.InitialValues.ViewModel)
    {
        DispatchQueue.main.async {
            self.initializingValues = true
            self.separatorPositionY.constant = viewModel.separatorOriginY
            self.rectangleView.frame = viewModel.rectangleFrame
            self.originalRectangleSize = viewModel.rectangleFrame.size
            self.lowerScrollView.minimumZoomScale = viewModel.lowerScrollScale
            self.lowerScrollView.maximumZoomScale = viewModel.lowerScrollScale
            self.lowerScrollView.zoomScale = viewModel.lowerScrollScale
            self.upperScrollView.minimumZoomScale = 1.0
            self.upperScrollView.maximumZoomScale = viewModel.rectangleMaxZoomScale
            self.upperScrollView.isScrollEnabled = true
            self.upperScrollView.setContentOffset(viewModel.upperScrollCenterOffset, animated: false)
            self.lowerScrollView.setContentOffset(viewModel.lowerScrollCenterOffset, animated: false)
            let zoom1X = CGFloat(2.0)
            self.upperScrollView.zoomScale = zoom1X
        }
    }
    
    func displayResizedRectangle(viewModel: ReviewPhoto.ResizeRectangle.ViewModel) {
        DispatchQueue.main.async {
            self.rectangleView.frame = viewModel.rectangleFrame
        }
    }
    
    func displayRecenteredLowerView(viewModel: ReviewPhoto.ReCenterLowerView.ViewModel) {
        DispatchQueue.main.async {
            self.upperScrollView.setContentOffset(viewModel.upperScrollViewContentOffset, animated: false)
            self.lowerScrollView.setContentOffset(viewModel.lowerScrollViewContentOffset, animated: false)
        }
    }
    
    func displayRecenteredUpperView(viewModel: ReviewPhoto.ReCenterUpperView.ViewModel) {
        DispatchQueue.main.async {
            self.lowerScrollView.setContentOffset(viewModel.lowerScrollViewContentOffset, animated: false)
            self.upperScrollView.setContentOffset(viewModel.upperScrollViewContentOffset, animated: false)
        }
    }
    
    func displayNewZoomScale(viewModel: ReviewPhoto.DoubleTapZoom.ViewModel) {
        DispatchQueue.main.async {
            self.upperScrollView.zoomScale = viewModel.zoomScale
        }
    }
    
}

class ReviewPhotoViewController: UIViewController
{
    var interactor: ReviewPhotoBusinessLogic?
    var router: ReviewPhotoRoutingLogic?
    
    // MARK: Object lifecycle
    
    internal var image: UIImage!
    internal var photoData: Data? = nil
    internal var lensPosition: Float?
    internal var gravityData: TakePhoto.GravityData?

    internal var helpText: NSAttributedString?
    internal var helpTitle: String?

    internal var originalRectangleSize = CGSize(width: 0, height: 0)
    internal var userIsScrollingUpperView = false
    internal var userIsScrollingLowerView = false
    internal var userIsZooming = false
    internal var didZoomProgrammatically = false
    internal var initializingValues = false
    @IBOutlet weak var separatorView: UIView!
    @IBOutlet weak var separatorPositionY: NSLayoutConstraint!
    @IBOutlet weak var upperScrollView: UIScrollView!
    @IBOutlet weak var lowerScrollView: UIScrollView!
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var upperImageView: UIImageView!
    @IBOutlet weak var lowerImageView: UIImageView!
    @IBOutlet weak var upperContainerView: UIView!
    @IBOutlet weak var lowerContainerView: UIView!
    @IBOutlet weak var rectangleView: ZoomAreaView!
    @IBOutlet weak var helpButton: UIButton!
    
    convenience init(photoData: TakePhoto.PhotoData) {
        self.init(nibName: "ReviewPhotoViewController", bundle: nil)
        
        self.image = photoData.displayPhoto
        self.photoData = photoData.jpegData
        self.lensPosition = photoData.lensPosition
        self.gravityData = photoData.gravityData
        
        setup()
    }
    
    func calculateInitialViewValues()
    {
        let request = ReviewPhoto.InitialValues.Request(separatorViewHeight: separatorView.frame.height, toolbarHeight: toolbar.frame.height, realImageSize:(lowerImageView.image?.size)!, lowerScrollSize: lowerScrollView.frame.size, upperContainerSize: upperContainerView.frame.size, upperScrollWidth: upperScrollView.frame.width, lowerContainerSize: lowerContainerView.frame.size)
        
        interactor?.calculateInitialViewValues(request: request)
    }
    
    private func setup()
    {
        let viewController = self
        let interactor = ReviewPhotoInteractor()
        let presenter = ReviewPhotoPresenter()
        let router = ReviewPhotoRouter()
        viewController.interactor = interactor
        viewController.router = router
        interactor.presenter = presenter
        presenter.viewController = viewController
        router.viewController = viewController
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        // Set images in image views
        upperImageView.image = image
        lowerImageView.image = UIImage(data: photoData!)
        // Add border to rectangle
        rectangleView.layer.borderWidth = 2.0
        rectangleView.layer.borderColor = UIColor.yellow.cgColor
        // Add border to lower view
        lowerScrollView.layer.borderWidth = 5.0
        lowerScrollView.layer.borderColor = UIColor.yellow.cgColor
        let tap = UITapGestureRecognizer(target: self, action: #selector(doubleTapped))
        tap.numberOfTapsRequired = 2
        upperScrollView.addGestureRecognizer(tap)
        self.calculateInitialViewValues()
        
        self.helpButton.mmHelpify()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // Show help screen...eventually make conditional
        invokeHelp(self)  // Let interactor decide whether to show or not
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    // MARK: Toolbar methods
    
    @IBAction func retakePhoto(_ sender: Any) {
        router?.navigateBack()
    }
    
    @IBAction func usePhoto(_ sender: Any) {
        router?.photoData = TakePhoto.PhotoData(displayPhoto: self.image!, jpegData: self.photoData!, lensPosition: self.lensPosition!, gravityData: self.gravityData)
        
        router?.navigateToCoinUsed()
    }
    
    // MARK: UITapGestures
    
    @objc func doubleTapped() {
        let request = ReviewPhoto.DoubleTapZoom.Request(currentZoomScale: upperScrollView.zoomScale)
        interactor?.calculateNewZoomScale(request: request)
    }
    
    @IBAction func invokeHelp(_ sender: Any) {
        var request : PopupHelp.Help.Request?
        if sender is UIButton {
            request = PopupHelp.Help.Request(.userRequest)
        } else {
            request = PopupHelp.Help.Request(.autoPopup)
        }
        interactor?.requestHelp(request: request!)
    }
}

extension ReviewPhotoViewController: UIScrollViewDelegate {
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        if scrollView.tag == ReviewPhotoScrollViews.upperView.rawValue {
            if initializingValues {
                initializingValues = false
                didZoomProgrammatically = true
            }
            let request = ReviewPhoto.ResizeRectangle.Request(originalRectangleSize: originalRectangleSize, scrollViewZoomScale: scrollView.zoomScale, scrollViewSize: CGSize(width: scrollView.frame.width, height: separatorPositionY.constant))
            interactor?.resizeRectangle(request: request)
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if scrollView.tag == ReviewPhotoScrollViews.upperView.rawValue {
            userIsScrollingUpperView = true
            userIsScrollingLowerView = false
        }else if scrollView.tag == ReviewPhotoScrollViews.lowerView.rawValue{
            userIsScrollingUpperView = false
            userIsScrollingLowerView = true
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        userIsScrollingUpperView = false
        userIsScrollingLowerView = false
    }
    
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        scrollView.setContentOffset(scrollView.contentOffset, animated: false)
    }
    
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        userIsZooming = true
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        userIsZooming = false
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.tag == ReviewPhotoScrollViews.upperView.rawValue {
            if let image = upperImageView.image {
                
                let imageSize = image.sizeAspectFit(aspectRatio: image.size, boundingSize: CGSize(width: upperImageView.frame.size.width, height: self.separatorPositionY.constant))
                
                if userIsScrollingUpperView || userIsZooming || didZoomProgrammatically{
                    didZoomProgrammatically = false
                    let request = ReviewPhoto.ReCenterLowerView.Request(scrollViewZoomScale: scrollView.zoomScale, scrollViewContentOffset: scrollView.contentOffset, imageSize: imageSize, upperContainerViewSize: upperContainerView.frame.size, scrollViewSize: scrollView.frame.size, rectangleViewSize: CGSize(width: originalRectangleSize.width*scrollView.zoomScale, height: originalRectangleSize.height*scrollView.zoomScale), originalRectangleSize: originalRectangleSize, lowerScrollViewZoomScale: lowerScrollView.zoomScale)
                    interactor?.reCenterLowerView(request: request)
                }
            }
        } else if scrollView.tag == ReviewPhotoScrollViews.lowerView.rawValue {
            if let image = lowerImageView.image {
                let imageSize = image.sizeAspectFit(aspectRatio: image.size, boundingSize: CGSize(width: upperImageView.frame.size.width, height: self.separatorPositionY.constant))
                if userIsScrollingLowerView {
                    let request = ReviewPhoto.ReCenterUpperView.Request(scrollViewZoomScale: scrollView.zoomScale, imageSize: imageSize, scrollViewContentOffset: scrollView.contentOffset, lowerContainerViewSize: lowerContainerView.frame.size, upperScrollViewSize: upperScrollView.frame.size, originalRectangleSize: originalRectangleSize, upperScrollViewZoomScale: upperScrollView.zoomScale, rectangleViewSize: rectangleView.frame.size, scrollViewSize: scrollView.frame.size)
                    interactor?.reCenterUpperView(request: request)
                }
            }
        }
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        if scrollView.tag == ReviewPhotoScrollViews.upperView.rawValue {
            return upperContainerView
        }else{
            return lowerContainerView
        }
    }
}

extension ReviewPhotoViewController : PopupHelpDataSource {
    func getHelpText() -> NSAttributedString {
        let text = self.helpText ?? NSAttributedString(string: "No Data")
        return text
    }
    func getHelpTitle() -> String {
        let text = self.helpTitle ?? "No Title"
        return text
    }
}
