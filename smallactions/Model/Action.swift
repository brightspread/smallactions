//
//  Action.swift
//  smallactions
//
//  Created by Jo on 2022/12/14.
//

import Foundation

struct ActionItem {
    var id: String
    var emoji: String?
    var title: String
    var dueTime: Date?
    var dueDate: Date?
    var isDone: Bool?
    var isAlarmOn: Bool?
    var routines: [String]?
    var endDate: Date?
    var tags: [String]?
    var color: String?
    var createdTime: String?
    var unit: String?
    var category: String?
    var rNextAction: String?
    var rBeforeAction: String?
}
