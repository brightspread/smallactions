//
//  AlertTableViewController.swift
//  smallactions
//
//  Created by Jo on 2022/12/26.
//

import UIKit

enum enumDay {
    
}

class AlertTableViewController: UITableViewController {

    var delegate: UIViewController?
    private let routines = ["월요일", "화요일", "수요일", "목요일", "금요일", "토요일", "일요일"]
    private let alertBackgroundColor = UIColor(red: 238/255, green: 238/255, blue: 239/255, alpha: 1.0)
    
    var selectedRoutines: [String] = [] {
        didSet {
            self.selectedRoutines = self.selectedRoutines.sorted {
                Utils.orderDay(str1: $0, str2: $1)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.backgroundColor = alertBackgroundColor
        self.preferredContentSize.height = 44 * 7
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return routines.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        var content = cell.defaultContentConfiguration()
        content.text = routines[indexPath.row]
        cell.accessoryType = .none
        self.selectedRoutines.forEach {
            if $0 == content.text {
                cell.accessoryType = .checkmark
            }
        }
        cell.contentConfiguration = content
        cell.backgroundColor = alertBackgroundColor
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let cell = tableView.cellForRow(at: indexPath) else { return }
        let routine = self.routines[indexPath.row]
        if cell.accessoryType != .checkmark {
            cell.accessoryType = .checkmark
            self.selectedRoutines.append(routine)
        } else {
            cell.accessoryType = .none
            self.selectedRoutines.enumerated().forEach {
                if routine == $1 {
                    self.selectedRoutines.remove(at: $0)
                }
            }
        }
    }
    
}
