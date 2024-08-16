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

import Foundation
import UIKit

enum ToastPosition {
    case top
    case middle
    case bottom
}

protocol ToastNotifications: class {
    func passingTouch(point: CGPoint)
}

extension UIViewController {

    func showToast(_ message: String, delegate: ToastNotifications? = nil, duration : TimeInterval = 2.5, position: ToastPosition = .bottom, background: UIColor = UIColor.white, textColor : UIColor = UIColor.mmBlue, dismissable: Bool = true) {

        if (UserDefaults.areHintsEnabled) {
            let toastContainer = ToastContainer(frame: view.bounds, dismissable: dismissable, delegate: delegate)
            view.addSubview(toastContainer)

            let toastLabel = UILabel(frame: CGRect.zero)
            toastLabel.translatesAutoresizingMaskIntoConstraints = false

            toastLabel.text = message
            
            toastLabel.numberOfLines = 0        // to enable multiple lines
            toastLabel.lineBreakMode = .byWordWrapping  // to -use- multiple lines!
            // TODO: add code (subclassing or UILabel extension) to pad the text
            toastLabel.sizeToFit()

            // Style attributes
            toastLabel.backgroundColor = background
            toastLabel.textColor = textColor
            toastLabel.textAlignment = NSTextAlignment.center;
            toastLabel.alpha = 0.0
            toastLabel.layer.cornerRadius = 10;
            toastLabel.clipsToBounds  =  true
            toastLabel.layer.borderColor = textColor.cgColor
            toastLabel.layer.borderWidth = 1.0

            // Placement attributes (by constraint)
            toastContainer.addSubview(toastLabel)
            let containerMargins = toastContainer.layoutMarginsGuide
            toastLabel.leadingAnchor.constraint(equalTo: containerMargins.leadingAnchor, constant: 50).isActive = true
            toastLabel.trailingAnchor.constraint(equalTo: containerMargins.trailingAnchor, constant: -50).isActive = true
            toastLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 48).isActive = true
            if position == .top {
                toastLabel.topAnchor.constraint(equalTo: containerMargins.topAnchor, constant: 200).isActive = true
            }
            else if position == .middle {
                toastLabel.centerYAnchor.constraint(equalTo: containerMargins.centerYAnchor, constant: 0.0).isActive = true
            }
            else {
                toastLabel.bottomAnchor.constraint(equalTo: containerMargins.bottomAnchor, constant: -220).isActive = true
            }
            UIView.animate(withDuration: 1.3, animations: {
                toastLabel.alpha = 1.0
            }) { (complete) in
                UIView.animate(withDuration: 1.6, delay: 3.5, options: .curveEaseOut, animations: {
                    toastLabel.alpha = 0.0
                }) { (complete) in
                    toastContainer.removeFromSuperview()
                }
            }
        }
    }
    
    class ToastContainer : UIView {
        
        fileprivate var dismissable: Bool = false
        fileprivate weak var delegate: ToastNotifications?
        
        override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
            removeToast()
            self.delegate?.passingTouch(point: point)
            return false
        }
        
        convenience init (frame: CGRect, dismissable: Bool, delegate: ToastNotifications? = nil) {
            self.init(frame: frame)
            self.dismissable = dismissable
            self.delegate = delegate
        }
        
        fileprivate func removeToast() {
            if dismissable {
                self.layer.removeAllAnimations()
                UIView.animate(withDuration: 0.3, animations: {
                    self.alpha = 0.0
                }) { (completed) in
                    self.removeFromSuperview()
                }
                self.dismissable = false
            }
        }
    }
}
