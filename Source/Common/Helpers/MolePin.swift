//
//  MolePin.swift
//  MoleMapper
//
// Copyright (c) 2016, 2017 OHSU. All rights reserved.
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

protocol MolePinDelegate {
    func gotTapped(widgetID: Int)
    func invokeMoleMenu(widgetID: Int)
    func longPressed(widgetID: Int)
}

class MolePin : UIView {
    
    private var moleState: CircleState = .unselected
    var state: CircleState {
        get {
            return moleState
        }
        set (newState) {
            moleState = newState
            if newState == .selected {
                if self.superview != nil {
                    showPinMenu()
                }
            } else {
                if calloutView != nil {
                    showPinMenu(false)
                }
            }
        }
    }
    
    var status: MoleStatus!  {
        didSet {
            if status == .removedWaiting {
                pinImageView.image = UIImage(named: "molepinNoSpace-red")
            }
            else if status == .removedRecorded {
                pinImageView.image = UIImage(named: "molepinNoSpace-black")
            }
            else {
                pinImageView.image = UIImage(named: "molepinNoSpace")
            }
            pinImageView.setNeedsDisplay()
        }
    }
    
    var moleName:String = ""
    var moleSize:String? = nil
    var moleID: Int = 0
    var moleRadius: CGFloat = 0.0       // in screen units, not small image units
    fileprivate var calloutView: SMCalloutView?
    fileprivate var delegate: MolePinDelegate!
    fileprivate let pinImageView = UIImageView()
    static let pinHeight: CGFloat = 30
    static let pinWidth: CGFloat = 21
    
    convenience init(center: CGPoint, size: CGSize,
                     state: CircleState = .unselected,
                     status: MoleStatus = .existingConfident,
                     moleName: String,
                     moleID:Int,
                     delegate: MolePinDelegate,
                     moleSize: String? = nil)
    {
//        let frame = CGRect(x: center.x - radius, y: center.y - radius, width: size.width, height: size.height)
        let frame = CGRect(x: 0, y: 0, width: MolePin.pinWidth, height: MolePin.pinHeight)

        self.init(frame: frame)
        self.moleRadius = size.width/2
        self.moleState = state
        self.status = status
        self.moleName = moleName
        self.moleID = moleID
        self.delegate = delegate
        self.moleSize = moleSize
        
//        let pinRect = CGRect(x: 0, y: 0, width: MolePin.pinWidth, height: MolePin.pinHeight)
        pinImageView.frame = frame
        pinImageView.contentMode = .scaleAspectFit
        // Must still set the image here because property observers aren't called during inits
        if self.status == .removedWaiting {
            pinImageView.image = UIImage(named: "molepinNoSpace-red")
        }
        else if self.status == .removedRecorded {
            pinImageView.image = UIImage(named: "molepinNoSpace-black")
        }
        else {
            pinImageView.image = UIImage(named: "molepinNoSpace")
        }
        pinImageView.isUserInteractionEnabled = true
        
        self.addGestureRecognizer(UILongPressGestureRecognizer(target: self,
                                                                       action: #selector(handleLongPress)))
        self.addGestureRecognizer(UITapGestureRecognizer(target: self,
                                                                       action: #selector(handleTap)))

        addSubview(pinImageView)
        
        updatePinCenter(moleCenter: center)
        
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
//        return nil
        
        // just a test (above)...
        let parent = self.superview
        let relativePt = self.convert(point, to: parent)
        let centerPt = self.center
        let distance = centerPt.distance(to: relativePt)
        let radiusThreshold = max(48, moleRadius + 30)
        if distance < radiusThreshold {
            return self
        }
        else {
            return nil
        }

    }
    
    /// Updates the pin center placing it horizontally centered with respect to the mole but at the top of the mole
    ///
    /// - Parameters:
    ///   - moleCenter: widget center (UIView relative to scrollView)
    func updatePinCenter(moleCenter: CGPoint){
        // ignore (and eventually delete) radius
        var center = moleCenter
        center.y -= moleRadius
        center.y -= self.bounds.size.height / 2     // center is in pin; we want to move bottom of pin to top of mole
        
        self.center = center
        
    }
    
    func showPinMenu(_ doDisplay: Bool = true) {
        if doDisplay == false {
            if calloutView != nil {
                calloutView!.dismissCallout(animated: true)
                calloutView = nil
            }
            return
        }
        
        if calloutView != nil {
            return
        }
        let callout = SMCalloutView.platform()
        
        let menuButton = UIButton(type: .custom)
        menuButton.frame = CGRect(x: 0, y: 0, width: 28, height: 28)
        let menuButtonImage = UIImage(named: "details")
        menuButton.setBackgroundImage(menuButtonImage, for: .normal)
        menuButton.addTarget(self, action: #selector(menuButtonPressed), for: .touchUpInside)
        
        calloutView = callout
        calloutView!.title = moleName
        if moleSize != nil {
            calloutView!.subtitle = moleSize
        } else {
            calloutView!.subtitle = "not measured yet"
        }
//        calloutView!.leftAccessoryView = menuButton
        calloutView!.rightAccessoryView = menuButton

        calloutView!.presentCallout(from: self.frame, in: self.superview!, constrainedTo: self.superview!, animated: true)
        
    }
    
    func updateMoleName(moleName: String) {
        self.moleName = moleName
        if calloutView != nil {
            calloutView!.title = moleName
            // Can't figure out how to force a redraw while displayed; instead "bounce" the callout
            showPinMenu(false)
            showPinMenu(true)
        }
    }
    
    @objc func menuButtonPressed() {
        delegate?.invokeMoleMenu(widgetID: self.moleID)
    }
    
    @objc func handleLongPress(recognizer:UILongPressGestureRecognizer) {
        if recognizer.state == .began {
            delegate?.longPressed(widgetID: self.moleID)
        }
    }

    @objc func handleTap(recognizer:UITapGestureRecognizer) {
        if recognizer.state == .ended {
            delegate?.gotTapped(widgetID: self.moleID)
        }
    }
}
