//
//  AddActionViewModel.swift
//  smallactions
//
//  Created by Jo on 2022/12/27.
//

import Foundation
import CoreData
import SearchTextField
import RxSwift
import RxRelay

/*
루틴 관련 테스트케이스
 루틴 생성
 - 중간 삭제 후  이전-다음 연결되는지 확인
 - 루틴의 마지막날에 연장되는지 확인
 - 루틴 줄이기 확인
 - 루틴 변경 확인
 */

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
    
    var disposeBag = DisposeBag()
    var delegate: AddActionDelegate?
    var action: Action?
    
    var actionEditorMode: ActionEditorMode = .new
    var rxSelectedDueDate = BehaviorRelay<Date>(value: .now)
    var rxSelectedDueTime = BehaviorRelay<Date>(value: .now)
    var rxSelectedEndDate = BehaviorRelay<Date>(value: .now)
    var rxSelectedRoutines = BehaviorRelay<[String]>(value: [])
        
    func configureData() {
        registerListeners()
        switch actionEditorMode {
        case let .edit(action):
            configureTodayContents(action)
        default:
            _ = rxSelectedDueDate.map {
                $0 + 86400 * 30
            }.bind(to: rxSelectedEndDate)
                .disposed(by: disposeBag)
            break
        }
    }
    
    private func configureTodayContents(_ action: Action) {
        delegate?.valueChanged(
            [ActionData.title: action.title,
             ActionData.emoji: action.emoji,
             ActionData.alarmSwitch: action.isAlarmOn,
             ActionData.isDone: action.isDone,
             ActionData.routines: action.routines]
        )
        
        _ = Observable.just(action.dueDate ?? rxSelectedDueDate.value)
            .bind(to: rxSelectedDueDate)
            .disposed(by: disposeBag)
        
        if let dueTime = action.dueTime {
            _ = Observable.just(dueTime).bind(to: rxSelectedDueTime)
        }
        if let endDate = action.endDate {
            _ = Observable.just(endDate).bind(to: rxSelectedEndDate)
        }
        if let routines = action.routines {
          _ = Observable.just(routines).bind(to: rxSelectedRoutines)
        }
    }
    
    private func registerListeners() {
        
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
            let action = ActionItem(id: id,
                                    emoji: emoji,
                                    title: title,
                                    dueTime: dueTime,
                                    dueDate: dueDate,
                                    isDone: isDone,
                                    isAlarmOn: isAlarmOn,
                                    routines: routines ?? nil,
                                    endDate: endDate,
                                    tags: [],
                                    color: nil,
                                    unit: nil,
                                    category: nil,
                                    rNextAction: action.rNextAction, // 원래 값을 들고감.
                                    rBeforeAction: action.rBeforeAction)
            if let routines = routines {
                if !routines.isEmpty {
                    // 루틴 마지막놈으로 연장하고자할때 변경할 때 (1월 30일 -> 2월 28일)
                    self.routineInsertActions(action, extendingOption: true)
                } else {
                    CoreDataManager.shared.editAction(action)
                    unlink(action)
                }
            } else {
                CoreDataManager.shared.editAction(action)
                unlink(action)
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
    
    private func unlink(_ action: ActionItem) {
        if let nextId = action.rNextAction  {
            if let beforeId = action.rBeforeAction {
                _ = CoreDataManager.shared.editAction(beforeId, rNextAction: nextId)
                _ = CoreDataManager.shared.editAction(nextId, rBeforeAction: beforeId)
                _ = CoreDataManager.shared.editAction(action.id, rNextAction: nil)
                _ = CoreDataManager.shared.editAction(action.id, rBeforeAction: nil)
            }
        } else if let beforeId = action.rBeforeAction {
            _ = CoreDataManager.shared.editAction(beforeId, rNextAction: nil)
            _ = CoreDataManager.shared.editAction(action.id, rBeforeAction: nil)
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
        case .edit(_):
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
        let newEndDateComponents = DateComponents(year: endDateComponents.year, month: endDateComponents.month, day: endDateComponents.day, hour: 23, minute: 59)
        guard let newEndDate = Calendar.current.date(from: newEndDateComponents) else { return }
        let dueDateComponents = Calendar.current.dateComponents([.year, .month, .day], from: dueDate)
        let newDueDateComponents = DateComponents(year: dueDateComponents.year, month: dueDateComponents.month, day: dueDateComponents.day, hour: 00, minute: 01)
        guard let newDueDate = Calendar.current.date(from: newDueDateComponents) else { return }

        var date = newEndDate
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
                                            isDone: false,
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
                        _ = CoreDataManager.shared.editAction(nextId, rBeforeAction: beforeActionId) // 링크 이어주기
                    }
                    nextActionId = action.id
                }
            }
            date -= 86400  // 하루씩 for문 돔
        }
        //TODO: 연장할때 앞에 전부다 enddate 바꿔야함
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
            _ = CoreDataManager.shared.editAction(nextId, rBeforeAction: action.id) // 마지막 -1 실천은 before가 없음
            self.changeRoutineEndDate(id: nextId)
        } else {
            // 일반적인 추가 상황
            // 해당일 저장.
            let action = ActionItem(id: UUID().uuidString,
                                    emoji: actionItem.emoji,
                                    title: actionItem.title,
                                    dueTime: actionItem.dueTime,
                                    dueDate: date,
                                    isDone: false,
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
            _ = CoreDataManager.shared.editAction(nextId, rBeforeAction: action.id)
        }
    }
    
    
    func deleteAction() {
        switch self.actionEditorMode {
        case let .edit(action):
            // 루틴 중간에 삭제가 되는 경우, 앞 뒤를 이어줘야함.
            if let beforeAction = action.rBeforeAction, let nextAction = action.rNextAction {
                if !beforeAction.isEmpty && !nextAction.isEmpty {
                    _ = CoreDataManager.shared.editAction(beforeAction, rNextAction: nextAction)
                    _ = CoreDataManager.shared.editAction(nextAction, rBeforeAction: beforeAction)
                }
            } else if let beforeAction = action.rBeforeAction { // 루틴의 마지막을 지우는경우
                if !beforeAction.isEmpty {
                    _ = CoreDataManager.shared.editAction(beforeAction, rNextAction: nil)
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
                _ = CoreDataManager.shared.editAction(beforeId, rNextAction: nil)
                // 중간부터 제거하는거라면 이전 링크 제거
                self.changeRoutineEndDate(id: beforeId)
            }
            while actionId != nil {
                guard let Id = actionId else { return }
                guard let action = CoreDataManager.shared.fetchAction(id: Id) else { return }
                actionId = action.rNextAction
                CoreDataManager.shared.delete(action)
            }
        }
    }
    
    //
    private func changeRoutineEndDate(id: String?) {
        guard let id = id else { return }
        let action = CoreDataManager.shared.fetchAction(id: id)
        
        var nextId: String?
        
        if let action = action { // 제일 마지막으로 이동시킨다.
            if action.rNextAction != nil {
                nextId = action.rNextAction
                while nextId != nil {
                    let nextAction = CoreDataManager.shared.fetchAction(id: nextId!)
                    if nextAction?.rNextAction != nil {
                        nextId = nextAction?.rNextAction
                    } else {
                        break
                    }
                }
            } else {
                nextId = id
            }
        }
        
        guard let lastId = nextId else { return } // 뒤에서부터 앞으로 오면서 변경해준다.
        if let beforeActionDueDate = CoreDataManager.shared.fetchAction(id: lastId)?.dueDate {
            var actionId = lastId
            while actionId != nil {
                _ = CoreDataManager.shared.editAction(actionId, endDate: beforeActionDueDate)
                guard let action = CoreDataManager.shared.fetchAction(id: actionId) else { return }
                guard let beforeAction = action.rBeforeAction else { return }
                actionId = beforeAction
            }
        }
    }

    
    @objc private func routinesSelectNotification(_ notification: Notification) {
        guard let routines = notification.object as? [String] else { return }
        _ = Observable.just(routines).bind(to: rxSelectedRoutines)
    }
    
    func getDBTitleArray() -> [String] {
        guard let allActions = CoreDataManager.shared.fetchAllAction() else { return [] }
        let actionStrings = allActions.map {
            return ($0.emoji ?? "") + " " + ($0.title ?? "")
        }.sorted(by: {
            return $0 < $1
        })
        let actionSet = Set(actionStrings) // 중복 제거
        let arr = Array(actionSet)
        return arr
    }
}

protocol AddActionViewModelType {
    var delegate: AddActionDelegate? { get set }
    var actionEditorMode: ActionEditorMode { get set }
    var rxSelectedDueDate: BehaviorRelay<Date> { get }
    var rxSelectedDueTime: BehaviorRelay<Date> { get }
    var rxSelectedEndDate: BehaviorRelay<Date> { get }
    
    func configureData()
    func existNextAction() -> Bool
    func saveAction(title: String,
                    emoji: String?,
                    isDone: Bool?,
                    isAlarmOn: Bool?,
                    dueDate: Date?,
                    dueTime: Date?,
                    routines: [String]?,
                    endDate: Date?)
    func saveRoutineActions(title: String,
                            emoji: String?,
                            isDone: Bool?,
                            isAlarmOn: Bool?,
                            dueDate: Date?,
                            dueTime: Date?,
                            routines: [String]?,
                            endDate: Date?)
    func deleteAction()
    func deleteRoutines()
    
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
