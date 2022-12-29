//
//  AddActionViewModel.swift
//  smallactions
//
//  Created by Jo on 2022/12/27.
//

import Foundation

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
            delegate?.valueChanged([ActionData.dueDate : selectedDueDate])
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
            break
        }
    }
    
    private func configureTodayContents(_ action: Action) {
        delegate?.valueChanged(
            [ActionData.title: action.title,
             ActionData.emoji: action.emoji,
             ActionData.alarmSwitch: action.isAlarmOn,
             ActionData.isDone: action.isDone]
        )

        self.selectedDueDate = action.dueDate ?? self.selectedDueDate
        self.selectedDueTime = action.dueTime ?? self.selectedDueTime
        self.selectedStartDate = action.startDate ?? self.selectedStartDate
        self.selectedEndDate = action.endDate ?? self.selectedEndDate
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
                    startDate: Date,
                    endDate: Date) {
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
                                        routines: [],
                                        startDate: startDate,
                                        endDate: endDate,
                                        tags: [],
                                        color: nil,
                                        unit: nil,
                                        category: nil)
            CoreDataManager.shared.editAction(actionItem)
        case .new:
            let action = ActionItem(id: UUID().uuidString,
                                    emoji: emoji,
                                    title: title,
                                    dueTime: dueTime,
                                    dueDate: dueDate,
                                    isDone: isDone,
                                    isAlarmOn: isAlarmOn,
                                    routines: [],
                                    startDate: startDate,
                                    endDate: endDate,
                                    tags: [],
                                    color: nil,
                                    createdTime: Date.now.description,
                                    unit: nil,
                                    category: nil)
            
            CoreDataManager.shared.insertAction(action)
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
}

protocol AddActionViewModelType {
    
}
