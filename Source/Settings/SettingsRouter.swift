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

protocol SettingsRoutingLogic {
    func routeToEnableNotifications()
    func routeToReminderFrequency()
}

class SettingsRouter: NSObject, SettingsRoutingLogic {
    weak var viewController: SettingsViewController?

    func navigateTo(destination: UIViewController, source: UIViewController?) {
        guard let navigationController = source?.navigationController else {
            print("No navigation controller to push a new view controller \(String(describing: destination))")
            guard let sourceViewController = source else {
                print("no viewController set in router")
                return
            }
            destination.modalPresentationStyle = .fullScreen
            sourceViewController.present(destination, animated: true, completion: nil)
            return
        }
        destination.modalPresentationStyle = .fullScreen
        navigationController.pushViewController(destination, animated: true)
    }
    
    // MARK: - SettingsRoutingLogic implementation
    
    func routeToEnableNotifications() {
        if UserDefaults.userHasSeenNotificationRequest {
            // User has seen the screen telling them about how we want to use notifications
            if !UserDefaults.userPreapprovedNotificationRequest {
                // User said "no" (but hasn't rejected the system yet)
                UserDefaults.userHasSeenNotificationRequest = false
                NotificationsManager.requestNotificationsAuthorization(presentingViewController: viewController!,
                                                                       acceptCompletion: nil,
                                                                       rejectCompletion: nil)
            }
            else {
                let sb = UIStoryboard(name: "WebViewer", bundle: nil)
                let vc = sb.instantiateViewController(withIdentifier: "WebViewController") as! WebViewController
                vc.setup(destination: "enableNotifications", contentType: .local)
                navigateTo(destination: vc, source: viewController)
            }
        }
        else {
            NotificationsManager.requestNotificationsAuthorization(presentingViewController: viewController!,
                                                                   acceptCompletion: nil,
                                                                   rejectCompletion: nil)
        }
    }
    

    func routeToReminderFrequency() {
        
        if UserDefaults.userHasSeenNotificationRequest {
            // User has seen the screen telling them about how we want to use notifications
            if !UserDefaults.userPreapprovedNotificationRequest {
                // User said "no" (but hasn't rejected the system yet)
                UserDefaults.userHasSeenNotificationRequest = false
                NotificationsManager.requestNotificationsAuthorization(presentingViewController: viewController!, acceptCompletion: nil, rejectCompletion: nil)
            }
            else {
                if NotificationsManager.current().isAlertable {
                    let sb = UIStoryboard(name: "ReminderFrequency", bundle: nil)
                    let vc = sb.instantiateViewController(withIdentifier: "ReminderFrequencyViewController") as! ReminderFrequencyViewController
                    let currentFrequency = ReminderFrequency(rawValue: UserDefaults.reminderFrequencyInMonths)
                    vc.setup(currentFrequency: currentFrequency ?? .monthly, delegate: viewController!)
                    vc.modalPresentationStyle = .fullScreen
                    viewController?.present(vc, animated: true, completion: nil)
                }
                else {
                    // Alert telling them to enable notifications
                    let title = "Enable notifications"
                    let message = "You must first enable notifications to set the reminder frequency."
                    
                    let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
                    let actions = [ok]
                    let alertController = viewController!.alert(with: actions, title: title, message: message, alertController: .actionSheet)
                    viewController!.present(alertController, animated: true, completion: nil)
                }
            }
        }
        else {
            NotificationsManager.requestNotificationsAuthorization(presentingViewController: viewController!, acceptCompletion: nil, rejectCompletion: nil)
        }

        
    }
    
}

