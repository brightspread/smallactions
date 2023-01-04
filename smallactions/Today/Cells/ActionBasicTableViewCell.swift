//
//  ActionBasicTableViewCell.swift
//  smallactions
//
//  Created by Jo on 2022/12/14.
//

import UIKit

class ActionBasicTableViewCell: UITableViewCell {
    
    static let reuseIdentifier = String(describing: ActionBasicTableViewCell.self)

    @IBOutlet weak var roundView: RoundedCornerView!
    @IBOutlet weak var dimView: UIView!
    @IBOutlet weak var emojiLabel: UILabel!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    
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
