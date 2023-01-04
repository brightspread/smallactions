//
//  SettingTableViewCell.swift
//  smallactions
//
//  Created by Jo on 2023/01/04.
//

import UIKit

class SettingTableViewCell: UITableViewCell {
    static let reuseIdentifier = String(describing: SettingTableViewCell.self)

    @IBOutlet weak var emojiLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    
    var setting: Setting? {
        didSet {
            guard let setting = self.setting else { return }
            self.emojiLabel.text = setting.emoji
            self.titleLabel.text = setting.title
        }
    }
}
