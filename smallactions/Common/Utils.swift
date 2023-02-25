//
//  Utils.swift
//  smallactions
//
//  Created by Jo on 2022/12/17.
//

import UIKit
import MessageUI

class Utils {
    
    static let icloud = "icloud"
    // MARK: Time
    
    static func ymdEToDate(_ strDate: String) -> Date? {
        if strDate.isEmpty { return nil }
        Utils.icloud
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy년 M월 d일 EEEEE"
        dateFormatter.locale = Locale(identifier: "ko_KR")
        return dateFormatter.date(from: strDate)
    }
    
    static func dateToYmdE(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 M월 d일 EEEEE"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }
    
    static func monthDateDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M월 d일 EEEEE"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }
    
    static func dateToE(_ date: Date, _ locale: String = "ko_KR") -> String {
        let formatter = DateFormatter()
        switch locale {
        case "en_US":
            formatter.dateFormat = "EEE"
        default:
            formatter.dateFormat = "EEEEE요일"
        }
        formatter.locale = Locale(identifier: locale)
        return formatter.string(from: date)
    }
    
    static func monthDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M월 d일"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }
    
    static func ampmTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "a h:mm"
        formatter.amSymbol = "오전"
        formatter.pmSymbol = "오후"
        return formatter.string(from: date)
    }
    
    static func getDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }
    
    static func getMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M월"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }
    
    static func getYear(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }
    
    static func getYearMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 M월"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }
    
    static func orderDay(_ str1: String, _ str2: String) -> Bool {
        if str2 == "일요일" { return true }
        else if str1 == "일요일" { return false }
        if str2 == "토요일" { return true }
        else if str1 == "토요일" { return false }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEEE"
        dateFormatter.locale = Locale(identifier: "ko_KR")
        return dateFormatter.date(from: str1)! < dateFormatter.date(from: str2)!
    }
    
    static func getOneWeekString(_ firstDate: Date, _ lastDate: Date) -> String {
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 M월 d일 - "
        formatter.locale = Locale(identifier: "ko_KR")
        
        let lastFormatter = DateFormatter()
        lastFormatter.dateFormat = "M월 d일"
        lastFormatter.locale = Locale(identifier: "ko_KR")
        
        return formatter.string(from: firstDate) + lastFormatter.string(from: lastDate)
    }
    
    static func addLaunchCount() {
        /*
         let id: String
         let createdTime: Date
         let title: String
         let emoji: String
         
         */
        var launchList: [CommonAction]
        let userDefaults = UserDefaults.standard
        if let data = userDefaults.object(forKey: "launchCount") as? [[String: Any]]  {
            launchList = data.compactMap {
                guard let id = $0["id"] as? String else { return nil }
                guard let createdTime = $0["createdTime"] as? Date else { return nil }
                guard let title = $0["title"] as? String else { return nil }
                guard let emoji = $0["emoji"] as? String else { return nil }
                return CommonAction(id: id, createdTime: createdTime, title: title, emoji: emoji)
            }
        }  else {
            launchList = []
        }
        
        launchList.append(CommonAction(id: UUID().uuidString, createdTime: Date.now, title: "작은 실천 들어오기", emoji: "😁"))
        let launchData = launchList.map {
            [
                "id": $0.id,
                "createdTime": $0.createdTime,
                "title": $0.title,
                "emoji": $0.emoji,
            ]
        }
        userDefaults.set(launchData, forKey: "launchCount")
    }
    
    static func getLaunchCount() -> [CommonAction]? {
        let userDefaults = UserDefaults.standard
        guard let data = userDefaults.object(forKey: "launchCount") as? [[String: Any]] else { return [] }
        var launchList: [CommonAction] = data.compactMap {
            guard let id = $0["id"] as? String else { return nil }
            guard let createdTime = $0["createdTime"] as? Date else { return nil }
            guard let title = $0["title"] as? String else { return nil }
            guard let emoji = $0["emoji"] as? String else { return nil }
            return CommonAction(id: id, createdTime: createdTime, title: title, emoji: emoji)
        }
        launchList = launchList.sorted(by: {
            $0.createdTime.compare($1.createdTime) == .orderedDescending
        })
        return launchList
    }
    
    static func sendEmailToAsk(_ viewController: UIViewController) {
        if !MFMailComposeViewController.canSendMail() {
            print("Mail services are not available")
            AlertService.presentAlert(alert: AlertService.noMailAlert(), vc: viewController)
            return
        }
        let composeVC = MFMailComposeViewController()
        composeVC.mailComposeDelegate = viewController as? MFMailComposeViewControllerDelegate
        
        composeVC.setToRecipients(["brightspread.jo@gmail.com"])
        composeVC.setSubject("작은 실천 문의사항")
        
        viewController.present(composeVC, animated: true, completion: nil)
    }
    
    static func requestNotificationuthorization() {
        let userNotiCenter = UNUserNotificationCenter.current()
        let notiAuthOptions = UNAuthorizationOptions(arrayLiteral: [.alert, .badge, .sound, .provisional])
        userNotiCenter.requestAuthorization(options: notiAuthOptions) { (success, error) in
            if let error = error {
                print(#function, error)
            }
        }
    }
    
    // TODO 알림 권한 체크 팝업
    static func triggerNotification() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        guard let allActions = CoreDataManager.shared.fetchAllAction() else { return }
        allActions.forEach {
            if $0.isAlarmOn && !$0.isDone {
                if let date = $0.dueDate {
                    let alarmComponents: DateComponents!
                    if let time = $0.dueTime { // 설정 시간이 있으면
                        let dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: date)
                        let timeComponents = Calendar.current.dateComponents([.hour, .minute], from: time)
                        alarmComponents = DateComponents(year: dateComponents.year,
                                                         month: dateComponents.month,
                                                         day: dateComponents.day,
                                                         hour: timeComponents.hour,
                                                         minute: timeComponents.minute)
                        
                    } else {
                        // 설정 시간이 없으면 22시
                        let dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: date)
                        alarmComponents = DateComponents(year: dateComponents.year,
                                                         month: dateComponents.month,
                                                         day: dateComponents.day,
                                                         hour: 22,
                                                         minute: 0)
                        
                    }
                    let trigger = UNCalendarNotificationTrigger(dateMatching: alarmComponents, repeats: false) // alarm 시간 트리거

                    // Notification build
                    let userNotiCenter = UNUserNotificationCenter.current()
                    let notiContent = UNMutableNotificationContent()
                    notiContent.title = "\($0.emoji ?? "") 작은 실천"
                    notiContent.body = "\($0.title ?? "") 해볼 시간이에요. 화이팅 👍🏻"
//                    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
                    let request = UNNotificationRequest(
                        identifier: UUID().uuidString,
                        content: notiContent,
                        trigger: trigger
                    )
                    userNotiCenter.add(request) { (error) in
                        if let error = error {
                            print(#function, error as Any)
                        }
                    }
               }
            }
        }
    }
    
    
    
}
