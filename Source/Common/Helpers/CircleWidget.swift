//
//  CircleView.swift
//  FixRewrite
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


// ************************************************************************************
// NOTE: all coordiates in this world are relative to the parent view that
// contains the widget (usually a UIScrollView). The scene's ViewController
// is responsible for mapping between "display" coordinates and "image" coordinates
// ************************************************************************************

protocol CircleWidgetDelegate {
    func invokeActionsMenu(widgetID: Int)
    func longPressed(widgetID: Int)
    func widgetStartedMoving(widgetID: Int)
    func widgetIsMoving(widgetID: Int, newCenter: CGPoint, newSize: CGSize) // handles pans and resizing
    func widgetFinishedMoving(widgetID: Int)
}

enum BorderStyle: Int{
    case solid = 0, dotted = 2, dashed = 8
}

@objc class CircleWidget: UIView {
    // Public Properties
    var borderWidth: CGFloat = 2.0
    var borderStyle: BorderStyle = .solid
    var circleColor: UIColor = UIColor.mmBlue {
        didSet {
            setupGlowableProperties()
        }
    }
    var delegate: CircleWidgetDelegate? = nil
    var menuTitle: String = ""
    var menuDetails: String = ""
    var widgetID: Int = -1

    // Private properties
    private let animationKey = "CircleGlow"
    private let bezierLayer = CAShapeLayer()
    private let circleAnimation = CAAnimationGroup()
    private var calloutView: SMCalloutView?
    private var panningStartingPoint: CGPoint = .zero
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    convenience init(position: CirclePosition, widgetID: Int) {
        let frame = position.rect
        self.init(frame: frame)
        
        self.widgetID = widgetID
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup() {
        self.backgroundColor = UIColor.clear
        bezierLayer.bounds = layer.bounds
        bezierLayer.position = CGPoint(x: layer.bounds.midX, y: layer.bounds.midY)
        layer.addSublayer(bezierLayer)
        layer.backgroundColor = UIColor.clear.cgColor
        bezierLayer.fillColor = UIColor.clear.cgColor
        bezierLayer.strokeColor = circleColor.cgColor
        bezierLayer.lineWidth = borderWidth
        let circlePath = UIBezierPath(roundedRect: bounds, cornerRadius: bounds.width/2)
        bezierLayer.path = circlePath.cgPath
        
        setupGlowableProperties()

        addGestureRecognizer(UIPinchGestureRecognizer(target: self,
                                                      action: #selector(handleObjectPinch(recognizer:))))
        addGestureRecognizer(UIPanGestureRecognizer(target: self,
                                                    action: #selector(handleObjectPan(recognizer:))))
        
        let longPressGesture = UILongPressGestureRecognizer(target: self,
                                                            action: #selector(handleObjectLongPress))
        longPressGesture.minimumPressDuration = 0.4
        addGestureRecognizer(longPressGesture)

        isUserInteractionEnabled = true
    }
    
    func animateCircle() {
        bezierLayer.add(circleAnimation, forKey: animationKey)
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let parent = self.superview
        let relativePt = self.convert(point, to: parent)
        let centerPt = self.center
        let distanceFromCenter = centerPt.distance(to: relativePt)
        let radiusThreshold = max(48, (self.bounds.size.width / 2.0) + 30)
        if distanceFromCenter < radiusThreshold {
            return self
        }
        else {
            return nil
        }
    }
    
    @objc func menuButtonPressed() {
        delegate?.invokeActionsMenu(widgetID: self.widgetID)
    }
    
    func redrawCircle() {
        bezierLayer.bounds = layer.bounds
        let circlePath = UIBezierPath(roundedRect: bezierLayer.bounds, cornerRadius: bezierLayer.bounds.width/2)
        bezierLayer.path = circlePath.cgPath
        if self.borderStyle == .dashed {
            bezierLayer.lineDashPattern = [5,3]
        } else {
            bezierLayer.lineDashPattern = nil
        }

        bezierLayer.position = CGPoint(x: layer.bounds.midX, y: layer.bounds.midY)
        self.setNeedsDisplay()
    }
    
    // TODO: remove these 2 below
    func resizeCircleLayer(_ newsize: CGSize) {
        // NOTE: setting bounds automatically sets frame adjusting around adjustPoint which defaults
        // to the center (where we want it)
        self.bounds.size.width = newsize.width
        self.bounds.size.height = newsize.height
        redrawCircle()
    }
    
    func rescaleCircleLayer(_ scale: CGFloat) {
        var newFrame = self.frame
        newFrame.origin.x *= scale
        newFrame.origin.y *= scale
        newFrame.size.width *= scale
        newFrame.size.height *= scale
        self.frame = newFrame
        self.layer.cornerRadius = newFrame.size.width / 2

        redrawCircle()
    }
    
    private func setupGlowableProperties() {
        bezierLayer.strokeColor = circleColor.cgColor
        bezierLayer.lineWidth = borderWidth
        
        bezierLayer.shadowOpacity = 1
        bezierLayer.shadowRadius = 0
        bezierLayer.shadowOffset = CGSize.zero
        bezierLayer.shadowColor = UIColor.black.cgColor
        
        let shadowGlow = CABasicAnimation(keyPath: keyPath.shadowRadius)
        shadowGlow.duration = 1.0
        shadowGlow.fromValue = 0
        shadowGlow.toValue = 2.0
        shadowGlow.autoreverses = true
        
        let borderGlow = CABasicAnimation(keyPath: keyPath.lineWidth)
        borderGlow.duration = 1.0
        borderGlow.fromValue = borderWidth
        borderGlow.toValue = 2.5 * borderWidth
        borderGlow.autoreverses = true
        
        var red = CGFloat(0)
        var green = CGFloat(0)
        var blue = CGFloat(0)
        var alpha = CGFloat(0)
        circleColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        let multiple = CGFloat(1.75)
        red = min(red * multiple, 1.0)
        blue = min(blue * multiple, 1.0)
        green = min(green * multiple, 1.0)
        let glowColor = UIColor(red: red, green: green, blue: blue, alpha: alpha)
        
        let colorGlow = CABasicAnimation(keyPath: keyPath.strokeColor)
        colorGlow.duration = 1.0
        colorGlow.fromValue = circleColor.cgColor
        colorGlow.toValue = glowColor.cgColor
        colorGlow.autoreverses = true
        
        //let circleAnimation = CAAnimationGroup()
        circleAnimation.animations = [ shadowGlow, borderGlow, colorGlow]
        circleAnimation.duration = 2.0
        circleAnimation.repeatCount = .greatestFiniteMagnitude
    }
    
   func showWidgetMenu(_ doDisplay: Bool = true, animated: Bool = true) {
        if doDisplay == false {
            if calloutView != nil {
                calloutView!.dismissCallout(animated: animated)
                calloutView = nil
            }
            stopAnimatingCircle()
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
        calloutView!.title = menuTitle
        calloutView!.subtitle = menuDetails
        calloutView!.rightAccessoryView = menuButton
        calloutView!.presentCallout(from: self.frame, in: self.superview!, constrainedTo: self.superview!, animated: animated)
        animateCircle()
    }

    func stopAnimatingCircle() {
        bezierLayer.removeAnimation(forKey: animationKey)
    }
    
    func updateWidgetMenu(menuTitle: String, menuDetails: String = "") {
        // these two lines -- the CORRECT way to do this -- break code downstream!!
        self.menuTitle = menuTitle
        self.menuDetails = menuDetails
        // apparently, merely setting the title/subtitle properties on the menu
        // is not enough to cause the labels in the menu to be updated. Hence there
        // is a need to create a new callout. At least we can modify our original
        // showWidgetMenu to not animate this time.
        if calloutView != nil {
            calloutView!.title = menuTitle
            calloutView!.subtitle = menuDetails
            calloutView!.dismissCallout(animated: false)
            calloutView!.presentCallout(from: self.frame, in: self.superview!, constrainedTo: self.superview!, animated: true)
        }
    }
    
    func updateWidgetPlacement(newCenter: CGPoint, newSize: CGSize) {
        bounds.size = newSize
        frame.size = newSize
        self.center = newCenter
        redrawCircle()
    }

    // TODO: remove the above after replacing with this
    func updateWidgetPlacement(position: CirclePosition) {
        let newSize = CGSize(width: position.radius*2, height: position.radius*2)
        bounds.size = newSize
        frame.size = newSize
        self.center = position.center
        redrawCircle()
    }

    // MARK: Gesture Handlers
    
    @objc func handleObjectLongPress(recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == .began {
            delegate?.longPressed(widgetID: self.widgetID)
        }
    }
    
    @objc func handleObjectPan(recognizer: UIPanGestureRecognizer) {
        let translation = recognizer.translation(in: self.superview)
        let newCenter = CGPoint(x: panningStartingPoint.x + translation.x,
                                y: panningStartingPoint.y + translation.y)
        if recognizer.state == .began {
            panningStartingPoint = center
            delegate?.widgetStartedMoving(widgetID: widgetID)
        }
        else if recognizer.state == .changed {
            delegate?.widgetIsMoving(widgetID: widgetID, newCenter: newCenter, newSize: bounds.size)
        }
        else if recognizer.state == .ended {
            delegate?.widgetFinishedMoving(widgetID: widgetID)
        }
    }
    
    @objc func handleObjectPinch(recognizer: UIPinchGestureRecognizer) {
        var newFrame = self.frame
        
        newFrame.size.width *= recognizer.scale
        newFrame.size.height *= recognizer.scale
        recognizer.scale = 1.0

        if recognizer.state == .began {
            delegate?.widgetStartedMoving(widgetID: widgetID)
        }
        else if recognizer.state == .changed {
            delegate?.widgetIsMoving(widgetID: widgetID, newCenter: self.center, newSize: newFrame.size)
        }
        else if recognizer.state == .ended {
            delegate?.widgetFinishedMoving(widgetID: widgetID)
        }
    }
}

enum keyPath {
    static let backgroundColor = "backgroundColor"
    static let opacity = "opacity"
    static let position = "position"
    static let positionX = "position.x"
    static let positionY = "position.y"
    static let shadowOffset = "shadowOffset"
    static let shadowOpacity = "shadowOpacity"
    static let shadowColor = "shadowColor"
    static let shadowRadius = "shadowRadius"
    static let strokeColor = "strokeColor"
    static let cornerRadius = "cornerRadius"
    static let borderColor = "borderColor"
    static let borderWidth = "borderWidth"
    static let lineWidth = "lineWidth"
}

