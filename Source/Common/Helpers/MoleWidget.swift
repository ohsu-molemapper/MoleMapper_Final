//
//  MoleWidget.swift
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

class MoleWidget : CircleWidget {
    
    private var moleState: CircleState = .unselected
    var state: CircleState {
        get {
            return moleState
        }
        set (newState) {
            moleState = newState
            self.redrawCircle()
        }
    }
    
    private var moleStatus: MoleStatus = .new
    var status: MoleStatus {
        get {
            return moleStatus
        }
        set (newStatus) {
            switch newStatus {
            case .new:
                borderStyle = .solid
                borderWidth = 2.0
                alpha = 1.0
                break
            case .removedWaiting:
                circleColor = UIColor.mmRed
                borderStyle = .solid
                borderWidth = 8.0
                alpha = 1.0
                break
            case .removedRecorded:
                circleColor = UIColor.black
                borderStyle = .solid
                borderWidth = 4.0
                alpha = 1.0
                break
            case .existingConfident:
                borderStyle = .solid
                borderWidth = 2.0
                alpha = 1.0
                break
            case .existingNotConfident:
                circleColor = UIColor.mmRed
                borderStyle = .dashed
                borderWidth = 2.0
                alpha = 1.0
                break
            default:
                fatalError(#function + "setting mole status to unknown")
            }
            moleStatus = newStatus
        }
    }
    // Well this is fine:
    // willSet and didSet observers are not called when a property is first initialized. They are only called when the property’s value is set outside of an initialization context.
    var moleName:String = "" {
        didSet {
            menuTitle = moleName
        }
    }
    var moleSize:String? = nil {
        didSet {
            if moleSize != nil {
                menuDetails = moleSize!
            }
        }
    }
    
    convenience init(center:CGPoint, radius: CGFloat,
                     state: CircleState = .unselected,
                     status: MoleStatus = .new,
                     moleName: String = "",
                     delegate: CircleWidgetDelegate,
                     moleSize: String? = nil) {
        let frame = CGRect(x: center.x - radius, y: center.y - radius, width: 2*radius, height: 2*radius)
        self.init(frame: frame)
        
        self.backgroundColor = UIColor.clear
        self.circleColor = UIColor.mmBlue
        self.status = status
        self.state = state
        self.menuTitle = moleName       // See comment above didSet about init contexts for setter observers
        self.menuDetails = moleSize ?? ""
        self.moleName = moleName
        self.moleSize = moleSize ?? ""
        self.delegate = delegate
        
        rescaleCircleLayer(1.0)
    }
    
    func updateMoleLabels(moleName: String, moleSize: String) {
        self.moleName = moleName
        self.moleSize = moleSize
        updateWidgetMenu(menuTitle: moleName, menuDetails: moleSize)
    }
    
}
