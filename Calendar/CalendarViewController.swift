//
//  CalendarViewController.swift
//  smallactions
//
//  Created by Jo on 2022/12/14.
//

import UIKit

class CalendarViewController: UIViewController {
    
    lazy var viewModel = { CalendarViewModel() }()

    @IBOutlet weak var calendarCollectionView: UICollectionView!
    @IBOutlet weak var actionTableView: UITableView!
    @IBOutlet weak var monthLabel: UILabel!
    @IBOutlet weak var yearLabel: UILabel!
    @IBOutlet weak var lastMonthImageView: UIImageView!
    @IBOutlet weak var nextMonthImageView: UIImageView!
    @IBOutlet weak var selectedDateLabel: UILabel!
    
    private lazy var lastMonthHandler = UITapGestureRecognizer(target: self, action: #selector(lastMonthTouched))
    private lazy var nextMonthHandler = UITapGestureRecognizer(target: self, action: #selector(nextMonthTouched))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureData()
        self.registerTouchHandler()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    private func configureData() {
        self.viewModel.delegate = self
        self.calendarCollectionView.delegate = self
        self.calendarCollectionView.dataSource = self
        self.actionTableView.delegate = self
        self.actionTableView.dataSource = self
        self.viewModel.loadActions()
        self.selectedDateLabel.text = Utils.monthDate(Date.now)
    }
    
    private func registerTouchHandler() {
        self.lastMonthImageView.addGestureRecognizer(self.lastMonthHandler)
        self.nextMonthImageView.addGestureRecognizer(self.nextMonthHandler)
    }
    
    private func unregisterTouchHandler() {
        self.lastMonthImageView.removeGestureRecognizer(self.lastMonthHandler)
        self.nextMonthImageView.removeGestureRecognizer(self.nextMonthHandler)
    }
    
    @objc func lastMonthTouched() {
        self.viewModel.showLastMonth()
    }
    
    @objc func nextMonthTouched() {
        self.viewModel.showNextMonth()
    }
    
}

extension CalendarViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        self.viewModel.days.count
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let day = self.viewModel.days[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DayCell.reuseIdentifier,
                                                      for: indexPath) as! DayCell
        cell.day = day
        return cell
    }
    
}

extension CalendarViewController: UICollectionViewDelegate {
    
}

extension CalendarViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {
        let day = self.viewModel.days[indexPath.row]
        self.viewModel.selectDate(day.date)
        //        baseDate = baseDate
        //        collectionView.reloadData()
        //    dismiss(animated: true, completion: nil)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return self.viewModel.getCalendarSize(width: collectionView.frame.width,
                                              height: collectionView.frame.height)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0    // 옆 라인 간격
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0     // 위아래 라인 간격
    }
}

extension CalendarViewController: CalendarViewDelegate {
    func dateDidChanged() {
        self.calendarCollectionView.reloadData()
    }
    
    func valueChanged(_ dic: Dictionary<CalendarData, Any>) {
        for (key, value) in dic {
            switch key {
            case .baseData:
                guard let value = value as? Date else { return }
                self.monthLabel.text = Utils.getMonth(value)
                self.yearLabel.text = Utils.getYear(value)
                self.selectedDateLabel.text = Utils.monthDate(value)
            case .selectedData:
                guard let value = value as? Date else { return }
                self.selectedDateLabel.text = Utils.monthDate(value)
            }
        }
    }
    
    func actionDidChanged() {
        self.actionTableView.reloadData()
    }
}

extension CalendarViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.actions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let action = self.viewModel.actions[indexPath.row]
        if action.dueTime != nil {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: CalendarActionWithTimeTableViewCell.reuseIdentifier, for: indexPath) as? CalendarActionWithTimeTableViewCell else { return UITableViewCell() }
            cell.selectionStyle = .none
            cell.action = action
            return cell
        } else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: CalendarActionTableViewCell.reuseIdentifier, for: indexPath) as? CalendarActionTableViewCell else { return UITableViewCell() }
            cell.selectionStyle = .none
            cell.action = action
            return cell
        }
    }
}

extension CalendarViewController: UITableViewDelegate {
    
}

protocol CalendarViewDelegate {
    func dateDidChanged()
    func valueChanged(_ dic: Dictionary<CalendarData, Any>)
    func actionDidChanged()
}
