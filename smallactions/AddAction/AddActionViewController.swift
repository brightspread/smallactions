//
//  AddActionViewController.swift
//  smallactions
//
//  Created by Jo on 2022/12/18.
//

import UIKit
import SearchTextField
import RxSwift
import RxCocoa

class AddActionViewController: UIViewController {
    
    var disposeBag = DisposeBag()
    var viewModel = AddActionViewModel()

    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var titleTextField: SearchTextField!
    @IBOutlet weak var emojiTextField: EmojiTextField!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var alarmSwitch: UISwitch!
    @IBOutlet weak var routinesLabel: UILabel!
    @IBOutlet weak var tagsLabel: UILabel!
    @IBOutlet weak var deleteView: RoundedCornerView!

    @IBOutlet weak var dueDatePicker: UIDatePicker!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var timeDatePicker: UIDatePicker!
    @IBOutlet weak var dueTimeLabel: UILabel!
    @IBOutlet weak var endDateView: UIView!
    @IBOutlet weak var endDatePicker: UIDatePicker!
    @IBOutlet weak var endDateLabel: UILabel!

    
    private var selectedRoutines: [String] = []
    
    private lazy var routinesTapGesutre = UITapGestureRecognizer(target: self, action: #selector(routinesTouched))
    private lazy var tagsTapGesutre = UITapGestureRecognizer(target: self, action: #selector(tagsTouched))
    private lazy var deleteTapGesutre = UITapGestureRecognizer(target: self, action: #selector(deleteViewTouched))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initViewModel()
        configureTextField()
        configureContents()
        registerTouchHandler()
    }
    
    private func initViewModel() {
        viewModel.delegate = self
        viewModel.configureData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    private func configureContents() {
        // viewmodel binding
        viewModel.rxSelectedDueTime
            .subscribe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                self?.timeDatePicker.date = $0
                self?.dueTimeLabel.text = Utils.ampmTime($0) + " >"
            }).disposed(by: disposeBag)
        
        viewModel.rxSelectedDueDate
            .subscribe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                self?.dueDatePicker.date = $0
                self?.dateLabel.text = Utils.monthDateDay($0) + " >"
            }).disposed(by: disposeBag)
        
        viewModel.rxSelectedEndDate
            .subscribe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                self?.endDateLabel.text = Utils.monthDateDay($0) + " >"
                self?.endDatePicker.date = $0
            }).disposed(by: disposeBag)

        _ = viewModel.rxSelectedRoutines
            .asDriver(onErrorJustReturn: [])
            .map {
                $0.isEmpty ? "없음 >" : $0.map {
                    return String($0.first!)
                }.joined(separator: ", ") + " >"
            }
            .drive(routinesLabel.rx.text)
            .disposed(by: disposeBag)
            
            _ = viewModel.rxSelectedRoutines
            .subscribe(onNext: { [weak self] in
                self?.selectedRoutines = $0
                self?.endDateView.isHidden = $0.isEmpty
            })
            .disposed(by: disposeBag)
        
        
        // Picker binding
        timeDatePicker.rx.value
            .asDriver(onErrorJustReturn: .now)
            .map{ Utils.ampmTime($0) }
            .drive(dueTimeLabel.rx.text)
            .disposed(by: disposeBag)
        
        dueDatePicker.rx.value
            .bind(to: viewModel.rxSelectedDueDate)
            .disposed(by: disposeBag)
        
        dueDatePicker.rx.value
            .asDriver(onErrorJustReturn: .now)
            .map { Utils.monthDateDay($0) + " >" }
            .drive(dateLabel.rx.text)
            .disposed(by: disposeBag)
        
        endDatePicker.rx.value
            .asDriver(onErrorJustReturn: .now)
            .map{ Utils.monthDateDay($0) + " >" }
            .drive(endDateLabel.rx.text)
            .disposed(by: disposeBag)
        
        self.emojiTextField.delegate = self
        switch self.viewModel.actionEditorMode {
        case .edit(_):
            self.deleteView.isHidden = false
        default:
            self.deleteView.isHidden = true
            break
        }
        self.validateInputField()
    }
    
    private func configureTextField() {
        self.titleTextField.addTarget(self, action: #selector(titleTextFieldDidChnage(_:)), for: .editingChanged)
        self.titleTextField.filterStrings(self.viewModel.getDBTitleArray())
        self.titleTextField.theme.cellHeight = 44

        self.titleTextField.theme.font = UIFont(name: "AppleSDGothicNeo-Light", size: 18)!
        self.titleTextField.itemSelectionHandler = {item, itemPosition in
            let title = item[itemPosition].title
            if let first = title.first {
                self.emojiTextField.text = first.isEmoji ? String(first) : ""
                self.titleTextField.text = first.isEmoji ? String(title.dropFirst().dropFirst()) : String(title.dropFirst())
            }
        }
    }

    private func registerTouchHandler() {
        self.routinesLabel.addGestureRecognizer(routinesTapGesutre)
        self.tagsLabel.addGestureRecognizer(tagsTapGesutre)
        self.deleteView.addGestureRecognizer(deleteTapGesutre)
    }

    
    private func unregisterTouchHandler() {
        self.routinesLabel.removeGestureRecognizer(routinesTapGesutre)
        self.tagsLabel.removeGestureRecognizer(tagsTapGesutre)
        self.deleteView.removeGestureRecognizer(deleteTapGesutre)
    }

    @objc private func titleTextFieldDidChnage(_ textField: UITextField) {
        self.validateInputField()
    }
    
    private func validateInputField() {
        self.saveButton.isEnabled = !(self.titleTextField.text?.isEmpty ?? true)
    }
    
    // #MARK: Touch Handlers
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.emojiTextField.resignFirstResponder()
        self.titleTextField.resignFirstResponder()
    }
    
    @IBAction func saveButtonTouched(_ sender: Any) {
        if self.titleTextField.text?.isEmpty == true { return }
        self.emojiTextField.resignFirstResponder()
        self.titleTextField.resignFirstResponder()
        self.saveAction()
    }
    
    @IBAction func cancelButtonTouched(_ sender: Any) {
        self.emojiTextField.resignFirstResponder()
        self.titleTextField.resignFirstResponder()
        self.dismiss(animated: true)
    }
    
    @IBAction func doneButtonTouched(_ sender: Any) {
        self.titleTextField.resignFirstResponder()
        self.doneButton.isSelected = !self.doneButton.isSelected
        self.doneButton.setImage(self.doneButton.isSelected ? UIImage(systemName: "checkmark.circle.fill") : UIImage(systemName: "circle"),
                                 for: .normal)
    }
    

    private func saveAction() {
        guard let title = self.titleTextField.text else { return }
        if viewModel.existNextAction() {
            // 딸려있는 실천이 있을때
            let alert = AlertService.saveRoutineActionAlert(
                thisOnlyHandler: { [weak self] _ in
                    self?.viewModel.saveAction(title: title,
                                              emoji: self?.emojiTextField.text ?? nil,
                                              isDone: self?.doneButton.isSelected,
                                              isAlarmOn: self?.alarmSwitch.isOn,
                                              dueDate: self?.dueDatePicker.date,
                                              dueTime: self?.timeDatePicker.date,
                                              routines: nil)
                    self?.dismiss(animated: true)
                }, afterAllHandler: { [weak self] _ in
                    guard let routines = self?.selectedRoutines else { return }
                    self?.viewModel.saveRoutineActions(title: title,
                                                       emoji: self?.emojiTextField.text ?? nil,
                                                       isDone: self?.doneButton.isSelected,
                                                       isAlarmOn: self?.alarmSwitch.isOn,
                                                       dueDate: self?.dueDatePicker.date,
                                                       dueTime: self?.timeDatePicker.date,
                                                       routines: routines,
                                                       endDate: routines.isEmpty ? nil : self?.endDatePicker.date)
                    self?.dismiss(animated: true)
                })
            AlertService.presentAlert(alert: alert, vc: self)
        } else {
            self.viewModel.saveAction(title: title,
                                      emoji: self.emojiTextField.text ?? nil,
                                      isDone: self.doneButton.isSelected,
                                      isAlarmOn: self.alarmSwitch.isOn,
                                      dueDate: self.dueDatePicker.date,
                                      dueTime: self.timeDatePicker.date,
                                      routines: self.selectedRoutines,
                                      endDate: self.selectedRoutines.isEmpty ? nil : self.endDatePicker.date)
            self.dismiss(animated: true)
        }
    }
    @objc private func dateTouched() {
        let alert = AlertService.datePickerAlert()
        AlertService.presentAlert(alert: alert, vc: self)
    }
    @objc private func timeTouched() {
        let alert = AlertService.timePickerAlert()
        AlertService.presentAlert(alert: alert, vc: self)

    }
    @objc private func routinesTouched() {
        let alert =  AlertService.routineDayAlert(vc: self, routines: self.selectedRoutines)
        AlertService.presentAlert(alert: alert, vc: self)
    }
    @objc private func tagsTouched() {
        
    }
    @objc private func deleteViewTouched() {
        if viewModel.existNextAction() {
            // 딸려있는 실천이 있을때
            let alert = AlertService.deleteRoutineActionAlert(
                thisOnlyHandler: { [weak self] _ in
                    self?.viewModel.deleteAction()
                    self?.dismiss(animated: true)
                }, afterAllHandler: { [weak self] _ in
                    self?.viewModel.deleteRoutines()
                    self?.dismiss(animated: true)
                })
            AlertService.presentAlert(alert: alert, vc: self)
        } else {
            self.viewModel.deleteAction()
            self.dismiss(animated: true)
        }
    }
    
    static func buildAddActionViewController(_ context: UIViewController) -> AddActionViewController? {
        guard let viewController = context.storyboard?.instantiateViewController(withIdentifier: "AddActionViewController") as? AddActionViewController else { return nil }
        viewController.isModalInPresentation = true // 스와이프로 꺼지는 동작 방어
        if let sheet = viewController.sheetPresentationController {
            if #available(iOS 16.0, *) { // 높이 지정
                sheet.detents = [.custom { _ in
                    return 530
                }]
            } else {
                sheet.detents = [.large()]
            }
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
            sheet.prefersEdgeAttachedInCompactHeight = true
            sheet.widthFollowsPreferredContentSizeWhenEdgeAttached = true
        }
        return viewController
    }
}

extension AddActionViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.text = ""
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == self.emojiTextField && string.count > 0 {
            DispatchQueue.main.async {
                textField.resignFirstResponder()
                self.titleTextField.becomeFirstResponder()
            }
        }
        return true
    }
}

extension AddActionViewController: AddActionDelegate {
    func valueChanged(_ dic: Dictionary<ActionData, Any>) {
        for (key, value) in dic {
            switch key {
            case .title:
                guard let value = value as? String else { continue }
                self.titleTextField.text = value
            case .emoji:
                guard let value = value as? String else { continue }
                self.emojiTextField.text = value
            case .alarmSwitch:
                guard let value = value as? Bool else { continue }
                self.alarmSwitch.setOn(value, animated: false)
            case .isDone:
                guard let value = value as? Bool else { continue }
                self.doneButton.isSelected = value
                self.doneButton.setImage(value ?
                                         UIImage(systemName: "checkmark.circle.fill")
                                         : UIImage(systemName: "circle"),
                                         for: .normal)
            default:
                print("\(key) \(value)")
                break
            }
        }
    }
}

protocol AddActionDelegate {
    func valueChanged(_ dic: Dictionary<ActionData, Any>)
}
