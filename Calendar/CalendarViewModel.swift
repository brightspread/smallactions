//
//  CalendarViewModel.swift
//  smallactions
//
//  Created by Jo on 2022/12/29.
//

import Foundation
import CoreData

enum CalendarData: String {
    case baseData = "baseData"
    case selectedData = "selectedData"
}

class CalendarViewModel: CalendarViewModelType {
    var delegate: CalendarViewDelegate?
    
    var selectedDateActions: [Action] = []{
        didSet {
            self.delegate?.selectedActionDidChanged()
        }
    }
    
    var allActions: [Action] = []{
        didSet {
//            self.delegate?.actionDidChanged()
        }
    }
    
    private var selectedDate: Date = Date.now {
        didSet {
            self.days = generateDaysInMonth(for: self.selectedDate)
            self.delegate?.dateDidChanged()
            self.delegate?.valueChanged([.selectedData: self.selectedDate])
            self.loadSelectedDateActions()
        }
    }
    
    private var baseDate: Date = Date.now {
        didSet {
            self.days = generateDaysInMonth(for: self.baseDate)
            self.delegate?.dateDidChanged()
            self.delegate?.valueChanged([.baseData: self.baseDate])
            self.loadSelectedDateActions()
        }
    }
    
    lazy var days = generateDaysInMonth(for: baseDate)
    
    private var numberOfWeeksInBaseDate: Int {
        self.calendar.range(of: .weekOfMonth, in: .month, for: baseDate)?.count ?? 0
    }
    
    
    private let calendar = Calendar(identifier: .gregorian)
    private lazy var numberDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d"
        return dateFormatter
    }()
    
    func showLastMonth() {
        self.baseDate = self.calendar.date(
            byAdding: .month,
            value: -1,
            to: self.baseDate
        ) ?? self.baseDate
    }
    
    func showNextMonth() {
        self.baseDate = self.calendar.date(byAdding: .month,
                                           value: 1,
                                           to: self.baseDate) ?? self.baseDate

    }
    
    func selectDate(_ date: Date) {
        self.selectedDate = date
    }
    
    func getCalendarSize(width: CGFloat, height: CGFloat) -> CGSize {
        let width = Int(width / 7)
        let height = Int(height) / numberOfWeeksInBaseDate
        return CGSize(width: width, height: height)
    }
    
    func loadSelectedDateActions() {
        let request: NSFetchRequest<Action> = Action.fetchRequest()
        request.predicate = NSPredicate(format: "dueDate >= %@ && dueDate <= %@", Calendar.current.startOfDay(for: self.selectedDate) as CVarArg, Calendar.current.startOfDay(for: self.selectedDate + 86400) as CVarArg)
        self.selectedDateActions = CoreDataManager.shared.fetch(request: request).sorted(by: {
            
            if $0.isDone != $1.isDone {
                return !$0.isDone
            }
            
            guard let lt = $0.dueTime else { return true }
            guard let rt = $1.dueTime else { return false }
            return lt < rt
        })
    }
    
    func loadAllActions() {
        let request: NSFetchRequest<Action> = Action.fetchRequest()
        self.allActions = CoreDataManager.shared.fetch(request: request)
    }
    
    func getActionProgress(_ date: Date) -> Double {
        let dateActions = self.allActions.filter {
            guard let dueDate = $0.dueDate else { return false }
            return dueDate >= date && dueDate <= (date + 86400)
        }
        if dateActions.count > 0 {
            var sum = 0.0
            dateActions.forEach {
                if $0.isDone { sum += 1.0 }
            }
            return sum/Double(dateActions.count)
        }
        return -1
    }

}

private extension CalendarViewModel {
    func monthMetadata(for baseDate: Date) throws -> MonthMetadata {
        guard let numberOfDaysInMonth = calendar.range(of: .day,in: .month,for: baseDate)?.count,
              let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: baseDate))
        else { throw CalendarDataError.metadataGeneration }
        
        let firstDayWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        
        return MonthMetadata(numberOfDays: numberOfDaysInMonth,
                             firstDay: firstDayOfMonth,
                             firstDayWeekday: firstDayWeekday)
    }
    
    func generateDaysInMonth(for baseDate: Date) -> [Day] {
        guard let metadata = try? monthMetadata(for: baseDate) else {
            preconditionFailure("An error occurred when generating the metadata for \(baseDate)")
        }
        
        let numberOfDaysInMonth = metadata.numberOfDays
        let offsetInInitialRow = metadata.firstDayWeekday
        let firstDayOfMonth = metadata.firstDay
        
        var days: [Day] = (1..<(numberOfDaysInMonth + offsetInInitialRow))
            .map { day in
                let isWithinDisplayedMonth = day >= offsetInInitialRow
                let dayOffset =
                isWithinDisplayedMonth ?
                day - offsetInInitialRow :
                -(offsetInInitialRow - day)
                
                return generateDay(offsetBy: dayOffset,
                                   for: firstDayOfMonth,
                                   isWithinDisplayedMonth: isWithinDisplayedMonth)
            }
        
        days += generateStartOfNextMonth(using: firstDayOfMonth)
        
        return days
    }
    
    func generateDay(
        offsetBy dayOffset: Int,
        for baseDate: Date,
        isWithinDisplayedMonth: Bool
    ) -> Day {
        let date = calendar.date(byAdding: .day,
                                 value: dayOffset,
                                 to: baseDate) ?? baseDate
        
        return Day(date: date,
                   number: Utils.getDay(date),
                   isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                   isWithinDisplayedMonth: isWithinDisplayedMonth)
    }
    
    func generateStartOfNextMonth(using firstDayOfDisplayedMonth: Date) -> [Day] {
        guard let lastDayInMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1),
                                                 to: firstDayOfDisplayedMonth)
        else { return [] }
        
        let additionalDays = 7 - calendar.component(.weekday, from: lastDayInMonth)
        guard additionalDays > 0 else { return [] }
        
        let days: [Day] = (1...additionalDays)
            .map {
                generateDay(offsetBy: $0,
                            for: lastDayInMonth,
                            isWithinDisplayedMonth: false)
            }
        
        return days
    }
    
    enum CalendarDataError: Error {
        case metadataGeneration
    }
}


protocol CalendarViewModelType {
    
}
