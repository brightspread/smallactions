//
//  Utils.swift
//  smallactions
//
//  Created by Jo on 2022/12/17.
//

import Foundation

class Utils {
    // MARK: Time
    
    static func ymdEToDate(strDate: String) -> Date? {
        if strDate.isEmpty { return nil }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy년 M월 d일 EEEEE"
        dateFormatter.locale = Locale(identifier: "ko_KR")
        return dateFormatter.date(from: strDate)
    }
    
    static func dateToYmdE(date: Date) -> String {
      let formatter = DateFormatter()
      formatter.dateFormat = "yyyy년 M월 d일 EEEEE"
      formatter.locale = Locale(identifier: "ko_KR")
      return formatter.string(from: date)
    }
    
    static func monthDateDay(date: Date) -> String {
      let formatter = DateFormatter()
      formatter.dateFormat = "M월 d일 EEEEE"
      formatter.locale = Locale(identifier: "ko_KR")
      return formatter.string(from: date)
    }
    
    static func ampmTime(date: Date) -> String {
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
    
    static func orderDay(str1: String, str2: String) -> Bool {
        if str2 == "일요일" { return true }
        else if str1 == "일요일" { return false }
        if str2 == "토요일" { return true }
        else if str1 == "토요일" { return false }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEEE"
        dateFormatter.locale = Locale(identifier: "ko_KR")
        return dateFormatter.date(from: str1)! < dateFormatter.date(from: str2)!
    }
}
