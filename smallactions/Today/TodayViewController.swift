//
//  TodayViewController.swift
//  smallactions
//
//  Created by Jo on 2022/12/14.
//

import UIKit
import CoreData
import RxSwift
import RxCocoa

class TodayViewController: UIViewController {
    
    var todayViewModel = TodayViewModel()
    var calendarViewModel = CalendarViewModel()
    
    var disposeBag = DisposeBag()

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
        self.configureViews()
        self.registerHandlers()
        self.configureRx()
    }
    
    private func configureRx() {
        _ = todayViewModel.rxActions
            .subscribe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.updateCalendar()
                Utils.triggerNotification()
            })
            .disposed(by: disposeBag)
        
        todayViewModel.rxActions
            .asDriver(onErrorJustReturn: [])
            .drive(actionTableView.rx.items) { (tableView, row, action) -> UITableViewCell in
                if action.dueTime != nil {
                    guard let cell = tableView.dequeueReusableCell(withIdentifier: "ActionBasicWithTimeTableViewCell", for: IndexPath(row: row, section: 0)) as? ActionBasicWithTimeTableViewCell else { return UITableViewCell() }
                    cell.action = action
                    return cell
                } else {
                    guard let cell = tableView.dequeueReusableCell(withIdentifier: "ActionBasicTableViewCell", for: IndexPath(row: row, section: 0)) as? ActionBasicTableViewCell else { return UITableViewCell() }
                    cell.action = action
                    return cell
                }
            }.disposed(by: disposeBag)
        
        Observable.zip(actionTableView.rx.modelSelected(Action.self),
                       actionTableView.rx.itemSelected)
        .bind { [weak self] (action, indexPath) in
            self?.actionTableView.deselectRow(at: indexPath, animated: true)
            self?.showEditActionView(action)
        }.disposed(by: disposeBag)
        
        todayViewModel.rxSelectedDate
            .map { Utils.getYearMonth($0) }
            .asDriver(onErrorJustReturn: "")
            .drive(monthLabel.rx.text)
            .disposed(by: disposeBag)
    }
    
    private func initViewModel() {
        self.calendarViewModel.delegate = self
    }
    
    private func configureViews() {
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
        _ = Observable.just(todayViewModel.rxSelectedDate.value)
            .bind(to: viewController.viewModel.rxSelectedDueDate)
            .disposed(by: disposeBag)
//        viewController.viewModel.selectedDueDate = todayViewModel.rxSelectedDate.value
        self.present(viewController, animated: true, completion: nil)
    }
    
    @objc private func todayLabelTapped() {
        self.calendarViewModel.selectDate(Date.now)
        _ = Observable.just(Date.now)
            .bind(to: todayViewModel.rxSelectedDate)
            .disposed(by: disposeBag)
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
        return cell
    }
    
}

extension TodayViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {
        let day = self.calendarViewModel.days[indexPath.row]
        _ = Observable.just(day.date)
            .bind(to: todayViewModel.rxSelectedDate)
        self.calendarViewModel.selectDate(day.date)

    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 36, height: collectionView.frame.height)
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
                _ = Observable.just(value)
                    .bind(to: todayViewModel.rxSelectedDate)
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
