//
//  ReviewViewModel.swift
//  smallactions
//
//  Created by Jo on 2022/12/31.
//

import Foundation
import CoreData

enum ReviewWMState: String {
    case week = "주간"
    case month = "월간"
}

class ReviewViewModel {
    var delegate: ReviewViewDelegate?
    
    var reviews: [Review] = [] {
        didSet {
            self.delegate?.reviewDidChange()
        }
    }
    
    // week month
    var wmstate: ReviewWMState = .week {
        didSet {
            guard let selectedDate = self.selectedDate else { return }
            switch self.wmstate {
            case .month:
                self.firstDate = getStartDayOfMonth(selectedDate)
            case .week:
                if Utils.dateToE(selectedDate) != "일요일" {
                    self.firstDate = getStartDayOfWeek(selectedDate)
                } else {
                    self.firstDate = selectedDate
                }
            }
        }
    }
    
    var selectedDate: Date? { // 몇 번째 주
        didSet {
            guard let selectedDate = self.selectedDate else { return }
            switch wmstate {
            case .month:
                self.firstDate = getStartDayOfMonth(selectedDate)
            case .week:
                if Utils.dateToE(selectedDate) != "일요일" {
                    self.firstDate = getStartDayOfWeek(selectedDate)
                } else {
                    self.firstDate = selectedDate
                }
            }
        }
    }
    
    private var firstDate: Date? {
        didSet {
            guard let firstDate = self.firstDate else { return }
            switch wmstate {
            case .month:
                self.lastDate = getEndDayOfMonth(firstDate)
            case .week:
                let calendar = Calendar.current
                self.lastDate = calendar.date(byAdding: .day, value: +6, to: firstDate)
            }
        }
    }

    private var lastDate: Date? {
        didSet {
            guard let firstDate = self.firstDate else { return }
            guard let lastDate = self.lastDate else { return }
            self.oneWeekString = Utils.getOneWeekString(firstDate, lastDate)
            self.loadReviews()
        }
    }
    
    var oneWeekString: String?
    
    func configureData() {
        self.selectedDate = Date.now
        self.loadReviews()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(changeActionNotification(_ :)),
            name: NSNotification.Name("changeAction"),
            object: nil
        )
    }
    
    private func loadReviews() {
        guard let firstDate = self.firstDate else { return }
        guard let lastDate = self.lastDate else { return }

        // 해당 날짜 실천 조회
        let request: NSFetchRequest<Action> = Action.fetchRequest()
        request.predicate = NSPredicate(format: "dueDate >= %@ && dueDate < %@", Calendar.current.startOfDay(for: firstDate) as CVarArg, Calendar.current.startOfDay(for: lastDate) + 86400 as CVarArg)
        let actions = CoreDataManager.shared.fetch(request: request).filter {
            $0.isDone
        }
        
        // 타이틀 & 이모지 동일하면 만들기
        self.reviews.removeAll()
        actions.forEach { action in
            var count = 1
            var lastDate = action.dueDate
            for i in 0..<self.reviews.count {
                let tReview = self.reviews[i]
                if action.title == tReview.actionTitle &&
                    action.emoji == tReview.actionEmoji {
                    count = tReview.count + 1 // 카운트를 1 늘려가면서..
                    lastDate = tReview.lastDate
                    if lastDate == nil {
                        lastDate = action.dueDate
                    } else {
                        if let tLastDate = lastDate, let dueDate = action.dueDate {
                            if tLastDate < dueDate {
                                lastDate = dueDate
                            }
                        }
                    }
                    self.reviews.remove(at: i) // 새로 만들기위해 지움
                    break
                }
            }
            let review = Review(actionTitle: action.title, actionEmoji: action.emoji, count: count, lastDate: lastDate)
            self.reviews.append(review)
        }
        self.addLaunchReview()

        self.delegate?.reviewDidChange()
    }
    
    
    @objc private func changeActionNotification(_ notification: Notification) {
        self.loadReviews()
    }
}

// Calendar
private extension ReviewViewModel {
    private func getStartDayOfWeek(_ date: Date) -> Date {
        var tempDate = date
        repeat {
            tempDate -= 86400
        } while (Utils.dateToE(tempDate) != "일요일")
        return tempDate
    }
    
    private func getStartDayOfMonth(_ date: Date) -> Date {
        let dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: date)
        let startDayComponents = DateComponents(year: dateComponents.year,
                                         month: dateComponents.month,
                                         day: 1)
        guard let newStartDay = Calendar.current.date(from: startDayComponents) else { return date }
        return newStartDay
    }
    
    private func getEndDayOfMonth(_ date: Date) -> Date {
        let calendar = Calendar(identifier: .gregorian)
        guard let numberOfDaysInMonth = calendar.range(of: .day,in: .month,for: date)?.count else { return date }
        guard let endDay = calendar.date(byAdding: .day, value: +(numberOfDaysInMonth - 1), to: date) else { return date }
        return endDay
    }
    
    private func addLaunchReview() {
        guard let launchList = Utils.getLaunchCount() else { return }
        guard let firstDate = self.firstDate else { return }
        guard let lastDate = self.lastDate else { return }

        let filteredList = launchList.filter {
            $0.createdTime >= Calendar.current.startOfDay(for: firstDate) && $0.createdTime <= Calendar.current.startOfDay(for: lastDate) + 86400 - 1
        } // 해당 주에 들어온 횟수만 봄
        if !filteredList.isEmpty {
            guard let launchInfo = filteredList.first else { return }
            let review = Review(actionTitle: launchInfo.title, actionEmoji: launchInfo.emoji, count: filteredList.count, lastDate: launchInfo.createdTime)
            self.reviews.insert(review, at: 0)
        }
    }

}

protocol ReviewViewModelType {
    var delegate: ReviewViewDelegate? { get set}
    var reviews: [Review]! { get }
    var selectedDate: Date? { get set }
    var oneWeekString: String? { get }
}
