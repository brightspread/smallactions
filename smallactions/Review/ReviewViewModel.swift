//
//  ReviewViewModel.swift
//  smallactions
//
//  Created by Jo on 2022/12/31.
//

import Foundation
import CoreData
import RxSwift
import RxRelay

enum ReviewWMState: String {
    case week = "주간"
    case month = "월간"
}

protocol ReviewViewModelType {
    var rxReviews: BehaviorRelay<[Review]> { get }
    var rxSelectedDate: BehaviorRelay<Date> { get set }
    var rxOneWeekString: Observable<String> { get }
    var rxWMstate: BehaviorRelay<ReviewWMState> { get set }
    func rxConfigureData()
}

class ReviewViewModel: ReviewViewModelType {
    var disposeBag = DisposeBag()
    var rxReviews = BehaviorRelay<[Review]>(value: [])
    var rxWMstate = BehaviorRelay<ReviewWMState>(value: .week)
    var rxSelectedDate = BehaviorRelay<Date>(value: .now)
    var rxFirstDate = BehaviorRelay<Date>(value: .now)
    var rxLastDate = BehaviorRelay<Date>(value: .now)
    
    lazy var rxOneWeekString = rxLastDate.map { [weak self] in
        if let firstDate = self?.rxFirstDate.value,
           let reviews = self?.rxReviews,
           let disposeBag = self?.disposeBag {
            self?.rxLoadReviews()
                .bind(to: reviews)
                .disposed(by: disposeBag)
            return Utils.getOneWeekString(firstDate, $0)
        }
        return ""
    }
    
    func rxConfigureData() {
        _ = rxWMstate.subscribe(onNext: { [weak self] in
            if let date = self?.rxSelectedDate.value,
               let firstDate = self?.rxFirstDate {
                switch $0 {
                case .week:
                    if Utils.dateToE(date) != "일요일" {
                        if let weekdate = self?.getStartDayOfWeek(date) {
                            _ = Observable.just(weekdate)
                                .bind(to: firstDate)
                        }
                    } else  {
                        _ = Observable.just(date)
                            .bind(to: firstDate)
                    }
                case .month:
                    if let monthDate = self?.getStartDayOfMonth(date) {
                        _ = Observable.just(monthDate)
                            .bind(to: firstDate)
                    }
                }
            }
        })
        
        _ = rxSelectedDate.subscribe(onNext: { [weak self] in
            if let firstDate = self?.rxFirstDate {
                switch self?.rxWMstate.value {
                case .week:
                    if Utils.dateToE($0) != "일요일" {
                        if let weekdate = self?.getStartDayOfWeek($0) {
                            _ = Observable.just(weekdate)
                                .bind(to: firstDate)
                        }
                    } else  {
                        _ = Observable.just($0)
                            .bind(to: firstDate)
                    }
                case .month:
                    if let monthDate = self?.getStartDayOfMonth($0) {
                        _ = Observable.just(monthDate)
                            .bind(to: firstDate)
                    }
                case .none:
                    print("reviewModel rxwmstate none")
                }
            }
        })
        
        _ = rxFirstDate.subscribe(onNext: { [weak self] in
            if let rxLastDate = self?.rxLastDate {
                switch self?.rxWMstate.value {
                case .month:
                    if let date = self?.getEndDayOfMonth($0) {
                        _ = Observable.just(date)
                            .bind(to: rxLastDate)
                    }
                case .week:
                    if let calendar = Calendar.current.date(byAdding: .day, value: +6, to: $0) {
                        _ = Observable.just(calendar)
                            .bind(to: rxLastDate)
                    }
                case .none:
                    print("rxFirstdate nil")
                }
            }
        })
        
        rxLoadReviews()
            .bind(to: rxReviews)
            .disposed(by: disposeBag)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(changeActionNotification(_ :)),
            name: NSNotification.Name("changeAction"),
            object: nil
        )
    }
    
    @objc private func changeActionNotification(_ notification: Notification) {
        rxLoadReviews()
            .bind(to: rxReviews)
            .disposed(by: disposeBag)
    }
    
    private func rxLoadReviews() -> Observable<[Review]> {
        return Observable.create { [weak self] emitter in
            guard let firstDate = self?.rxFirstDate.value else { return Disposables.create() }
            guard let lastDate = self?.rxLastDate.value else { return Disposables.create() }
            guard let launchList = Utils.getLaunchCount() else { return Disposables.create() }
            
            //     해당 날짜 실천 조회
            let request: NSFetchRequest<Action> = Action.fetchRequest()
            request.predicate = NSPredicate(format: "dueDate >= %@ && dueDate < %@", Calendar.current.startOfDay(for: firstDate) as CVarArg, Calendar.current.startOfDay(for: lastDate) + 86400 as CVarArg)
            let actions = CoreDataManager.shared.fetch(request: request).filter {
                $0.isDone
            }
            
            //              타이틀 & 이모지 동일하면 만들기
            var arrReview = Array<Review>()
            actions.forEach { action in
                var count = 1
                var lastDate = action.dueDate
                for i in 0..<arrReview.count {
                    let tReview = arrReview[i]
                    if action.title == tReview.actionTitle
                        && action.emoji == tReview.actionEmoji { // 이름으로만 구분
                        count = tReview.count + 1  //카운트를 1 늘려가면서..
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
                        arrReview.remove(at: i)  //새로 만들기위해 지움
                        break
                    }
                }
                let review = Review(actionTitle: action.title, actionEmoji: action.emoji, count: count, lastDate: lastDate)
                arrReview.append(review)
            }
            
            let filteredList = launchList.filter {
                $0.createdTime >= Calendar.current.startOfDay(for: firstDate) && $0.createdTime <= Calendar.current.startOfDay(for: lastDate) + 86400 - 1
            }  // 해당 주에 들어온 횟수만 봄
            if !filteredList.isEmpty {
                guard let launchInfo = filteredList.first else { return Disposables.create() }
                let review = Review(actionTitle: launchInfo.title, actionEmoji: launchInfo.emoji, count: filteredList.count, lastDate: launchInfo.createdTime)
                arrReview.insert(review, at: arrReview.count)
            }
            
            emitter.onNext(arrReview)
            emitter.onCompleted()
            return Disposables.create()
        }
        
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
}

