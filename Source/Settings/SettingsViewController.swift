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

class SettingsViewController: UIViewController {
    var interactor: SettingsBusinessLogic?
    var router: (NSObjectProtocol & SettingsRoutingLogic)?
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var versionLabel: UILabel!
    
    override func loadView() {
        super.loadView()
        let showNib = UINib(nibName: "ShowTableViewCell", bundle: nil)
        tableView.register(showNib, forCellReuseIdentifier: CellType.showCell.rawValue)
        let switchNib = UINib(nibName: "SwitchTableViewCell", bundle: nil)
        tableView.register(switchNib, forCellReuseIdentifier: CellType.switchCell.rawValue)
        // Get rid of extra lines
        tableView.tableFooterView = UIView(frame: CGRect.zero)

    }
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()

        tableView.separatorInset = UIEdgeInsets.zero
        tableView.separatorColor = UIColor.mmBlue

        var versionText = "Version \(Bundle.main.releaseVersionNumberPretty)"
        #if DEBUG
        versionText += " (\(Bundle.main.buildVersionNumberPretty))"
        #endif
        
        versionLabel.text = versionText
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let request = Settings.InitModel.Request(tableView: tableView, cellDelegate: self)
        interactor?.initModel(request: request)
        tableView.reloadData()
    }
    
    private func setup() {
        let viewController = self
        let interactor = SettingsInteractor()
        let router = SettingsRouter()
        viewController.interactor = interactor
        viewController.router = router
        router.viewController = viewController
        // tableview data source set in interactor on initModel call
    }
    
    func leaveStudyCompleted() {
        interactor?.updateParticipation(request: Settings.UpdateParticipation.Request(tableView: tableView))
    }
}

class SpinnerViewController: UIViewController {
    var spinner = UIActivityIndicatorView(style: .whiteLarge)
    
    override func loadView() {
        view = UIView()
        view.backgroundColor = UIColor(white: 0, alpha: 0.7)
        
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.startAnimating()
        view.addSubview(spinner)
        
        spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
    }
}

extension SettingsViewController: CellDelegate {
    func showScene(actionID: String) {
        guard let action = SettingsActionIDs(rawValue: actionID) else { return }
        switch action {
        case .howtoEnableNotifications:
            router?.routeToEnableNotifications()
        case .reminderFrequency:
            router?.routeToReminderFrequency()
        case .autoshowHelp:
            // TODO: flip boolean switch
            break
        case .showHints:
            // TODO: flip boolean switch
            break
        }
    }
    
    func updateBoolean(actionID: String, flag: Bool) {
        guard let action = SettingsActionIDs(rawValue: actionID) else { return }
        switch action {
        case .autoshowHelp:
            if flag {
                UserDefaults.areHelpScreensDisabled = false
            } else {
                UserDefaults.areHelpScreensDisabled = true
            }
        case .showHints:
            if flag {
                UserDefaults.areHintsEnabled = true
            } else {
                UserDefaults.areHintsEnabled = false
            }
        default:
            print("Illegal action in SettingsViewController:showScene")
        }
    }
}

extension SettingsViewController: ReminderFrequencyDelegate {
    func frequencySelected(newFrequency: ReminderFrequency) {
        let request = Settings.UpdateReminderFrequency.Request(tableView: self.tableView, frequency: newFrequency)
        interactor?.updateReminderFrequency(request: request)
    }
}
