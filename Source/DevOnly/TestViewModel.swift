//
//  TestViewModel.swift
//  MoleMapper
//
//  Created by Alejandro Cárdenas on 3/14/18.
//  Copyright © 2018 OHSU. All rights reserved.
//

import UIKit
import UserNotifications

class TestViewModel {
    private var items = [TestItem]()
    private var notificationCounter = 0
    
    var itemsCount: Int {
        return items.count
    }
    
    var cellIdentifier: String {
        return "testCell"
    }
    
    init() {
        setupModel()
    }
    
//    func makeStoryNotification() {
//        print("Add Story Notification here")
//
//        guard NotificationsManager.current().isAlertable else { return }
//
//        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
//
//        // Read in a JSON
//        let jsonFile = Bundle.main.url(forResource: "story1", withExtension: "json")
//        do {
//            // Update the title
//            let newTitle = "Notification \(notificationCounter)"
//            notificationCounter += 1
//
//            // Get original JSON
//            let contents = try Data(contentsOf: jsonFile!)
//            let jsonDecoder = JSONDecoder()
//            jsonDecoder.dateDecodingStrategy = .iso8601
//            var newsItem = try jsonDecoder.decode(NewsItemService.self, from: contents)
//            // Update key fields
//            newsItem.aps.alert.title = newTitle
//            newsItem.storyid = UUID()
//
//            // Extract new JSON
//            let jsonEncoder = JSONEncoder()
//            jsonEncoder.dateEncodingStrategy = .iso8601
//            let newJSONData = try! jsonEncoder.encode(newsItem)
//
//            // Create local notification
//            let json_dict = try? JSONSerialization.jsonObject(with: newJSONData, options: []) as! [String: Any]
//            let notificationContent = UNMutableNotificationContent()
//            notificationContent.title = newsItem.aps.alert.title
//            notificationContent.body = newsItem.aps.alert.body
//            notificationContent.userInfo = (json_dict)!
//            notificationContent.categoryIdentifier = NotificationsManagerCategories.news.rawValue
//
//            // Test: don't "filter" by anything except seconds and add a minute to see if it captures that
//            //            let unitFlags2:Set<Calendar.Component> = [.second] // fails: (ignores minutes)
//            let unitFlags:Set<Calendar.Component> = [.year, .month, .day, .hour, .minute, .second]
//            let calendar = Calendar.current
//            var scheduledDate = calendar.date(byAdding: .second, value: 4, to: Date())!
////            scheduledDate = calendar.date(byAdding: .minute, value: 1, to: scheduledDate)!
//            let scheduledDateComponents = calendar.dateComponents(unitFlags, from: scheduledDate)
//
//            let trigger = UNCalendarNotificationTrigger(dateMatching: scheduledDateComponents, repeats: false)
//
//            let id = newsItem.storyid.uuidString
//            let request = UNNotificationRequest(identifier: id, content: notificationContent, trigger: trigger)
//            UNUserNotificationCenter.current().add(request){
//                (error) in
//                print("created (apparently) a notification")
//                if error != nil {
//                    print("error adding notification: \(error?.localizedDescription)")
//                }
//            }
//
//        }
//        catch let error as NSError {
//            print("Got problems in River City: \(error)")
//        }
//    }
    
    func setupModel() {
        // Add view controllers as needed.
        let item1 = TestItem(rowTitle: "Crash app") {
            print("Invoke crash to trigger Firebase/Crashlytics")
            fatalError("Crashlytics test")
        }
        let item3 = TestItem(rowTitle: "Trigger reminders") {
            NotificationsManager.scheduleFutureReminders()
        }
        let item4 = TestItem(rowTitle: "Set mole dates back 30 days") {
            let moles = Mole30.allMoles()
            for mole in moles {
                mole.setMeasurementDatesBackOneMonthForMole()
            }
        }
        let item5 = TestItem(rowTitle: "Set zone dates back 30 days") {
            let zoneIDs = Zone30.allZoneIDs()
            for zoneID in zoneIDs {
                if let zone = Zone30.zoneForZoneID(zoneID as! String) {
                    zone.setMeasurementDatesBackOneMonthForZone()
                }
            }
        }
//        let item6 = TestItem(rowTitle: "Moles needing diagnosis?") {
//            let oldDate = Calendar.current.date(byAdding: .month, value: -1, to: Date())
//            let count = Mole30.numberOfMolesNeedingDiagnosisOlderThan(date: oldDate!)
//            (UIApplication.shared.delegate as! AppDelegate).refreshBadgeForDashboard()
//            print("Moles needing diagonsis still = \(count)")
//        }
        let item7 = TestItem(rowTitle: "More recent zone measurement?") {
            let olddate = Calendar.current.date(byAdding: .month, value: -1, to: Date())
            let result = ZoneMeasurement30.moreRecentZoneMeasurementThan(date: olddate!)
            print("Zone more recent than \(String(describing: olddate)) = \(result)")
        }
        let item8 = TestItem(rowTitle: "Internet available?") {
            let reachable = Reachability.isConnectedToNetwork()
            print("Internet connectivity = \(reachable)")
        }
        let item9 = TestItem(rowTitle: "Print scheduled notifications") {
            let center = UNUserNotificationCenter.current()
            center.getPendingNotificationRequests(completionHandler: { requests in
                for request in requests {
                    print(request)
                }
            })
        }
        let item10 = TestItem(rowTitle: "Dump mole database") {
            let stack = V30StackFactory.createV30Stack()
            stack.dumpModel()
        }
        let item12 = TestItem(rowTitle: "Schedule 5-sec notification") {
            let date = Calendar.current.date(byAdding: .second, value: 5, to: Date())!
            NotificationsManager.scheduleReminderNotification(on: date)
        }
        let item13 = TestItem(rowTitle: "Schedule past notification") {
            let date = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
            NotificationsManager.scheduleReminderNotification(on: date)
        }

        
        items = [item1, item3, item4, item5, item7, item8, item9, item10, item12, item13]
    }
    
    func item(at index: Int) -> TestItem {
        return items[index]
    }
    
    
}
