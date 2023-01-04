//
//  SettingsViewController.swift
//  smallactions
//
//  Created by Jo on 2022/12/14.
//

import UIKit
import CoreData

class SettingsViewController: UIViewController {

    @IBOutlet weak var settingTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

extension SettingsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "SettingTableViewCell") as? SettingTableViewCell else { return UITableViewCell() }
        switch indexPath.row {
        case 0:
            cell.setting = Setting(emoji: "✉️", title: "개발자에게 문의하기")
        case 1:
            cell.setting = Setting(emoji: "🗑", title: "전체 데이터 삭제하기")
        default:
            break
        }
        return cell
    }
}

extension SettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath.row {
        case 0:
            Utils.sendEmailToAsk(self)
        case 1:
            let alert = AlertService.deleteAllDataActionAlert(deleteActionHandler: { _ in
                let reAlert = AlertService.deleteAllDataRetryActionAlert(deleteActionHandler: { _ in
                    let request: NSFetchRequest<Action> = Action.fetchRequest()
                    let allActions = CoreDataManager.shared.fetch(request: request)
                    allActions.forEach {
                        CoreDataManager.shared.delete($0)
                    }
                })
                AlertService.presentAlert(alert: reAlert, vc: self)

            })
            AlertService.presentAlert(alert: alert, vc: self)
        default:
            break
        }
    }
}
