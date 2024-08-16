//
//  NotificationsManager.swift
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

import UserNotifications
import EventKit

protocol NotificationPermissions: class {
    func userPreapproved(answer: Bool)
    func preapprovalFinished()
}

enum NotificationsManagerCategories : String {
    case moleReminder = "molemapper.reminder.mole"
    case annualReminder = "molemapper.reminder.annualvisit"
}

enum NotificationsManagerActions : String {
    case snooze = "action.snooze"
    case dismiss = "action.dismiss"
    case schedule = "action.schedule"
}

@objc class NotificationsManager: NSObject {
    private static var singleton: NotificationsManager?
    private(set) var isAlertable: Bool = false
    private(set) var isBadgeable: Bool = false
    private(set) var canAddToCalendar: Bool = false
    private static var futureRemindersHaveBeenSet: Bool = false
      
    // Save for use in preapprovalFinished call
    private var acceptCompletion: (()->Void)?
    private var rejectCompletion: (()->Void)?

    // MARK: - Methods
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        
        initNotificationPermissions()
    }
    
    func initNotificationPermissions() {
        if UserDefaults.userPreapprovedNotificationRequest {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) {[unowned self] (accepted, error) in
                if accepted {
                    UNUserNotificationCenter.current().getNotificationSettings(completionHandler: { [unowned self] (settings) in
                        if settings.alertSetting == .enabled {
                            self.isAlertable = true
                            // Handle the special case of user not actively disabling mole notifications and
                            // frequency == 0 (the default). In this case, set frequency to 1 and create reminders.
                            if !UserDefaults.userDisabledMoleNotifications && UserDefaults.reminderFrequencyInMonths == 0 {
                                UserDefaults.reminderFrequencyInMonths = 1
                                DispatchQueue.main.async {
                                    NotificationsManager.scheduleFutureReminders()
                                }
                            }
                        }
                        if settings.badgeSetting == .enabled {
                            self.isBadgeable = true
                        }
                        if self.acceptCompletion != nil {
                            self.acceptCompletion!()
                            self.acceptCompletion = nil
                        }
                    })
                }
                else {
                    if self.rejectCompletion != nil {
                        self.rejectCompletion!()
                        self.rejectCompletion = nil
                    }
                }
                let eventStore = EKEventStore()
                eventStore.requestAccess(to: .event) { [weak self] (accessGranted, error) in
                    if accessGranted {
                        self?.canAddToCalendar = true
                    }
                    self?.setCategories()
                }
            }
        }
        else {
            if rejectCompletion != nil {
                rejectCompletion!()
                rejectCompletion = nil
            }
        }

    }
    
    class func current()->NotificationsManager {
        if NotificationsManager.singleton == nil {
            NotificationsManager.singleton = NotificationsManager()
        }
        return NotificationsManager.singleton!
    }
    
    class func requestNotificationsAuthorization(presentingViewController: UIViewController, acceptCompletion: (()->Void)?, rejectCompletion: (()->Void)?) {
        guard let notificationManager = NotificationsManager.singleton else { return }
        notificationManager.acceptCompletion = acceptCompletion
        notificationManager.rejectCompletion = rejectCompletion
        if !UserDefaults.userHasSeenNotificationRequest {
            // Show screen modally
            let sb = UIStoryboard(name: "Notifications", bundle: nil)
            let vc = sb.instantiateViewController(withIdentifier: "NotificationRequest") as! NotificationRequestViewController
            
            vc.delegate = NotificationsManager.singleton
        
            vc.modalPresentationStyle = .overFullScreen
            vc.modalTransitionStyle = .crossDissolve
            presentingViewController.present(vc, animated: true) {
                UserDefaults.userHasSeenNotificationRequest = true
            }
        }
        else {
            NotificationsManager.singleton!.initNotificationPermissions()
        }
    }
    
    class func scheduleFutureReminders(force: Bool = false){
        if futureRemindersHaveBeenSet && !force {
            return
        }
        
        // Clean notifications queue...wait, no: only clear mole reminder notifications!!
        // UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { (requests) in
            // Remove any existing mole measurement reminders (and only mole measurement reminders)
            var identifiers = [String]()
            for request in requests {
                if request.content.categoryIdentifier == NotificationsManagerCategories.moleReminder.rawValue {
                    identifiers.append(request.identifier)
                }
            }
            if identifiers.count > 0 {
                center.removePendingNotificationRequests(withIdentifiers: identifiers)
            }
            // but don't reschedule if the user has said not to
            if UserDefaults.reminderFrequencyInMonths == 0 {
                return
            }
            
            // Create new mole reminder notifications
            for interval in 1 ... 3 {
                let monthsInterval = UserDefaults.reminderFrequencyInMonths
                
                let date = Calendar.current.date(byAdding: .month, value: interval * monthsInterval, to: Date())!
                scheduleReminderNotification(on: date)
            }
        }
        futureRemindersHaveBeenSet = true
    }
    
    class func scheduleReminderNotification(on date: Date){
        let unitFlags:Set<Calendar.Component> = [.year, .month, .day, .minute, .hour, .second]
        let scheduledDateComponents = Calendar.current.dateComponents(unitFlags, from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: scheduledDateComponents, repeats: false)
        
        let content = UNMutableNotificationContent()
        content.title = "Time to remeasure your moles"
        content.body = "We recommend measuring your moles monthly."
        content.categoryIdentifier = NotificationsManagerCategories.moleReminder.rawValue
        let id = UUID().uuidString
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) {(error) in
            if let error = error {
                print("Uh oh! We had an error: \(error)")
            }
        }
    }
 
    class func scheduleReminderToCalendar() {
        let store = EKEventStore()
        let status = EKEventStore.authorizationStatus(for: .event)
        if status == .authorized {
            let unitFlags:Set<Calendar.Component> = [.year, .month, .day, .minute, .hour, .second]
            // TODO: future release, let user choose default day/time of week to schedule
            // or better yet, invoke calendar directly if possible
            var startDateComponents = Calendar.current.dateComponents(unitFlags, from: Date())
            startDateComponents.calendar = Calendar.current     // You'd think this would be set from the above, wouldn't you?
            startDateComponents.hour = 15
            startDateComponents.minute = 0
            // Make sure this is later than now (by adding a day if necessary)
            if startDateComponents.date! < Date() {
                let date = Calendar.current.date(byAdding: .day, value: 1, to: startDateComponents.date!)!
                startDateComponents = Calendar.current.dateComponents(unitFlags, from: date)
                startDateComponents.calendar = Calendar.current
            }
            var endDateComponents = startDateComponents
            endDateComponents.minute = 15

            let newEvent = EKEvent(eventStore: store)
            newEvent.title = "Measure your moles"
            newEvent.calendar = store.defaultCalendarForNewEvents
            newEvent.startDate = startDateComponents.date       // These won't work if the calendar isn't set
            newEvent.endDate = endDateComponents.date
            do {
                try store.save(newEvent, span: EKSpan.thisEvent, commit: true)
            } catch {
                print("error saving event")
                print("\(error)")
            }
        } else {
            print("Not authorized to add event")
            switch status {
            case EKAuthorizationStatus.denied:
                print("denied")
            case EKAuthorizationStatus.notDetermined:
                print("not determined")
            case EKAuthorizationStatus.restricted:
                print("restricted")
            default:
                print("other")
            }
        }
    }
    
    func setCategories() {
        var moleReminderCategory: UNNotificationCategory!
        // Not a class function; need one of these objects around to make these work.
        let dismissAction = UNNotificationAction(identifier: NotificationsManagerActions.dismiss.rawValue,
                                                 title: "Dismiss", options: [])
        let snoozeAction = UNNotificationAction(identifier: NotificationsManagerActions.snooze.rawValue,
                                                title: "Snooze", options: [])
        if self.canAddToCalendar {
            let scheduleAction = UNNotificationAction(identifier: NotificationsManagerActions.schedule.rawValue,
                                                      title: "Add to Calendar", options: [])
            moleReminderCategory = UNNotificationCategory(identifier: NotificationsManagerCategories.moleReminder.rawValue,
                                                          actions: [snoozeAction, scheduleAction, dismissAction],
                                                          intentIdentifiers: [], options: [])
        } else {
            moleReminderCategory = UNNotificationCategory(identifier: NotificationsManagerCategories.moleReminder.rawValue,
                                                          actions: [snoozeAction, dismissAction],
                                                          intentIdentifiers: [], options: [])
        }
        UNUserNotificationCenter.current().setNotificationCategories([moleReminderCategory])
    }

    
    @objc class func updateBadgeNumber(){
        if NotificationsManager.current().isBadgeable {
            let badgeNumber = Zone30.numberOfZonesNeedingRemeasurement(UserDefaults.reminderFrequencyInMonths)
            DispatchQueue.main.async {
                UIApplication.shared.applicationIconBadgeNumber = Int(badgeNumber)
            }
        }
    }
}

// MARK: - UNUserNotiicationCenterDelegate
extension NotificationsManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let categoryIdentifer = response.notification.request.content.categoryIdentifier
        if categoryIdentifer == NotificationsManagerCategories.moleReminder.rawValue {
            let action = response.actionIdentifier
            let request = response.notification.request
            if action == NotificationsManagerActions.dismiss.rawValue {
                center.removePendingNotificationRequests(withIdentifiers: [request.identifier])
            }
            if action == NotificationsManagerActions.snooze.rawValue {
                let date = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
                let unitFlags:Set<Calendar.Component> = [.year, .month, .day, .minute, .hour, .second]
                let scheduledDateComponents = Calendar.current.dateComponents(unitFlags, from: date)
                let trigger = UNCalendarNotificationTrigger(dateMatching: scheduledDateComponents, repeats: false)

                let newRequest = UNNotificationRequest(identifier: request.identifier, content: request.content, trigger: trigger)
                UNUserNotificationCenter.current().add(newRequest, withCompletionHandler: { (error) in
                    if error != nil {
                        print("\(error?.localizedDescription ?? "nil error")")
                    }
                })
            }
            if action == NotificationsManagerActions.schedule.rawValue {
                NotificationsManager.scheduleReminderToCalendar()
                center.removePendingNotificationRequests(withIdentifiers: [request.identifier])
            }
        }
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        completionHandler(.alert)
    }
}

// MARK: - NotificationPermissions
extension NotificationsManager: NotificationPermissions {
    func preapprovalFinished() {
        initNotificationPermissions()
    }
    
    func userPreapproved(answer: Bool) {
        UserDefaults.userPreapprovedNotificationRequest = answer
    }
}
