//
//  smallactionsTests.swift
//  smallactionsTests
//
//  Created by Jo on 2023/01/16.
//

import XCTest
import RxSwift

@testable import smallactions

final class smallactionsTests: XCTestCase {

    private var appDelegate: AppDelegate!
    private var settingsViewController: SettingsViewController!
    private var reviewViewModel: ReviewViewModel!
    private var disposeBag: DisposeBag!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        disposeBag = DisposeBag()

        reviewViewModel = ReviewViewModel()
        configureData()
        
        appDelegate = UIApplication.shared.delegate as! AppDelegate
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        settingsViewController = storyboard.instantiateViewController(withIdentifier: "SettingsViewController") as! SettingsViewController
        _ = settingsViewController.view  // Trigger view load and viewDidLoad()

    }
    
    func configureData() {
        reviewViewModel.rxConfigureData()
    }

    override func tearDownWithError() throws {
        settingsViewController = nil
        appDelegate = nil
        reviewViewModel = nil
        disposeBag = nil
        try super.tearDownWithError()
    }

    func testExample() throws {
        try reviewTest()
        try settingTest()
    }
    
    func reviewTest() throws {
        try reviewLastDateTest()
    }
    
    func reviewLastDateTest() throws {
        //given
        let guess = reviewViewModel.rxLastDate
        //when
        reviewViewModel.rxConfigureData()
        Observable.just(Date.now)
            .bind(to: reviewViewModel.rxFirstDate)
            .disposed(by: disposeBag)
        Observable.just(ReviewWMState.month)
            .bind(to: reviewViewModel.rxWMstate)
            .disposed(by: disposeBag)
        //then
        XCTAssertEqual(Utils.getDay(guess.value), Utils.getDay(getEndDayOfMonth(getStartDayOfMonth(Date.now))), "rxLastDate 오류")
//        XCTAssertEqual(Utils.getDay(guess.value), Utils.getDay(getEndDayOfMonth(Date.now)), "rxLastDate 오류")
    }
    
    func settingTest() throws {
        let guess = settingsViewController.settingTableView.dataSource?.tableView(settingsViewController.settingTableView, numberOfRowsInSection: 0)
        //when
        //then
        XCTAssertEqual(guess, 2, "Setting 테이블뷰 개수 오류")
    }
    

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }

    
    
    // 테스트용 체크 코드
    
    private func getStartDayOfMonth(_ date: Date) -> Date {
        let dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: date)
        let startDayComponents = DateComponents(year: dateComponents.year,
                                         month: dateComponents.month,
                                         day: 1)
        guard let newStartDay = Calendar.current.date(from: startDayComponents) else { return date }
        return newStartDay
    }
    
    private func getEndDayOfMonth(_ date: Date) -> Date {
        let calendar = Calendar(identifier: .gregorian)
        guard let numberOfDaysInMonth = calendar.range(of: .day,in: .month,for: date)?.count else { return date }
        guard let endDay = calendar.date(byAdding: .day, value: +(numberOfDaysInMonth - 1), to: date) else { return date }
        return endDay
    }
}
