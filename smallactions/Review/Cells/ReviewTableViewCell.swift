//
//  ReviewTableViewCell.swift
//  smallactions
//
//  Created by Jo on 2023/01/01.
//

import UIKit

class ReviewTableViewCell: UITableViewCell {
    static let reuseIdentifier = String(describing: ReviewTableViewCell.self)
    
    var review: Review? {
        didSet {
            guard let review = review else { return }
            self.titleLabel.text = review.actionTitle
            self.emojiLabel.text = review.actionEmoji
            self.countLabel.text = String(review.count)
            self.countLabel.contentMode = .bottom
            guard let lastDate = review.lastDate else { return }
            self.timeLabel.text = Utils.dateToE(lastDate)
        }
    }

    @IBOutlet weak var emojiLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var countLabel: UILabel!
}
