//
//  CalendarViewController.swift
//  smallactions
//
//  Created by Jo on 2022/12/14.
//

import UIKit

class CalendarViewController: UIViewController {
    
    @IBOutlet weak var monthLabel: UILabel!
    @IBOutlet weak var yearLabel: UILabel!
    @IBOutlet weak var calendarCollectionView: UICollectionView!
    @IBOutlet weak var lastMonthImageView: UIImageView!
    @IBOutlet weak var nextMonthImageView: UIImageView!
    @IBOutlet weak var selectedDateLabel: UILabel!
    
    private lazy var lastMonthHandler = UITapGestureRecognizer(target: self, action: #selector(lastMonthTouched))
    private lazy var nextMonthHandler = UITapGestureRecognizer(target: self, action: #selector(nextMonthTouched))
    
    private var selectedDate: Date = Date.now {
        didSet {
            self.days = generateDaysInMonth(for: baseDate)
            self.calendarCollectionView.reloadData()
        }
    }
    
    private var baseDate: Date = Date.now {
        didSet {
            self.days = generateDaysInMonth(for: baseDate)
            self.calendarCollectionView.reloadData()
            self.monthLabel.text = Utils.getMonth(baseDate)
            self.yearLabel.text = Utils.getYear(baseDate)
        }
    }
    
    private lazy var days = generateDaysInMonth(for: baseDate)
    
    private var numberOfWeeksInBaseDate: Int {
        calendar.range(of: .weekOfMonth, in: .month, for: baseDate)?.count ?? 0
    }
    
    
    private let calendar = Calendar(identifier: .gregorian)
    private lazy var numberDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d"
        return dateFormatter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.calendarCollectionView.delegate = self
        self.calendarCollectionView.dataSource = self
        
        self.registerTouchHandler()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        unregisterTouchHandler()
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
        self.baseDate = self.calendar.date(
            byAdding: .month,
            value: -1,
            to: self.baseDate
        ) ?? self.baseDate
    }
    
    @objc func nextMonthTouched() {
        self.baseDate = self.calendar.date(byAdding: .month,
                                           value: 1,
                                           to: self.baseDate) ?? self.baseDate
    }
    
}

extension CalendarViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        days.count
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let day = days[indexPath.row]
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
        let day = days[indexPath.row]
        self.selectedDate = day.date
        //        baseDate = baseDate
        //        collectionView.reloadData()
        //    dismiss(animated: true, completion: nil)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = Int(collectionView.frame.width / 7)
        let height = Int(collectionView.frame.height) / numberOfWeeksInBaseDate
        return CGSize(width: width, height: height)
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


private extension CalendarViewController {
    func monthMetadata(for baseDate: Date) throws -> MonthMetadata {
        guard let numberOfDaysInMonth = calendar.range(of: .day,in: .month,for: baseDate)?.count,
              let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: baseDate))
        else { throw CalendarDataError.metadataGeneration }
        
        let firstDayWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        
        return MonthMetadata(numberOfDays: numberOfDaysInMonth,
                             firstDay: firstDayOfMonth,
                             firstDayWeekday: firstDayWeekday)
    }
    
    func generateDaysInMonth(for baseDate: Date) -> [Day] {
        guard let metadata = try? monthMetadata(for: baseDate) else {
            preconditionFailure("An error occurred when generating the metadata for \(baseDate)")
        }
        
        let numberOfDaysInMonth = metadata.numberOfDays
        let offsetInInitialRow = metadata.firstDayWeekday
        let firstDayOfMonth = metadata.firstDay
        
        var days: [Day] = (1..<(numberOfDaysInMonth + offsetInInitialRow))
            .map { day in
                let isWithinDisplayedMonth = day >= offsetInInitialRow
                let dayOffset =
                isWithinDisplayedMonth ?
                day - offsetInInitialRow :
                -(offsetInInitialRow - day)
                
                return generateDay(offsetBy: dayOffset,
                                   for: firstDayOfMonth,
                                   isWithinDisplayedMonth: isWithinDisplayedMonth)
            }
        
        days += generateStartOfNextMonth(using: firstDayOfMonth)
        
        return days
    }
    
    func generateDay(
        offsetBy dayOffset: Int,
        for baseDate: Date,
        isWithinDisplayedMonth: Bool
    ) -> Day {
        let date = calendar.date(byAdding: .day,
                                 value: dayOffset,
                                 to: baseDate) ?? baseDate
        
        return Day(date: date,
                   number: Utils.getDay(date),
                   isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                   isWithinDisplayedMonth: isWithinDisplayedMonth)
    }
    
    func generateStartOfNextMonth(using firstDayOfDisplayedMonth: Date) -> [Day] {
        guard let lastDayInMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1),
                                                 to: firstDayOfDisplayedMonth)
        else { return [] }
        
        let additionalDays = 7 - calendar.component(.weekday, from: lastDayInMonth)
        guard additionalDays > 0 else { return [] }
        
        let days: [Day] = (1...additionalDays)
            .map {
                generateDay(offsetBy: $0,
                            for: lastDayInMonth,
                            isWithinDisplayedMonth: false)
            }
        
        return days
    }
    
    enum CalendarDataError: Error {
        case metadataGeneration
    }
    
}
