//
//  TodayViewController.swift
//  smallactions
//
//  Created by Jo on 2022/12/14.
//

import UIKit
import CoreData

class TodayViewController: UIViewController {
    
    lazy var viewModel = { TodayViewModel() }()

    @IBOutlet weak var monthLabel: UILabel!
    @IBOutlet weak var actionLabel: UILabel!
    @IBOutlet weak var subActionLabel: UILabel!

    @IBOutlet weak var calendarCollectionView: UICollectionView!
    @IBOutlet weak var actionTableView: UITableView!
    
    @IBOutlet weak var addButtonImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initViewModel()
        self.configureTodayView()
        self.configureTableView()
        self.registerHandlers()
    }
    
    private func initViewModel() {
        self.viewModel.delegate = self
        self.viewModel.configureData()
    }
    
    private func configureTodayView() {
        self.monthLabel.text = Utils.getYearMonth(Date.now)
    }
    
    private func configureTableView() {
        self.actionTableView.dataSource = self
        self.actionTableView.delegate = self
    }
    
    private func registerHandlers() {
        self.addButtonImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(addButtonTapped)))
    }
    
    // MARK: 실천 추가 페이지
    @objc private func addButtonTapped() {
        guard let viewController = AddActionViewController.buildAddActionViewController(self)
        else { return }
        self.present(viewController, animated: true, completion: nil)
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
        return self.viewModel.actions.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let action = self.viewModel.actions[indexPath.row]
        if action.dueTime != nil {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "ActionBasicWithTimeTableViewCell", for: indexPath) as? ActionBasicWithTimeTableViewCell else { return UITableViewCell() }
            cell.selectionStyle = .none
            cell.action = action
            return cell
        } else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "ActionBasicTableViewCell", for: indexPath) as? ActionBasicTableViewCell else { return UITableViewCell() }
            cell.selectionStyle = .none
            cell.action = action
            return cell
        }
    }
}

extension TodayViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let action = self.viewModel.actions[indexPath.row]
        self.showEditActionView(action)
    }
}

extension TodayViewController: TodayViewDelegate {
    func actionDidChanged() {
        self.actionTableView.reloadData()
    }
}

protocol TodayViewDelegate {
    func actionDidChanged()
}
