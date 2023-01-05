//
//  TodayViewController.swift
//  smallactions
//
//  Created by Jo on 2022/12/14.
//

import UIKit
import CoreData

class TodayViewController: UIViewController {
    
    lazy var todayViewModel = { TodayViewModel() }()
    lazy var calendarViewModel = { CalendarViewModel() }()

    lazy var confettiView = ConfettiView(frame: self.view.bounds)

    @IBOutlet weak var monthLabel: UILabel!
    @IBOutlet weak var actionLabel: UILabel!
    @IBOutlet weak var subActionLabel: UILabel!
    @IBOutlet weak var todayLabel: UILabel!
    @IBOutlet weak var calendarCollectionView: UICollectionView!
    @IBOutlet weak var actionTableView: UITableView!
    @IBOutlet weak var addButtonImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initViewModel()
        self.configureTodayView()
        self.configureViews()
        self.registerHandlers()
    }
    
    private func initViewModel() {
        self.todayViewModel.delegate = self
        self.todayViewModel.configureData()
        self.calendarViewModel.delegate = self
    }
    
    private func configureTodayView() {
        self.monthLabel.text = Utils.getYearMonth(self.todayViewModel.selectedDate)
    }
    
    private func configureViews() {
        self.actionTableView.dataSource = self
        self.actionTableView.delegate = self
        self.calendarCollectionView.dataSource = self
        self.calendarCollectionView.delegate = self
    }
    
    private func registerHandlers() {
        self.addButtonImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(addButtonTapped)))
        self.todayLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(todayLabelTapped)))
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(confettiNotification(_ :)),
            name: NSNotification.Name("confetti"),
            object: nil
        )
    }
    
    @objc private func confettiNotification(_ notification: Notification) {
        self.view.addSubview(confettiView)
        confettiView.startConfetti()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.confettiView.stopConfetti()
            self?.confettiView.removeFromSuperview()
        }
    }
    
    // MARK: 실천 추가 페이지
    @objc private func addButtonTapped() {
        guard let viewController = AddActionViewController.buildAddActionViewController(self)
        else { return }
        viewController.viewModel.selectedDueDate = self.todayViewModel.selectedDate
        self.present(viewController, animated: true, completion: nil)
    }
    
    @objc private func todayLabelTapped() {
        self.calendarViewModel.selectDate(Date.now)
        self.todayViewModel.selectedDate = Date.now
    }

    private func showEditActionView(_ action: Action?) {
        guard let viewController = AddActionViewController.buildAddActionViewController(self)
        else { return }
        if let action = action {
            viewController.viewModel.actionEditorMode = .edit(action)
        }
        self.present(viewController, animated: true, completion: nil)
    }
}

extension TodayViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.todayViewModel.actions.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let action = self.todayViewModel.actions[indexPath.row]
        if action.dueTime != nil {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: ActionBasicWithTimeTableViewCell.reuseIdentifier, for: indexPath) as? ActionBasicWithTimeTableViewCell else { return UITableViewCell() }
            cell.selectionStyle = .none
            cell.action = action
            return cell
        } else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: ActionBasicTableViewCell.reuseIdentifier, for: indexPath) as? ActionBasicTableViewCell else { return UITableViewCell() }
            cell.selectionStyle = .none
            cell.action = action
            return cell
        }
    }
}

extension TodayViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let action = self.todayViewModel.actions[indexPath.row]
        self.showEditActionView(action)
    }
}

extension TodayViewController: TodayViewDelegate {
    func actionDidChanged() {
        self.updateCalendar()
        Utils.triggerNotification()
    }
}

extension TodayViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return self.calendarViewModel.days.count
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let day = self.calendarViewModel.days[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TodayDayCell.reuseIdentifier,
                                                      for: indexPath) as! TodayDayCell
        cell.day = day
//        cell.actionProgress = self.viewModel.getActionProgress(day.date)
        return cell
    }
    
}

extension TodayViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {
        let day = self.calendarViewModel.days[indexPath.row]
        self.todayViewModel.selectedDate = day.date
        self.calendarViewModel.selectDate(day.date)
//        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        //        baseDate = baseDate
        //        collectionView.reloadData()
        //    dismiss(animated: true, completion: nil)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 36, height: collectionView.frame.height)
//        return self.calendarViewModel.getCalendarSize(width: collectionView.frame.width,
//                                              height: collectionView.frame.height)
    }
    
    
}


extension TodayViewController: CalendarViewDelegate {
    func updateCalendar() {
        self.calendarCollectionView.reloadData()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            for i in 0..<self.calendarViewModel.days.count {
                if self.calendarViewModel.days[i].isSelected {
                    if self.calendarCollectionView.visibleCells.count >= 0 {
                        self.calendarCollectionView.scrollToItem(at: IndexPath.init(row: i, section: 0), at: .centeredHorizontally, animated: true)
                    }
                    break
                }
            }
        }
        self.actionTableView.reloadData()
        self.configureTodayView()
    }
    
    func valueChanged(_ dic: Dictionary<CalendarData, Any>) {
        for (key, value) in dic {
            switch key {
            case .baseData:
                guard let value = value as? Date else { return }
//                self.monthLabel.text = Utils.getMonth(value)
//                self.yearLabel.text = Utils.getYear(value)
//                self.selectedDateLabel.text = Utils.monthDate(value)
            case .selectedData:
                guard let value = value as? Date else { return }
                self.todayViewModel.selectedDate = value
//                self.monthLabel.text = Utils.getMonth(value)
//                self.yearLabel.text = Utils.getYear(value)
//                self.selectedDateLabel.text = Utils.monthDate(value)
            }
        }
    }
}

protocol TodayViewDelegate {
    func actionDidChanged()
}
