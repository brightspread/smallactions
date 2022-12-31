//
//  AddActionViewModel.swift
//  smallactions
//
//  Created by Jo on 2022/12/27.
//

import Foundation
import CoreData

enum ActionEditorMode {
    case new
    case edit(Action)
}

enum ActionData: String {
    case dueDate = "dueDate"
    case duetime = "duetime"
    case endDate = "endDate"
    case routines = "routines"
    case title = "title"
    case emoji = "emoji"
    case alarmSwitch = "alarmSwitch"
    case isDone = "isDone"
}

class AddActionViewModel: AddActionViewModelType {
    
    var delegate: AddActionDelegate?
    var action: Action?
    
    var actionEditorMode: ActionEditorMode = .new
    
    private var selectedDueDate = Date.now {
        didSet {
            self.delegate?.valueChanged([ActionData.dueDate : selectedDueDate])
            self.selectedEndDate = self.selectedDueDate + 86400 * 7
        }
    }
    
    private var selectedDueTime: Date? {
        didSet {
            guard let dueTime = selectedDueTime else { return }
            delegate?.valueChanged(
                [ActionData.duetime: dueTime]
            )
        }
    }
    
    
    
    private var selectedEndDate: Date? {
        didSet {
            if let endDate = selectedEndDate {
                delegate?.valueChanged(
                    [ActionData.endDate: endDate]
                )
            }
        }
    }
    
    private var selectedRoutines: [String]? {
        didSet {
            guard let routines = selectedRoutines else { return }
            delegate?.valueChanged([ActionData.routines: routines])
        }
    }
    
    func configureData() {
        self.registerListeners()
        switch actionEditorMode {
        case let .edit(action):
            self.configureTodayContents(action)
        default:
            // 신규 데이터 생성시
            // 초기 값 설정
            self.selectedEndDate = self.selectedDueDate + 86400 * 30
            break
        }
    }
    
    private func configureTodayContents(_ action: Action) {
        print("configureTodayContents : \(action)")
        delegate?.valueChanged(
            [ActionData.title: action.title,
             ActionData.emoji: action.emoji,
             ActionData.alarmSwitch: action.isAlarmOn,
             ActionData.isDone: action.isDone,
             ActionData.routines: action.routines]
        )
        
        self.selectedDueDate = action.dueDate ?? self.selectedDueDate
        self.selectedDueTime = action.dueTime ?? self.selectedDueTime
        self.selectedEndDate = action.endDate ?? self.selectedEndDate
        print("configureTodayContents Done ")
    }
    
    func registerListeners() {
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(routinesSelectNotification(_ :)),
            name: NSNotification.Name("routinesSelect"),
            object: nil
        )
    }
    
    // MARK: CoreData
    func saveAction(title: String,
                    emoji: String? = "",
                    isDone: Bool? = false,
                    isAlarmOn: Bool? = false,
                    dueDate: Date? = nil,
                    dueTime: Date? = nil,
                    routines: [String]? = [],
                    endDate: Date? = nil) {
        switch self.actionEditorMode {
        case let .edit(action):
            guard let id = action.id else { return }
            guard let routines = routines else { return }
            let action = ActionItem(id: id,
                                    emoji: emoji,
                                    title: title,
                                    dueTime: dueTime,
                                    dueDate: dueDate,
                                    isDone: isDone,
                                    isAlarmOn: isAlarmOn,
                                    routines: routines,
                                    endDate: endDate,
                                    tags: [],
                                    color: nil,
                                    unit: nil,
                                    category: nil,
                                    rNextAction: action.rNextAction, // 원래 값을 들고감.
                                    rBeforeAction: action.rBeforeAction)
            if !routines.isEmpty {
                // 루틴 마지막놈으로 연장하고자할때 변경할 때 (1월 30일 -> 2월 28일)
                self.routineInsertActions(action, extendingOption: true)
            } else {
                CoreDataManager.shared.editAction(action)
            }
        case .new:
            guard let routines = routines else { return }
            let action = ActionItem(id: UUID().uuidString,
                                    emoji: emoji,
                                    title: title,
                                    dueTime: dueTime,
                                    dueDate: dueDate,
                                    isDone: isDone,
                                    isAlarmOn: isAlarmOn,
                                    routines: routines,
                                    endDate: endDate,
                                    tags: [],
                                    color: nil,
                                    createdTime: Date.now.description,
                                    unit: nil)
            if !routines.isEmpty {
                self.routineInsertActions(action)
            } else {
                CoreDataManager.shared.insertAction(action)
            }
        }
    }
    
    func existNextAction() -> Bool {
        switch actionEditorMode {
        case .new:
            return false
        case .edit(let action):
            if action.rNextAction == nil {
                return false
            } else {
                return true
            }
        }
    }
    
    // 반복 실천 저장
    func saveRoutineActions(title: String,
                            emoji: String? = "",
                            isDone: Bool? = false,
                            isAlarmOn: Bool? = false,
                            dueDate: Date? = nil,
                            dueTime: Date? = nil,
                            routines: [String]? = [],
                            endDate: Date? = nil) {
        switch actionEditorMode {
        case .new:
            print("error 루틴액션인데 new")
        case .edit(let action):
            guard let routines = routines else { return }
            // 현재 날짜로부터 뒤 실천 다 삭제하고, 새로 추가
            self.deleteRoutines()
            let action = ActionItem(id: UUID().uuidString,
                                    emoji: emoji,
                                    title: title,
                                    dueTime: dueTime,
                                    dueDate: dueDate,
                                    isDone: isDone,
                                    isAlarmOn: isAlarmOn,
                                    routines: routines,
                                    endDate: endDate,
                                    tags: [],
                                    color: nil,
                                    createdTime: Date.now.description,
                                    unit: nil,
                                    rNextAction: nil,
                                    rBeforeAction: nil)
            if !routines.isEmpty {
                self.routineInsertActions(action)
            } else {
                CoreDataManager.shared.insertAction(action)
            }
        }
    }
    
    // 루틴 추가
    // extendingOption = 루틴 마지막날 아이템으로 연장하는 경우
    private func routineInsertActions(_ actionItem: ActionItem, extendingOption: Bool = false) {
        guard let endDate = actionItem.endDate else { return }
        guard let dueDate = actionItem.dueDate else { return }
        guard let routines = actionItem.routines else { return }
        let endDateComponents = Calendar.current.dateComponents([.year, .month, .day], from: endDate)
        let newEndDateComponents = DateComponents(year: endDateComponents.year, month: endDateComponents.month, day: endDateComponents.day, hour: 24)
        guard let newEndDate = Calendar.current.date(from: newEndDateComponents) else { return }
        let dueDateComponents = Calendar.current.dateComponents([.year, .month, .day], from: dueDate)
        let newDueDateComponents = DateComponents(year: dueDateComponents.year, month: dueDateComponents.month, day: dueDateComponents.day, hour: 00)
        guard let newDueDate = Calendar.current.date(from: newDueDateComponents) else { return }

        var date = endDate
        var count = 1
        var nextActionId: String?
        var beforeActionId: String?

        // 마지막 날짜부터 추가하는 형식으로 진행!
        // 직전까지 추가하고나서, 당일 추가건 추가

        while date >= newDueDate + 86400 { // 해당일까지 도달하면 멈춤
            routines.forEach {
                if Utils.dateToE(date) == $0 { // 월요일, 화요일 등 해당하는 날인지 체크!!
                    print("\(count) : \(Utils.dateToE(date)), \(date)")
                    count += 1 // 몇개 추가되었는지 개발용 디버그
                    let action = ActionItem(id: UUID().uuidString,
                                            emoji: actionItem.emoji,
                                            title: actionItem.title,
                                            dueTime: actionItem.dueTime,
                                            dueDate: date,
                                            isDone: actionItem.isDone,
                                            isAlarmOn: actionItem.isAlarmOn,
                                            routines: actionItem.routines,
                                            endDate: actionItem.endDate,
                                            tags: actionItem.tags,
                                            color: actionItem.color,
                                            createdTime: Date.now.description,
                                            unit: actionItem.unit,
                                            category: actionItem.category,
                                            rNextAction: nextActionId,
                                            rBeforeAction: nil)
                    CoreDataManager.shared.insertAction(action)
                    if let nextId = nextActionId  {
                        beforeActionId = action.id
                        CoreDataManager.shared.editAction(nextId, rBeforeAction: beforeActionId) // 링크 이어주기
                    }
                    nextActionId = action.id
                }
            }
            date -= 86400  // 하루씩 for문 돔
        }
        
        if extendingOption {
            // 마지막 날 연장인 경우
            let action = ActionItem(id: actionItem.id,
                                    emoji: actionItem.emoji,
                                    title: actionItem.title,
                                    dueTime: actionItem.dueTime,
                                    dueDate: date,
                                    isDone: actionItem.isDone,
                                    isAlarmOn: actionItem.isAlarmOn,
                                    routines: actionItem.routines,
                                    endDate: actionItem.endDate,
                                    tags: actionItem.tags,
                                    color: actionItem.color,
                                    createdTime: actionItem.createdTime,
                                    unit: actionItem.unit,
                                    category: actionItem.category,
                                    rNextAction: nextActionId,
                                    rBeforeAction: actionItem.rBeforeAction)
            CoreDataManager.shared.editAction(action)
            guard let nextId = nextActionId else { return }
            CoreDataManager.shared.editAction(nextId, rBeforeAction: action.id) // 마지막 -1 실천은 before가 없음
        } else {
            // 일반적인 추가 상황
            // 해당일 저장.
            let action = ActionItem(id: UUID().uuidString,
                                    emoji: actionItem.emoji,
                                    title: actionItem.title,
                                    dueTime: actionItem.dueTime,
                                    dueDate: date,
                                    isDone: actionItem.isDone,
                                    isAlarmOn: actionItem.isAlarmOn,
                                    routines: actionItem.routines,
                                    endDate: actionItem.endDate,
                                    tags: actionItem.tags,
                                    color: actionItem.color,
                                    createdTime: Date.now.description,
                                    unit: actionItem.unit,
                                    category: actionItem.category,
                                    rNextAction: nextActionId,
                                    rBeforeAction: actionItem.rBeforeAction)
            CoreDataManager.shared.insertAction(action)
            guard let nextId = nextActionId else { return }
            CoreDataManager.shared.editAction(nextId, rBeforeAction: action.id)
        }
    }
    
    
    func deleteAction() {
        switch self.actionEditorMode {
        case let .edit(action):
            // 루틴 중간에 삭제가 되는 경우, 앞 뒤를 이어줘야함.
            if let beforeAction = action.rBeforeAction, let nextAction = action.rNextAction {
                if !beforeAction.isEmpty && !nextAction.isEmpty {
                    CoreDataManager.shared.editAction(beforeAction, rNextAction: nextAction)
                    CoreDataManager.shared.editAction(nextAction, rBeforeAction: beforeAction)
                }
            } else if let beforeAction = action.rBeforeAction { // 루틴의 마지막을 지우는경우
                if !beforeAction.isEmpty {
                    CoreDataManager.shared.editAction(beforeAction, rNextAction: nil)
                    self.changeRoutineEndDate(id: beforeAction)
                }
            }
            CoreDataManager.shared.delete(action)
        default:
            break
        }
    }
    
    // 반복 액션 제거
    func deleteRoutines() {
        switch actionEditorMode {
        case .new:
            print("error new인데 루틴 제거")
            break
        case .edit(let action):
            var actionId = action.id

            if let beforeId = action.rBeforeAction {
                CoreDataManager.shared.editAction(beforeId, rNextAction: nil)
                self.changeRoutineEndDate(id: beforeId)
                // 중간부터 제거하는거라면 이전 링크 제거
            }
            while actionId != nil {
                guard let Id = actionId else { return }
                guard let action = CoreDataManager.shared.fetchAction(id: Id) else { return }
                actionId = action.rNextAction
                CoreDataManager.shared.delete(action)
            }
        }
    }
    
    func changeRoutineEndDate(id: String?) {
        guard let id = id else { return }
        if let beforeActionDueDate = CoreDataManager.shared.fetchAction(id: id)?.dueDate {
            var actionId = id
            while actionId != nil {
                CoreDataManager.shared.editAction(actionId, endDate: beforeActionDueDate)
                guard let action = CoreDataManager.shared.fetchAction(id: actionId) else { return }
                guard let beforeAction = action.rBeforeAction else { return }
                actionId = beforeAction
            }
        }
    }

    
    @objc func routinesSelectNotification(_ notification: Notification) {
        guard let routines = notification.object as? [String] else { return }
        self.selectedRoutines = routines
    }
    
    func dueDateChanged(_ date: Date) {
        self.selectedDueDate = date
    }
}

protocol AddActionViewModelType {
    
}



/*
 private func checkRoutineActions(_ actionItem: ActionItem) {
     guard let endDate = actionItem.endDate else { return }
     guard let dueDate = actionItem.dueDate else { return }
     guard let routines = actionItem.routines else { return }
     let endDateComponents = Calendar.current.dateComponents([.year, .month, .day], from: endDate)
     let newEndDateComponents = DateComponents(year: endDateComponents.year, month: endDateComponents.month, day: endDateComponents.day, hour: 24)
     guard let newEndDate = Calendar.current.date(from: newEndDateComponents) else { return }
     let dueDateComponents = Calendar.current.dateComponents([.year, .month, .day], from: dueDate)
     let newDueDateComponents = DateComponents(year: dueDateComponents.year, month: dueDateComponents.month, day: dueDateComponents.day, hour: 00)
     guard let newDueDate = Calendar.current.date(from: newDueDateComponents) else { return }

     let request: NSFetchRequest<Action> = Action.fetchRequest()
     request.predicate = NSPredicate(format: "dueDate >= %@ && dueDate <= %@", newDueDate as CVarArg ,newEndDate as CVarArg)
     let allActions = CoreDataManager.shared.fetch(request: request)
     var date = dueDate
     
     var count = 1
     while date <= newEndDate {
         routines.forEach {
             if Utils.dateToE(date) == $0 {
                 print("\(count) : \(Utils.dateToE(date)), \(date)")
                 count += 1
                 var isExist = false
                 allActions.forEach {
                     guard let due = $0.dueDate else { return }
                     if $0.emoji == actionItem.emoji &&
                         $0.title == actionItem.title &&
                         due >= date &&
                         due <= date + 86400 {
                         isExist = true
                     }
                 }
                 if !isExist {
                     let action = ActionItem(id: UUID().uuidString,
                                             emoji: actionItem.emoji,
                                             title: actionItem.title,
                                             dueTime: actionItem.dueTime,
                                             dueDate: date,
                                             isDone: actionItem.isDone,
                                             isAlarmOn: actionItem.isAlarmOn,
                                             routines: actionItem.routines,
                                             startDate: nil,
                                             endDate: actionItem.endDate,
                                             tags: actionItem.tags,
                                             color: actionItem.color,
                                             createdTime: Date.now.description,
                                             unit: actionItem.unit,
                                             category: actionItem.category)
                     CoreDataManager.shared.insertAction(action)
                 }
             }
         }
         date += 86400
     }
 }

 */
