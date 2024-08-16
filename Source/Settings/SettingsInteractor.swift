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
import UserNotifications

protocol SettingsBusinessLogic {
    func initModel(request: Settings.InitModel.Request)
    func updateReminderFrequency(request: Settings.UpdateReminderFrequency.Request)
    func updateParticipation(request: Settings.UpdateParticipation.Request)
}

class SettingsInteractor: NSObject, SettingsBusinessLogic {
    
    var tableRows : [CellModelProtocol]!
    var cellDelegate: CellDelegate!
    
    func initModel(request: Settings.InitModel.Request) {
        tableRows = SettingsWorker.buildTableRows()
        request.tableView.dataSource = self
        cellDelegate = request.cellDelegate
    }
    
    func updateParticipation(request: Settings.UpdateParticipation.Request) {
        tableRows = SettingsWorker.buildTableRows()
        request.tableView.reloadData()
    }

    func updateReminderFrequency(request: Settings.UpdateReminderFrequency.Request) {
        UserDefaults.reminderFrequencyInMonths = request.frequency.rawValue
        if request.frequency == .none {
            UserDefaults.userDisabledMoleNotifications = true
        } else {
            UserDefaults.userDisabledMoleNotifications = false
        }
        NotificationsManager.scheduleFutureReminders(force: true)  // reset based on new frequency (this restarts the clock, it doesn't adjust existing dates)
        NotificationsManager.updateBadgeNumber()
        (UIApplication.shared.delegate! as! AppDelegate).refreshBadgeForDashboard()
        tableRows = SettingsWorker.buildTableRows()
        request.tableView.reloadData()
    }
}

extension SettingsInteractor : UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableRows.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellModel = tableRows[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: cellModel.cellType.rawValue)
        
        if let modelCell = cell as? TableViewCellProtocol {
            modelCell.setup(cellModel: cellModel, cellDelegate: cellDelegate)
        }
        
        return cell!
    }
    
}


