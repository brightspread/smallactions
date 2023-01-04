//
//  TodayDayCell.swift
//  smallactions
//
//  Created by Jo on 2023/01/03.
//

import UIKit

class TodayDayCell: UICollectionViewCell {
    static let reuseIdentifier = String(describing: TodayDayCell.self)
    
    @IBOutlet weak var dayLabel: UILabel!
    @IBOutlet weak var dayELabel: UILabel!
    @IBOutlet weak var background: RoundedCornerView!
    
    var day: Day? {
        didSet {
            guard let day = day else { return }
            self.dayLabel.text = day.number
            self.dayELabel.text = Utils.dateToE(day.date, "en_US")
            self.updateSelectionStatus()
        }
    }
    
//    var actionProgress: Double = 0 {
//        didSet {
//            self.updateActionProgress()
//        }
//    }

}


private extension TodayDayCell {
    func updateSelectionStatus() {
        guard let day = day else { return }
        if Utils.getDay(day.date) == "1" {
            print(day.date)
        }
        if day.isSelected {
            self.background.alpha = 1.0
            self.dayLabel.textColor = .white
            self.dayELabel.textColor = .white
        } else {
            background.alpha = 0.0
            self.dayLabel.textColor = .black
            self.dayELabel.textColor = .black
        }
    }

}
