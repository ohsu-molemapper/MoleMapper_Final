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

import Foundation

enum UDItems: String {
    case areHelpScreensDisabled
    case areHintsEnabled
    case askWhenDone
    case firstTimeLogin
    case firstTimeIdentifyCoinOpened //
    case firstMoleReview //
    case firstZoneReview //
    case moleNameGender
    case nextMoleID
    case numberOfTimesAppOpened // number of times app was opened
    case reminderFrequency
    case shouldShowRememberCoinPopup
    case shouldShowWelcomeScreenWithCarousel
    case showNotificationsCoach //
    case showDashboard //
    case userHasSeenNotificationRequest
    case userHasNotSeenWelcome
    case userDisabledMoleNotifications
    case userPreapprovedNotificationRequest
}

@objc
extension UserDefaults {
    // Demonstration objects; have yet to test if we can see these in Obj-C
    class var areHelpScreensDisabled: Bool {
        get {
            return UserDefaults.standard.bool(forKey: UDItems.areHelpScreensDisabled.rawValue)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UDItems.areHelpScreensDisabled.rawValue)
        }
    }
    class var areHintsEnabled: Bool {
        get {
            return UserDefaults.standard.bool(forKey: UDItems.areHintsEnabled.rawValue)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UDItems.areHintsEnabled.rawValue)
        }
    }
    class var askWhenDone: Bool {
        get {
            return UserDefaults.standard.bool(forKey: UDItems.askWhenDone.rawValue)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UDItems.askWhenDone.rawValue)
        }
    }
    class var firstTimeLogin: Bool {
        get {
            return UserDefaults.standard.bool(forKey: UDItems.firstTimeLogin.rawValue)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UDItems.firstTimeLogin.rawValue)
        }
    }
    class var firstTimeIdentifyCoinOpened: Bool {
        get {
            return UserDefaults.standard.bool(forKey: UDItems.firstTimeIdentifyCoinOpened.rawValue)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UDItems.firstTimeIdentifyCoinOpened.rawValue)
        }
    }
    class var firstMoleReview: Bool {
        get {
            return UserDefaults.standard.bool(forKey: UDItems.firstMoleReview.rawValue)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UDItems.firstMoleReview.rawValue)
        }
    }
    class var firstZoneReview: Bool {
        get {
            return UserDefaults.standard.bool(forKey: UDItems.firstZoneReview.rawValue)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UDItems.firstZoneReview.rawValue)
        }
    }
    class var moleNameGender: String! {
        get {
            return UserDefaults.standard.string(forKey: UDItems.moleNameGender.rawValue)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UDItems.moleNameGender.rawValue)
        }
    }
    class var nextMoleID: Int {
        get {
            return UserDefaults.standard.integer(forKey: UDItems.nextMoleID.rawValue)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UDItems.nextMoleID.rawValue)
        }
    }
    class var numberOfTimesAppOpened: Int {
        get {
            return UserDefaults.standard.integer(forKey: UDItems.numberOfTimesAppOpened.rawValue)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UDItems.numberOfTimesAppOpened.rawValue)
        }
    }
    class var reminderFrequencyInMonths: Int {
        get {
            return UserDefaults.standard.integer(forKey: UDItems.reminderFrequency.rawValue)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UDItems.reminderFrequency.rawValue)
        }
    }
    class var shouldShowRememberCoinPopup: Bool {
        get {
            return UserDefaults.standard.bool(forKey: UDItems.shouldShowRememberCoinPopup.rawValue)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UDItems.shouldShowRememberCoinPopup.rawValue)
        }
    }
    class var shouldShowWelcomeScreenWithCarousel: Bool {
        get {
            return UserDefaults.standard.bool(forKey: UDItems.shouldShowWelcomeScreenWithCarousel.rawValue)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UDItems.shouldShowWelcomeScreenWithCarousel.rawValue)
        }
    }
    class var showNotificationsCoach: Bool {
        get {
            return UserDefaults.standard.bool(forKey: UDItems.showNotificationsCoach.rawValue)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UDItems.showNotificationsCoach.rawValue)
        }
    }
    class var showDashboard: Bool {
        get {
            return UserDefaults.standard.bool(forKey: UDItems.showDashboard.rawValue)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UDItems.showDashboard.rawValue)
        }
    }
    class var userHasNotSeenWelcome: Bool {
        get {
            return UserDefaults.standard.bool(forKey: UDItems.userHasNotSeenWelcome.rawValue)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UDItems.userHasNotSeenWelcome.rawValue)
        }
    }
    class var userHasSeenNotificationRequest: Bool {
        get {
            return UserDefaults.standard.bool(forKey: UDItems.userHasSeenNotificationRequest.rawValue)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UDItems.userHasSeenNotificationRequest.rawValue)
        }
    }
    class var userDisabledMoleNotifications: Bool {
        get {
            return UserDefaults.standard.bool(forKey: UDItems.userDisabledMoleNotifications.rawValue)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UDItems.userDisabledMoleNotifications.rawValue)
        }
    }
    class var userPreapprovedNotificationRequest: Bool {
        get {
            return UserDefaults.standard.bool(forKey: UDItems.userPreapprovedNotificationRequest.rawValue)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UDItems.userPreapprovedNotificationRequest.rawValue)
        }
    }

  
    // ------------ Set up default values
    class func setupStdUserDefaults() {
        if UserDefaults.standard.object(forKey: UDItems.areHelpScreensDisabled.rawValue) == nil {
            UserDefaults.areHelpScreensDisabled = false
        }
        if UserDefaults.standard.object(forKey: UDItems.areHintsEnabled.rawValue) == nil {
            UserDefaults.areHintsEnabled = true
        }
        if UserDefaults.standard.object(forKey: UDItems.askWhenDone.rawValue) == nil {
            UserDefaults.askWhenDone = true
        }
        if UserDefaults.standard.object(forKey: UDItems.firstTimeLogin.rawValue) == nil {
            UserDefaults.firstTimeLogin = true
        }
        if UserDefaults.standard.object(forKey: UDItems.firstTimeIdentifyCoinOpened.rawValue) == nil {
            UserDefaults.firstTimeIdentifyCoinOpened = true
        }
        if UserDefaults.standard.object(forKey: UDItems.firstMoleReview.rawValue) == nil {
            UserDefaults.firstMoleReview = true
        }
        if UserDefaults.standard.object(forKey: UDItems.firstZoneReview.rawValue) == nil {
            UserDefaults.firstZoneReview = true
        }
        if UserDefaults.standard.object(forKey: UDItems.moleNameGender.rawValue) == nil {
            UserDefaults.moleNameGender = "Random"
        }
        if UserDefaults.standard.object(forKey: UDItems.nextMoleID.rawValue) == nil {
            UserDefaults.nextMoleID = 1
        }
        if UserDefaults.standard.object(forKey: UDItems.numberOfTimesAppOpened.rawValue) == nil {
            UserDefaults.numberOfTimesAppOpened = 0
        }
        if UserDefaults.standard.object(forKey: UDItems.reminderFrequency.rawValue) == nil {
            UserDefaults.reminderFrequencyInMonths = 0
        }
        if UserDefaults.standard.object(forKey: UDItems.shouldShowRememberCoinPopup.rawValue) == nil {
            UserDefaults.shouldShowRememberCoinPopup = true
        }
        if UserDefaults.standard.object(forKey: UDItems.shouldShowWelcomeScreenWithCarousel.rawValue) == nil {
            UserDefaults.shouldShowWelcomeScreenWithCarousel = true
        }
        if UserDefaults.standard.object(forKey: UDItems.showNotificationsCoach.rawValue) == nil {
            UserDefaults.showNotificationsCoach = false
        }
        if UserDefaults.standard.object(forKey: UDItems.showDashboard.rawValue) == nil {
            UserDefaults.showDashboard = true
        }
        if UserDefaults.standard.object(forKey: UDItems.userHasNotSeenWelcome.rawValue) == nil {
            UserDefaults.userHasNotSeenWelcome = true
        }
        if UserDefaults.standard.object(forKey: UDItems.userHasSeenNotificationRequest.rawValue) == nil {
            UserDefaults.userHasSeenNotificationRequest = false
        }
        if UserDefaults.standard.object(forKey: UDItems.userDisabledMoleNotifications.rawValue) == nil {
            UserDefaults.userDisabledMoleNotifications = false
        }
        if UserDefaults.standard.object(forKey: UDItems.userPreapprovedNotificationRequest.rawValue) == nil {
            UserDefaults.userPreapprovedNotificationRequest = false
        }
    }
}

