//
//  AddActionViewController.swift
//  smallactions
//
//  Created by Jo on 2022/12/18.
//

import UIKit



class AddActionViewController: UIViewController {
    
    lazy var viewModel = { AddActionViewModel() }()

    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var titleTextField: UITextField!
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
        self.emojiTextField.delegate = self
        self.initViewModel()
        self.configureInputField()
        self.registerTouchHandler()
        self.configureTodayContents()
    }
    
    private func initViewModel() {
        self.viewModel.delegate = self
        self.viewModel.configureData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    private func configureTodayContents() {
        switch self.viewModel.actionEditorMode {
        case .edit(_):
            self.deleteView.isHidden = false
        default:
            self.dueDatePicker.date = self.viewModel.selectedDueDate
            self.dateLabel.text = Utils.monthDateDay(self.viewModel.selectedDueDate) + " >"
            self.deleteView.isHidden = true
            break
        }
        self.validateInputField()
    }
    
    private func configureInputField() {
        self.titleTextField.addTarget(self, action: #selector(titleTextFieldDidChnage(_:)), for: .editingChanged)
    }

    private func registerTouchHandler() {
        self.alarmSwitch.addTarget(self, action: #selector(alarmSwitchChanged(sender:)), for: .valueChanged)
        self.timeDatePicker.addTarget(self, action: #selector(dueTimeChanged(sender:)), for: .valueChanged)
        self.dueDatePicker.addTarget(self, action: #selector(dueDateChanged(sender:)), for: .valueChanged)
        self.endDatePicker.addTarget(self, action: #selector(endDateChanged(sender:)), for: .valueChanged)

        self.routinesLabel.addGestureRecognizer(routinesTapGesutre)
        self.tagsLabel.addGestureRecognizer(tagsTapGesutre)
        self.deleteView.addGestureRecognizer(deleteTapGesutre)
    }

    
    private func unregisterTouchHandler() {
        self.routinesLabel.removeGestureRecognizer(routinesTapGesutre)
        self.tagsLabel.removeGestureRecognizer(tagsTapGesutre)
        self.deleteView.removeGestureRecognizer(deleteTapGesutre)
    }

    @objc private func alarmSwitchChanged(sender: UISwitch) {
//        self.endDateView.isHidden = !sender.isOn
    }
    
    @objc private func dueTimeChanged(sender: UIDatePicker) {
        self.dueTimeLabel.text = Utils.ampmTime(sender.date)
    }
    
    @objc private func dueDateChanged(sender: UIDatePicker) {
        self.dateLabel.text = Utils.monthDateDay(sender.date) + " >"
        self.viewModel.dueDateChanged(sender.date)
    }

    @objc private func endDateChanged(sender: UIDatePicker) {
        self.endDateLabel.text = Utils.monthDateDay(sender.date) + " >"
    }

    @objc private func titleTextFieldDidChnage(_ textField: UITextField) {
        self.validateInputField()
    }
    
    private func validateInputField() {
        self.saveButton.isEnabled = !(self.titleTextField.text?.isEmpty ?? true)
    }
    
    // #MARK: Touch Handlers
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("touchesBegan")
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


extension AddActionViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        self.validateInputField()
    }
}

extension AddActionViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.text = ""
    }
}

extension AddActionViewController: AddActionDelegate {
    func valueChanged(_ dic: Dictionary<ActionData, Any>) {
        print("valueChanged : \(dic)")
        for (key, value) in dic {
            switch key {
            case .routines:
                guard let value = value as? [String] else { continue }
                self.selectedRoutines = value
                self.routinesLabel.text = value.isEmpty ? "없음 >" : value.map {
                    return String($0.first!)
                }.joined(separator: ", ") + " >"
                self.endDateView.isHidden = value.isEmpty
            case .duetime:
                guard let value = value as? Date else { continue }
                self.timeDatePicker.date = value
                self.dueTimeLabel.text = Utils.ampmTime(value) + " >"
            case .dueDate:
                guard let value = value as? Date else { continue }
                self.dueDatePicker.date = value
                self.dateLabel.text = Utils.monthDateDay(value) + " >"
            case .endDate:
                guard let value = value as? Date else { continue }
                self.endDateLabel.text = Utils.monthDateDay(value) + " >"
                self.endDatePicker.date = value
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
