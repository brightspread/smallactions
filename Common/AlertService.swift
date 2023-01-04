//
//  AlertService.swift
//  smallactions
//
//  Created by Jo on 2022/12/24.
//

import UIKit
struct AlertService {
    
    static func presentBarButtonAlert(alert: UIAlertController, vc: UIViewController, completion: (() -> Void)? = nil, sender: Any) {
        // barbutton item alert
        if UIDevice.current.userInterfaceIdiom == .pad {
            //디바이스 타입이 iPad일때
            if let popoverController = alert.popoverPresentationController {
                // ActionSheet가 표현되는 위치를 저장해줍니다.
                popoverController.barButtonItem = sender as? UIBarButtonItem
                vc.present(alert, animated: true, completion: completion)
            } else {
                vc.present(alert, animated: true, completion: completion)
            }
        } else {
            vc.present(alert, animated: true, completion: completion)
        }
    }
    
    static func presentAlert(alert: UIAlertController, vc: UIViewController, completion: (() -> Void)? = nil) {
//        alert.textFields?.forEach { // Alert 내 Textfield 테두리 이상한거 잡기
//            $0.superview?.backgroundColor = ThemeHelper.themeMainColor
//        }
        
        // normal alert
        if UIDevice.current.userInterfaceIdiom == .pad {
            //디바이스 타입이 iPad일때
            if let popoverController = alert.popoverPresentationController {
                // ActionSheet가 표현되는 위치를 저장해줍니다.
                popoverController.sourceView = vc.view
                popoverController.sourceRect = CGRect(x: vc.view.bounds.midX, y: vc.view.bounds.midY, width: 0, height: 0)
                popoverController.permittedArrowDirections = []
                vc.present(alert, animated: true, completion: completion)
            } else {
                vc.present(alert, animated: true, completion: completion)
            }
        } else {
            vc.present(alert, animated: true, completion: completion)
        }
    }
    
    
    static func buildAlertControllerWithApplyTheme(title: String?, message: String?, preferredStyle: UIAlertController.Style) -> UIAlertController {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: preferredStyle)
//        alert.view.subviews.first?.subviews.first?.subviews.first?.backgroundColor = ThemeHelper.themePopupColor
//        alert.view.tintColor = ThemeHelper.actionAS()
        if title != nil {
//            alert.setValue(ThemeHelper.attributedTextAS(title!), forKey: "attributedMessage")
            alert.title = title
        }
        if message != nil {
//            alert.setValue(ThemeHelper.attributedTextAS(message!), forKey: "attributedMessage")
            alert.message = message
        }
        return alert
    }
    
    
    static func datePickerAlert() -> UIAlertController {
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.locale = NSLocale(localeIdentifier: "ko_KO") as Locale // datePicker의 default 값이 영어이기 때문에 한글로 바꿔줘야한다. 그래서 이 방식으로 변경할 수 있다.
        
        let alert = buildAlertControllerWithApplyTheme(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.view.addSubview(datePicker)
        alert.addAction(UIAlertAction(title: "선택 완료", style: .default, handler: { action in
            NotificationCenter.default.post(
                name: NSNotification.Name("dateSelect"),
                object: datePicker.date,
                userInfo: nil)
        }))
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        
        let height : NSLayoutConstraint = NSLayoutConstraint(item: alert.view, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.1, constant: 300)
        alert.view.addConstraint(height)
            
        return alert
    }
    
    static func timePickerAlert() -> UIAlertController {
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .time
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.locale = NSLocale(localeIdentifier: "ko_KO") as Locale // datePicker의 default 값이 영어이기 때문에 한글로 바꿔줘야한다. 그래서 이 방식으로 변경할 수 있다.
        
        let alert = buildAlertControllerWithApplyTheme(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.view.addSubview(datePicker)
        alert.addAction(UIAlertAction(title: "선택 완료", style: .default, handler: { action in
            NotificationCenter.default.post(
                name: NSNotification.Name("dueTimeSelect"),
                object: datePicker.date,
                userInfo: nil)
        }))
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        
        let height : NSLayoutConstraint = NSLayoutConstraint(item: alert.view, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.1, constant: 330)
        alert.view.addConstraint(height)
            
        return alert
    }
    
    static func routineDayAlert(vc: UIViewController, routines: [String]) -> UIAlertController {
        let checkAlert = buildAlertControllerWithApplyTheme(title: nil, message: nil, preferredStyle: .actionSheet)
        let contentVc = AlertTableViewController()
        contentVc.delegate = vc
        contentVc.selectedRoutines = routines
        let okAction = UIAlertAction(title: "확인", style: .default) { (_) in
            NotificationCenter.default.post(
                name: NSNotification.Name("routinesSelect"),
                object: contentVc.selectedRoutines,
                userInfo: nil)
        }
        let cancelAction = UIAlertAction(title: "취소", style: .destructive)
        checkAlert.addAction(okAction)
        checkAlert.addAction(cancelAction)
        checkAlert.setValue(contentVc, forKey: "contentViewController")
        
        return checkAlert
    }
    
    static func saveRoutineActionAlert(thisOnlyHandler: @escaping (UIAlertAction) -> Void, afterAllHandler: @escaping (UIAlertAction) -> Void) -> UIAlertController {
        let alert = buildAlertControllerWithApplyTheme(title: nil, message: "반복되는 실천입니다.", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "취소" , style: .destructive) { (UIAlertAction) in
            alert.dismiss(animated: true, completion: nil)
        }
        let thisOnlyAction = UIAlertAction(title: "이 실천만 저장", style: .destructive, handler: thisOnlyHandler)
        alert.addAction(thisOnlyAction)
        let afterAllAction = UIAlertAction(title: "이후 실천에 대해 저장", style: .destructive, handler: afterAllHandler)
        alert.addAction(afterAllAction)
        alert.addAction(cancelAction)
        return alert
    }
    
    static func deleteRoutineActionAlert(thisOnlyHandler: @escaping (UIAlertAction) -> Void, afterAllHandler: @escaping (UIAlertAction) -> Void) -> UIAlertController {
        let alert = buildAlertControllerWithApplyTheme(title: nil, message: "이 실천을 삭제하시겠습니까? 반복되는 실천입니다.", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "취소" , style: UIAlertAction.Style.cancel) { (UIAlertAction) in
            alert.dismiss(animated: true, completion: nil)
        }
        let thisOnlyAction = UIAlertAction(title: "이 실천만 삭제", style: .destructive, handler: thisOnlyHandler)
        alert.addAction(thisOnlyAction)
        let afterAllAction = UIAlertAction(title: "이후 모든 이벤트 삭제", style: .destructive, handler: afterAllHandler)
        alert.addAction(afterAllAction)
        alert.addAction(cancelAction)
        return alert
    }
    
    static func deleteAllDataActionAlert(deleteActionHandler: @escaping (UIAlertAction) -> Void) -> UIAlertController {
        let alert = buildAlertControllerWithApplyTheme(title: nil, message: "전체 데이터를 삭제하시겠습니까? 되돌릴 수 없습니다.", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "취소" , style: UIAlertAction.Style.cancel) { (UIAlertAction) in
            alert.dismiss(animated: true, completion: nil)
        }
        let deleteAction = UIAlertAction(title: "모든 데이터 삭제", style: .destructive, handler: deleteActionHandler)
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        return alert
    }
    
    static func deleteAllDataRetryActionAlert(deleteActionHandler: @escaping (UIAlertAction) -> Void) -> UIAlertController {
        let alert = buildAlertControllerWithApplyTheme(title: nil, message: "정말로 전체 데이터를 삭제합니까?", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "취소" , style: UIAlertAction.Style.cancel) { (UIAlertAction) in
            alert.dismiss(animated: true, completion: nil)
        }
        let deleteAction = UIAlertAction(title: "모든 데이터 삭제", style: .destructive, handler: deleteActionHandler)
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        return alert
    }
    
    static func noMailAlert() -> UIAlertController {
        let alert = UIAlertController(title: nil, message: "메일 설정이 되어있지 않습니다.\nbrightspread.jo@gmail.com로 문의사항을 보내주세요.", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "확인", style: UIAlertAction.Style.default, handler: { _ in
            alert.dismiss(animated: true, completion: nil)
        })
        alert.addAction(okAction)
        return alert
    }
}
