//
//  CalendarActionWithTimeTableViewCell.swift
//  smallactions
//
//  Created by Jo on 2022/12/29.
//

import UIKit

class CalendarActionWithTimeTableViewCell: UITableViewCell {
    static let reuseIdentifier = String(describing: CalendarActionWithTimeTableViewCell.self)
    
    @IBOutlet weak var emojiLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var doneButton: UIButton!
    
    var action: Action? {
        didSet {
            guard let action = action else { return }
            self.emojiLabel.text = action.emoji
            self.titleLabel.text = action.title
            guard let time = action.dueTime else { return }
            self.timeLabel.text = Utils.ampmTime(time)
            self.doneButton.setImage(action.isDone ? UIImage(systemName: "checkmark.circle.fill") : UIImage(systemName: "circle"), for: .normal)
        }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    @IBAction func doneButtonTouched(_ sender: Any) {
        guard let action = action, let id = action.id else { return }
        CoreDataManager.shared.editAction(id, isDone: !action.isDone)
    }


}
