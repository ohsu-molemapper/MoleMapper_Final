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

// Use the compiler to make sure we don't make mistakes in our strings!
enum SettingsActionIDs: String {
    // in current order they appear on Learn More scene
    case autoshowHelp
    case showHints
    case howtoEnableNotifications
    case reminderFrequency
}

class SettingsWorker {
    private static var model : [CellModelProtocol]?
     
    static func buildTableRows() -> [CellModelProtocol] {
        // Build table rows dynamically based on study membership
        
        // Get current frequency and construct sub-title message
        let frequencyGap = UserDefaults.reminderFrequencyInMonths
        var frequencySubtitle = "You are not being reminded"
        if frequencyGap > 0 {
            let frequency = ReminderFrequency(rawValue: frequencyGap)
            frequencySubtitle = "You are being reminded \(frequency?.text.lowercased() ?? "")"
        }
        
        // Get strings to represent enrollment status
        SettingsWorker.model = [
                 SwitchCellModel(cellTitle: "Auto-show Help",
                               cellSubtitle: "Automatically show help each time you use the app",
                               actionID: SettingsActionIDs.autoshowHelp.rawValue,
                               switchState: !UserDefaults.areHelpScreensDisabled),
                 SwitchCellModel(cellTitle: "Show Hints",
                               cellSubtitle: "Show hints on selected scenes",
                               actionID: SettingsActionIDs.showHints.rawValue,
                               switchState: UserDefaults.areHintsEnabled),
                 ShowCellModel(cellTitle: "Enable/Disable Notifications",
                               cellSubtitle: "Learn more about notifications",
                               actionID: SettingsActionIDs.howtoEnableNotifications.rawValue),
                 ShowCellModel(cellTitle: "Reminder Frequency",
                               cellSubtitle: frequencySubtitle,
                               actionID: SettingsActionIDs.reminderFrequency.rawValue)
                ]
        return SettingsWorker.model!
    }
}
