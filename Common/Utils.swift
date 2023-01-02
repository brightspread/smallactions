//
//  Utils.swift
//  smallactions
//
//  Created by Jo on 2022/12/17.
//

import Foundation

class Utils {
    // MARK: Time
    
    static func ymdEToDate(_ strDate: String) -> Date? {
        if strDate.isEmpty { return nil }
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
    
    static func dateToE(_ date: Date) -> String {
      let formatter = DateFormatter()
      formatter.dateFormat = "EEEEE요일"
      formatter.locale = Locale(identifier: "ko_KR")
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
}
