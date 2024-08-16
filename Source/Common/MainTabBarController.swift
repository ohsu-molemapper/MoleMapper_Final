//
//  MainTabBarController.swift
//  MoleMapper
//
// Copyright (c) 2022, OHSU. All rights reserved.
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

class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        configureDashboard()
        configureLearnMore()
        #if DEBUG
            // If in DEBUG mode (only set in MoleMapper Dev target build settings), it adds
            // a new tab bar item with a list testable view controllers.
            let testTableViewController = TestTableViewController(style: .plain)
            testTableViewController.viewModel = TestViewModel()
            let navController = UINavigationController(rootViewController: testTableViewController)
            navController.title = "Dev Only"
            navController.tabBarItem.image = #imageLiteral(resourceName: "info")
            viewControllers?.append(navController)
        #endif
    }
    
    private func configureLearnMore() {
        // Already embedded in a NavigationController
        let navController = UIStoryboard(name: "LearnMore", bundle: nil).instantiateInitialViewController()!
        navController.tabBarItem.image = UIImage.init(imageLiteralResourceName: "learnMoreUnselected")
        navController.tabBarItem.selectedImage = UIImage.init(imageLiteralResourceName: "learnMoreSelected")
        navController.tabBarItem.title = NSLocalizedString("Learn More", comment: "")
        viewControllers?.append(navController)
    }
    
    private func configureDashboard() {
        // Insertion of new profile view controller until we get rid of storyboards completely.
        let profileViewController:DashboardViewController = UIStoryboard(name: "Dashboard", bundle: nil)
            .instantiateViewController(withIdentifier: "dashboard") as! DashboardViewController

        let navController = UINavigationController(rootViewController: profileViewController)
        navController.tabBarItem.image = #imageLiteral(resourceName: "dashboardUnselected")
        navController.tabBarItem.selectedImage = #imageLiteral(resourceName: "dashboardSelected")
        navController.tabBarItem.title = NSLocalizedString("Dashboard", comment: "")
        viewControllers?.append(navController)
    }
}
