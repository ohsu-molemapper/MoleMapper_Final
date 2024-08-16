//
//  AppDelegate.swift
//  MoleMapper
//
// Copyright (c) 2018 OHSU. All rights reserved.
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
import CoreData

//@UIApplicationMain
@objcMembers
class AppDelegate: UIResponder, UIApplicationDelegate {
    static let numberOfDaysInFollowupPeriod = 30
    
    var window: UIWindow?
    
    var webNavController: UINavigationController?

    var tabBarController: UITabBarController?
    lazy var managedObjectContext : NSManagedObjectContext = {
        return V30StackFactory.createV30Stack().managedContext
    }()

    var notificationsManager = NotificationsManager.current() // need strong link to an object so it can receive notification messages (it registers itself)
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        #if TOUCHPOSE
        print("Running with touchpose")
        #endif
        
        Zone30.createAllZones()
        UserDefaults.setupStdUserDefaults()
        overridePageControlColors()
        showCorrectOnboardingScreenOrBodyMap()
        
        NotificationsManager.updateBadgeNumber()
        
        return true
    }
    
    func showCorrectOnboardingScreenOrBodyMap() {
        if UserDefaults.shouldShowWelcomeScreenWithCarousel {
            showWelcomeScreenWithCarousel()
        }
        else {
            showBodyMap()
            let openedCount = UserDefaults.numberOfTimesAppOpened
            UserDefaults.numberOfTimesAppOpened = openedCount + 1
            if (UserDefaults.numberOfTimesAppOpened == 1) {
                UserDefaults.showNotificationsCoach = true
            }
        }
    }
    
    func showWelcomeScreenWithCarousel() {
        let welcomeVC = UIStoryboard(name: "NewWelcome", bundle: nil).instantiateInitialViewController()
        self.window!.rootViewController = welcomeVC
        self.window!.makeKeyAndVisible()

        // Decided not to use a transition (which, consequently, makes the app feel snappier)
        // The animation process introduces a bug with the hidding of the left button on the
        // welcome screen.
    }
    
    func routeToWarOnMelanoma() {
        // Switch to body map but immediately jump to WoM web page
        // no transitions; just see if the basic architecture works
        let sb = UIStoryboard(name: "WebViewer", bundle: nil)
        guard let womVC = sb.instantiateViewController(withIdentifier: "WebViewController") as? WebViewController else { return }
        womVC.setup(destination: "http://www.ohsu.edu/xd/health/services/dermatology/war-on-melanoma/melanoma-community-registry.cfm", contentType: .external, showDoneButton: true)
        self.webNavController = UINavigationController.init(rootViewController: womVC)
        self.window!.rootViewController = self.webNavController
    }
    
    func showBodyMap() {
        let tabBar = self.activeTabBarController()
        self.window?.backgroundColor = .white
        UIView.transition(with: self.window!, duration: 0.6, options: [.transitionCrossDissolve], animations: {
            UIView.setAnimationsEnabled(false)
            self.window!.rootViewController = tabBar
            self.window!.makeKeyAndVisible()
            UIView.setAnimationsEnabled(true)
        }, completion: nil)

        refreshBadgeForDashboard()
    }
    
    func setUpRootViewController(for viewController: UIViewController) {
        let navController = UINavigationController(rootViewController: viewController)
        navController.navigationBar.isTranslucent = false

        self.window?.backgroundColor = .white
        UIView.transition(with: self.window!, duration: 0.6, options: [.transitionCrossDissolve], animations: {
            UIView.setAnimationsEnabled(false)
            self.window!.rootViewController = navController
            self.window!.makeKeyAndVisible()
            UIView.setAnimationsEnabled(true)
        }, completion: nil)
    }
    
    func setOnboardingBooleansBackToInitialValues() {
        UserDefaults.shouldShowWelcomeScreenWithCarousel = true
    }
    
    func overridePageControlColors() {
        let pageControl = UIPageControl.appearance()
        pageControl.pageIndicatorTintColor = UIColor.lightGray
        pageControl.currentPageIndicatorTintColor = UIColor.mmBlue
        pageControl.backgroundColor = UIColor.clear
    }
    
    func MonthNameString(_ monthNumber: Int) -> String {
        let formatter = DateFormatter()
        return formatter.standaloneMonthSymbols[monthNumber - 1]
    }
    
    func activeTabBarController() -> UITabBarController {
        if self.tabBarController == nil {
            self.tabBarController = UIStoryboard(name: "MainStoryboard", bundle: nil)
                .instantiateViewController(withIdentifier: "tabBar") as? UITabBarController
        }
        return self.tabBarController!  // Force app crash if this is that broken
    }
    
    func refreshBadgeForDashboard() {
        let dashboardItem: UITabBarItem = self.activeTabBarController().viewControllers![1].tabBarItem as UITabBarItem
        
        let remainingMoles = Mole30.numberOfMolesNeedingRemeasurement()
        dashboardItem.badgeValue = remainingMoles > 0 ? "\(remainingMoles)" : nil
    }
    
    func setAllMoleMeasurementsBackOneMonth() {
        let allMoles = Mole30.allMoles()
        for mole in allMoles {
            mole.setMeasurementDatesBackOneMonthForMole()
        }
    }
    
    func applicationDocumentsDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
}

