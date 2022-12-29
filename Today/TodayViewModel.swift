//
//  TodayViewModel.swift
//  smallactions
//
//  Created by Jo on 2022/12/27.
//

import Foundation
import CoreData

class TodayViewModel: TodayViewModelType {
    var delegate: TodayViewDelegate?
    
    var actions: [Action]! {
        didSet {
            self.delegate?.actionDidChanged()
        }
    }
    
    var selectedDate = Date.now {
        didSet {
            self.loadActions()
        }
    }
    
    func configureData() {
        self.loadActions()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(changeActionNotification(_ :)),
            name: NSNotification.Name("changeAction"),
            object: nil
        )
    }
    
    func loadActions() {
        let request: NSFetchRequest<Action> = Action.fetchRequest()
        request.predicate = NSPredicate(format: "dueDate >= %@ && dueDate <= %@", Calendar.current.startOfDay(for: self.selectedDate) as CVarArg, Calendar.current.startOfDay(for: self.selectedDate + 86400) as CVarArg)
        self.actions = CoreDataManager.shared.fetch(request: request).sorted(by: {
            
            if $0.isDone != $1.isDone {
                return !$0.isDone
            }
            
            guard let lt = $0.dueTime else { return true }
            guard let rt = $1.dueTime else { return false }
            return lt < rt
        })
    }
    
    @objc func changeActionNotification(_ notification: Notification) {
        self.loadActions()
    }
}

protocol TodayViewModelType {
    var delegate: TodayViewDelegate? { get set }
}
