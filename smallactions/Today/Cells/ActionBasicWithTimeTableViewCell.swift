//
//  ActionBasicWithTimeTableViewCell.swift
//  smallactions
//
//  Created by Jo on 2022/12/14.
//

import UIKit

class ActionBasicWithTimeTableViewCell: UITableViewCell {
    
    static let reuseIdentifier = String(describing: ActionBasicWithTimeTableViewCell.self)

    @IBOutlet weak var roundView: RoundedCornerView!
    @IBOutlet weak var emojiLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var dimView: RoundedCornerView!

    var action: Action? {
        didSet {
            guard let action = action else { return }

            self.emojiLabel.text = action.emoji
            self.titleLabel.text = action.title
            self.doneButton.setImage(action.isDone ? UIImage(systemName: "checkmark.circle.fill") : UIImage(systemName: "circle"), for: .normal)

            //Animation 자연스럽게
            self.dimView.layoutIfNeeded()
            
            UIView.animate(withDuration: 0.5, animations: {
                self.roundView.alpha = action.isDone ? 0.7 : 1.0
                self.dimView.alpha = action.isDone ? 0.1 : 0
                self.dimView.layoutIfNeeded()
            })

            guard let time = action.dueTime else { return }
            self.timeLabel.text = Utils.ampmTime(time)
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
