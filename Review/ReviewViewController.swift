//
//  ReviewViewController.swift
//  smallactions
//
//  Created by Jo on 2022/12/14.
//

import UIKit

class ReviewViewController: UIViewController {

    lazy var viewModel = { ReviewViewModel() }()
    
    @IBOutlet weak var reviewTableView: UITableView!
    @IBOutlet weak var reviewDateLabel: UILabel!
    @IBOutlet weak var reviewDatePicker: UIDatePicker!
    @IBOutlet weak var complimentsLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initViewModel()
        self.configureView()
        self.registerHandlers()
    }
    
    private func initViewModel() {
        self.viewModel.delegate = self
        self.viewModel.configureData()
    }
    
    private func configureView() {
        self.reviewDateLabel.text = self.viewModel.oneWeekString
    }
    private func registerHandlers() {
        self.reviewDatePicker.addTarget(self, action: #selector(reviewDateChanged(sender:)), for: .valueChanged)
    }
    
    @objc private func reviewDateChanged(sender: UIDatePicker) {
        self.viewModel.selectedDate = sender.date
    }
}

extension ReviewViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.reviews.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ReviewTableViewCell.reuseIdentifier) as? ReviewTableViewCell else { return UITableViewCell() }
        cell.review = self.viewModel.reviews[indexPath.row]
        cell.selectionStyle = .none
        return cell
    }
}

extension ReviewViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension ReviewViewController: ReviewViewDelegate {
    func reviewDidChange() {
        self.reviewDateLabel.text = self.viewModel.oneWeekString
        self.reviewTableView.reloadData()
    }
}

protocol ReviewViewDelegate {
    func reviewDidChange()
}
