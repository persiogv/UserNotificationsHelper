//
//  UserNotificationsHelper.swift
//
//  Created by Pérsio on 02/02/19.
//  Copyright © 2019 Persio Vieira. All rights reserved.
//

import UserNotifications

enum UserNotificationsHelperError: Error {
    case unauthorized
    case unauthorizedOptions(options: UNAuthorizationOptions)
    case unhandledError(error: Error)
}

struct UserNotificationsHelper {
    
    // MARK: - Public statements
    
    static func scheduleLocalNotification(withIdentifier identifier: String,
                                          options: UNAuthorizationOptions,
                                          content: UNNotificationContent,
                                          trigger: UNCalendarNotificationTrigger?,
                                          completion: @escaping (() throws -> Void) -> Void) {
        center.getNotificationSettings { (settings) in
            guard settings.authorizationStatus == .authorized else {
                return completion { throw UserNotificationsHelperError.unauthorized }
            }
            
            authorizedOptions { (results) in
                do {
                    let authorizedOptions = try results()
                    
                    if authorizedOptions.contains(options) {
                        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                        center.add(request) { (error) in
                            guard let error = error else { return completion {} }
                            return completion { throw UserNotificationsHelperError.unhandledError(error: error) }
                        }
                        return
                    }
                    
                    completion {
                        let invalidOptions = options.subtracting(authorizedOptions)
                        throw UserNotificationsHelperError.unauthorizedOptions(options: invalidOptions)
                    }
                } catch {
                    completion { throw error }
                }
            }
        }
    }
    
    static func requestAuthorization(for options: UNAuthorizationOptions, completion: @escaping (() throws -> Bool) -> Void) {
        center.requestAuthorization(options: options) { (success, error) in
            guard let error = error else { return completion { return success } }
            completion { throw UserNotificationsHelperError.unhandledError(error: error) }
        }
    }
    
    static func authorizedOptions(completion: @escaping (() throws -> UNAuthorizationOptions) -> Void) {
        center.getNotificationSettings { (settings) in
            var options: UNAuthorizationOptions = []
            if settings.badgeSetting == .enabled {
                options.insert(.badge)
            }
            
            if settings.soundSetting == .enabled {
                options.insert(.sound)
            }
            
            if settings.alertSetting == .enabled {
                options.insert(.alert)
            }
            
            if settings.carPlaySetting == .enabled {
                options.insert(.carPlay)
            }
            
            completion { return options }
        }
    }
    
    static func registerNotificationCategories(_ categories: Set<UNNotificationCategory>) {
        center.setNotificationCategories(categories)
    }
    
    static func unscheduleAllLocalNotifications() {
        center.removeAllPendingNotificationRequests()
    }
    
    // MARK: - Private statements
    
    private static let center = UNUserNotificationCenter.current()
}
