//
//  CoreDataManager.swift
//  smallactions
//
//  Created by Jo on 2022/12/22.
//

import Foundation
import CoreData
import UIKit

class CoreDataManager {
    
    static var shared: CoreDataManager = CoreDataManager()
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "SmallActions")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    var context: NSManagedObjectContext {
        return self.persistentContainer.viewContext
    }
    
    func fetch<T: NSManagedObject>(request: NSFetchRequest<T>) -> [T] {
        do {
            let fetchResult = try self.context.fetch(request)
            return fetchResult
        } catch {
            print(error.localizedDescription)
            return []
        }
    }
    
    // 신규 실천 추가
    @discardableResult
    func insertAction(_ action: ActionItem) -> Bool {
        let entity = NSEntityDescription.entity(forEntityName: "Action", in: self.context)
        
        if let entity = entity {
            let managedObject = NSManagedObject(entity: entity, insertInto: self.context)
            managedObject.setValue(action.category, forKey: "category")
            managedObject.setValue(action.color, forKey: "color")
            managedObject.setValue(action.createdTime, forKey: "createdTime")
            managedObject.setValue(action.emoji, forKey: "emoji")
            managedObject.setValue(action.endDate, forKey: "endDate")
            managedObject.setValue(action.id, forKey: "id")
            managedObject.setValue(action.isAlarmOn, forKey: "isAlarmOn")
            managedObject.setValue(action.routines, forKey: "routines")
            managedObject.setValue(action.tags, forKey: "tags")
            managedObject.setValue(action.dueTime, forKey: "dueTime")
            managedObject.setValue(action.dueDate, forKey: "dueDate")
            managedObject.setValue(action.title, forKey: "title")
            managedObject.setValue(action.unit, forKey: "unit")
            managedObject.setValue(action.isDone, forKey: "isDone")
            managedObject.setValue(action.rNextAction, forKey: "rNextAction")
            managedObject.setValue(action.rBeforeAction, forKey: "rBeforeAction")

            do {
                try self.context.save()
                NotificationCenter.default.post(
                    name: NSNotification.Name("changeAction"),
                    object: nil,
                    userInfo: nil)

                return true
            } catch {
                print(error.localizedDescription)
                return false
            }
        } else {
            return false
        }
    }
    
    // 실천 변경
    @discardableResult
    func editAction(_ action: ActionItem) -> Bool {
        let request: NSFetchRequest<Action> = Action.fetchRequest()
        request.predicate = NSPredicate(format: "id = %@", action.id)
        let result = fetch(request: request)
        if let managedObject = result.first {
            managedObject.setValue(action.category, forKey: "category")
            managedObject.setValue(action.color, forKey: "color")
            managedObject.setValue(action.createdTime, forKey: "createdTime")
            managedObject.setValue(action.emoji, forKey: "emoji")
            managedObject.setValue(action.endDate, forKey: "endDate")
            managedObject.setValue(action.isAlarmOn, forKey: "isAlarmOn")
            managedObject.setValue(action.routines, forKey: "routines")
            managedObject.setValue(action.tags, forKey: "tags")
            managedObject.setValue(action.dueTime, forKey: "dueTime")
            managedObject.setValue(action.dueDate, forKey: "dueDate")
            managedObject.setValue(action.title, forKey: "title")
            managedObject.setValue(action.unit, forKey: "unit")
            managedObject.setValue(action.isDone, forKey: "isDone")
            managedObject.setValue(action.rNextAction, forKey: "rNextAction")
            managedObject.setValue(action.rBeforeAction, forKey: "rBeforeAction")

            do {
                try self.context.save()
                NotificationCenter.default.post(
                    name: NSNotification.Name("changeAction"),
                    object: nil,
                    userInfo: nil)

                return true
            } catch {
                print(error.localizedDescription)
                return false
            }

        } else {
            print("no id")
            return false
        }
    }
    
    func fetchAction(id: String) -> Action? {
        let request: NSFetchRequest<Action> = Action.fetchRequest()
        request.predicate = NSPredicate(format: "id = %@", id)
        return fetch(request: request).first
    }
    
    func fetchAllAction() -> [Action]? {
        let request: NSFetchRequest<Action> = Action.fetchRequest()
        return CoreDataManager.shared.fetch(request: request)
    }
    
    // 실천 여부 변경
    func editAction(_ id: String, isDone: Bool) -> Bool {
        let request: NSFetchRequest<Action> = Action.fetchRequest()
        request.predicate = NSPredicate(format: "id = %@", id)
        let result = fetch(request: request)
        if let managedObject = result.first {
            managedObject.setValue(isDone, forKey: "isDone")
            
            do {
                try self.context.save()
                NotificationCenter.default.post(
                    name: NSNotification.Name("changeAction"),
                    object: nil,
                    userInfo: nil)
                if isDone {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("confetti"),
                        object: nil,
                        userInfo: nil)
                }
                return true
            } catch {
                print(error.localizedDescription)
                return false
            }

        } else {
            return false
        }
    }
    
    // 실천 여부 변경
    func editAction(_ id: String, endDate: Date) -> Bool {
        let request: NSFetchRequest<Action> = Action.fetchRequest()
        request.predicate = NSPredicate(format: "id = %@", id)
        let result = fetch(request: request)
        if let managedObject = result.first {
            managedObject.setValue(endDate, forKey: "endDate")
            
            do {
                try self.context.save()
                NotificationCenter.default.post(
                    name: NSNotification.Name("changeAction"),
                    object: nil,
                    userInfo: nil)

                return true
            } catch {
                print(error.localizedDescription)
                return false
            }

        } else {
            return false
        }
    }
    
    func editAction(_ id: String, rBeforeAction: String? = "") -> Bool {
        let request: NSFetchRequest<Action> = Action.fetchRequest()
        request.predicate = NSPredicate(format: "id = %@", id)
        let result = fetch(request: request)
        if let managedObject = result.first {
            managedObject.setValue(rBeforeAction, forKey: "rBeforeAction")
            do {
                try self.context.save()
                NotificationCenter.default.post(
                    name: NSNotification.Name("changeAction"),
                    object: nil,
                    userInfo: nil)
                return true
            } catch {
                print(error.localizedDescription)
                return false
            }

        } else {
            return false
        }
    }
    
    func editAction(_ id: String, rNextAction: String? = "") -> Bool {
        let request: NSFetchRequest<Action> = Action.fetchRequest()
        request.predicate = NSPredicate(format: "id = %@", id)
        let result = fetch(request: request)
        if let managedObject = result.first {
            managedObject.setValue(rNextAction, forKey: "rNextAction")
            do {
                try self.context.save()
                NotificationCenter.default.post(
                    name: NSNotification.Name("changeAction"),
                    object: nil,
                    userInfo: nil)
                return true
            } catch {
                print(error.localizedDescription)
                return false
            }

        } else {
            return false
        }
    }
    
    
    func count<T: NSManagedObject>(request: NSFetchRequest<T>) -> Int? {
        do {
            let count = try self.context.count(for: request)
            return count
        } catch {
            return nil
        }
    }
    
    @discardableResult
    func delete(_ object: NSManagedObject) -> Bool {
        self.context.delete(object)
        do {
            try context.save()
            NotificationCenter.default.post(
                name: NSNotification.Name("changeAction"),
                object: nil,
                userInfo: nil)

            return true
        } catch {
            return false
        }
    }
    
    @discardableResult
    func deleteAll<T: NSManagedObject>(request: NSFetchRequest<T>) -> Bool {
        let request: NSFetchRequest<NSFetchRequestResult> = T.fetchRequest()
        let delete = NSBatchDeleteRequest(fetchRequest: request)
        do {
            try self.context.execute(delete)
            return true
        } catch {
            return false
        }
    }
}


