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

import UIKit

// Start of migration from UXConstants to where they belong...
extension UIColor {
    static var ccTranslucentGray: UIColor {
        get {
            return UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 0.4)
        }
    }
    static var mmBlue: UIColor {
        get {
            return UIColor(red: 0, green: (122.0/255.0), blue: 1.0, alpha: 1.0)
        }
    }
    static var mmLightBlue: UIColor {
        get {
            return UIColor(red: (25.0/255.0), green: (201.0/255.0), blue: 1.0, alpha: 1.0)
        }
    }
    static var mmRed: UIColor {
        get {
            return UIColor(red: 1.0, green: (25.0/255.0), blue: (25.0/255.0), alpha: 1.0)
        }
    }
    static var mmDarkRed: UIColor {
        get {
            return UIColor(red: (201.0/255.0), green: (22.0/255.0), blue: (22.0/255.0), alpha: 1.0)
        }
    }
    static var mmBackgroundGray: UIColor {
        get {
            return UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 0.4)
        }
    }
    static var mmLightGray: UIColor {
        get {
            return UIColor(red: 0.4, green: 0.94, blue: 0.95, alpha: 1.0)
        }
    }
    static var mmYellow: UIColor {
        get {
            return UIColor(red: 1.0, green: 1.0, blue: 0.5, alpha: 1.0)
        }
    }
}
