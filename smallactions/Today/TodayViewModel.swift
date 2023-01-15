//
//  TodayViewModel.swift
//  smallactions
//
//  Created by Jo on 2022/12/27.
//

import Foundation
import CoreData
import RxSwift
import RxRelay

protocol TodayViewModelType {
    var rxActions: BehaviorRelay<[Action]> { get }
}

class TodayViewModel: TodayViewModelType {
    var disposeBag = DisposeBag()
    var rxSelectedDate = BehaviorRelay<Date>(value: .now)
    var rxActions = BehaviorRelay<[Action]>(value: [])
    
    init() {
        configureData()
    }
    
    private func configureData() {
        rxSelectedDate.subscribe(onNext: { [weak self] in
            guard let rxActions = self?.rxActions else { return }
            _ = self?.rxLoadActions($0)
                .bind(to: rxActions)
        }).disposed(by: disposeBag)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(changeActionNotification(_ :)),
            name: NSNotification.Name("changeAction"),
            object: nil
        )
    }
    private func rxLoadActions(_ date: Date) -> Observable<[Action]> {
        let request: NSFetchRequest<Action> = Action.fetchRequest()
        request.predicate = NSPredicate(format: "dueDate >= %@ && dueDate < %@", Calendar.current.startOfDay(for: date) as CVarArg, Calendar.current.startOfDay(for: date + 86400) as CVarArg)
        return CoreDataManager.shared.rxFetch(request: request).map {
            return $0.sorted(by: {
                if $0.isDone != $1.isDone {
                    return !$0.isDone
                }
                
                guard let lt = $0.dueTime else { return true }
                guard let rt = $1.dueTime else { return false }
                return lt < rt
            })
        }
    }

    @objc private func changeActionNotification(_ notification: Notification) {
        _ = rxLoadActions(rxSelectedDate.value)
            .bind(to: rxActions)
    }
}


