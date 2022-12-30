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
    case startDate = "startDate"
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
            self.selectedStartDate = self.selectedDueDate
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
    
    private var selectedStartDate: Date? {
        didSet {
            if let startDate = selectedStartDate {
                delegate?.valueChanged(
                    [ActionData.startDate: startDate]
                )
            }
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
            self.selectedStartDate = self.selectedDueDate
            self.selectedEndDate = self.selectedDueDate + 86400 * 7
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
        self.selectedStartDate = action.startDate ?? self.selectedStartDate
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
                    emoji: String?,
                    isDone: Bool,
                    isAlarmOn: Bool,
                    dueDate: Date,
                    dueTime: Date,
                    routines: [String],
                    startDate: Date?,
                    endDate: Date?) {
        switch self.actionEditorMode {
        case let .edit(action):
            guard let id = action.id else { return }
            let actionItem = ActionItem(id: id,
                                        emoji: emoji,
                                        title: title,
                                        dueTime: dueTime,
                                        dueDate: dueDate,
                                        isDone: isDone,
                                        isAlarmOn: isAlarmOn,
                                        routines: routines,
                                        startDate: startDate,
                                        endDate: endDate,
                                        tags: [],
                                        color: nil,
                                        unit: nil,
                                        category: nil)
            CoreDataManager.shared.editAction(actionItem)
            if !routines.isEmpty {
                self.checkRoutineActions(actionItem)
            }
        case .new:
            let action = ActionItem(id: UUID().uuidString,
                                    emoji: emoji,
                                    title: title,
                                    dueTime: dueTime,
                                    dueDate: dueDate,
                                    isDone: isDone,
                                    isAlarmOn: isAlarmOn,
                                    routines: routines,
                                    startDate: startDate,
                                    endDate: endDate,
                                    tags: [],
                                    color: nil,
                                    createdTime: Date.now.description,
                                    unit: nil,
                                    category: nil)
            CoreDataManager.shared.insertAction(action)
            if !routines.isEmpty {
                self.checkRoutineActions(action)
            }
        }

    }
    
    private func checkRoutineActions(_ actionItem: ActionItem) {
        guard let endDate = actionItem.endDate else { return }
        guard let startDate = actionItem.startDate else { return }
        guard let routines = actionItem.routines else { return }
        let endDateComponents = Calendar.current.dateComponents([.year, .month, .day], from: endDate)
        let newEndDateComponents = DateComponents(year: endDateComponents.year, month: endDateComponents.month, day: endDateComponents.day, hour: 24)
        guard let newEndDate = Calendar.current.date(from: newEndDateComponents) else { return }
        let startDateComponents = Calendar.current.dateComponents([.year, .month, .day], from: startDate)
        let newStartDateComponents = DateComponents(year: startDateComponents.year, month: startDateComponents.month, day: startDateComponents.day, hour: 00)
        guard let newStartDate = Calendar.current.date(from: newStartDateComponents) else { return }

        let request: NSFetchRequest<Action> = Action.fetchRequest()
        request.predicate = NSPredicate(format: "dueDate >= %@ && dueDate <= %@", newStartDate as CVarArg ,newEndDate as CVarArg)
        let allActions = CoreDataManager.shared.fetch(request: request)
        var date = startDate
        
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
                                                routines: nil,
                                                startDate: nil,
                                                endDate: nil,
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

    
    func deleteAction() {
        switch self.actionEditorMode {
        case let .edit(action):
            CoreDataManager.shared.delete(action)
        default:
            break
        }
    }
    
    @objc func routinesSelectNotification(_ notification: Notification) {
        guard let routines = notification.object as? [String] else { return }
        self.selectedRoutines = routines
//        self.routinesLabel.text = routines.map {
//            return String($0.first!)
//        }.joined(separator: ", ")
    }
    
    func dueDateChanged(_ date: Date) {
        self.selectedDueDate = date
    }
}

protocol AddActionViewModelType {
    
}
