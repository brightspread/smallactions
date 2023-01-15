//
//  ReviewViewController.swift
//  smallactions
//
//  Created by Jo on 2022/12/14.
//

import UIKit
import RxCocoa
import RxSwift

class ReviewViewController: UIViewController {

    var disposeBag = DisposeBag()
    lazy var viewModel = { ReviewViewModel() }()
    
    @IBOutlet weak var reviewTableView: UITableView!
    @IBOutlet weak var reviewDateLabel: UILabel!
    @IBOutlet weak var reviewDatePicker: UIDatePicker!
    @IBOutlet weak var complimentsLabel: UILabel!
    
    @IBOutlet weak var reviewMainLabel: UILabel!
    @IBOutlet weak var reviewSubLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.initViewModel()
        self.configureView()
        self.registerHandlers()
    }
    
    private func initViewModel() {
        viewModel.rxConfigureData()
    }
    
    private func configureView() {
        viewModel.rxOneWeekString
            .asDriver(onErrorJustReturn: "")
            .drive(reviewDateLabel.rx.text)
            .disposed(by: disposeBag)
        viewModel.rxReviews
            .asDriver(onErrorJustReturn: [])
            .drive(reviewTableView.rx.items(cellIdentifier: ReviewTableViewCell.reuseIdentifier, cellType: ReviewTableViewCell.self)) { _, item, cell in
                cell.review = item
            }.disposed(by: disposeBag)
        
//        self.reviewDateLabel.text = self.viewModel.oneWeekString
    }
    private func registerHandlers() {
        self.reviewDatePicker.addTarget(self, action: #selector(reviewDateChanged(sender:)), for: .valueChanged)
        self.reviewSubLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(reviewSubLabelTapped(sender:))))
    }
    
    @objc private func reviewSubLabelTapped(sender: UIGestureRecognizer) {
        guard let wmstate = ReviewWMState(rawValue:(sender.view as? UILabel)?.text ?? "") else { return }
        _ = Observable.just(wmstate)
            .bind(to: viewModel.rxWMstate)
            .disposed(by: disposeBag)
        switch wmstate {
        case .month:
            self.reviewMainLabel.text = "월간 실천 진행"
            self.reviewSubLabel.text = "주간"
        case .week:
            self.reviewMainLabel.text = "주간 실천 진행"
            self.reviewSubLabel.text = "월간"
        }
    }
    
    @objc private func reviewDateChanged(sender: UIDatePicker) {
        _ = Observable.just(sender.date)
            .bind(to: viewModel.rxSelectedDate)
            .disposed(by: disposeBag)
        guard let presentedViewController = presentedViewController else { return }
        presentedViewController.dismiss(animated: false, completion: nil)
    }
}
