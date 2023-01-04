//
//  DayCell.swift
//  smallactions
//
//  Created by Jo on 2022/12/21.
//

import UIKit

class DayCell: UICollectionViewCell {
    static let reuseIdentifier = String(describing: DayCell.self)
    
    @IBOutlet weak var dayLabel: UILabel!
    @IBOutlet weak var background: RoundedCornerView!
    @IBOutlet weak var selectPointView: RoundedCornerView!
    
    var day: Day? {
        didSet {
            guard let day = day else { return }
            self.dayLabel.text = day.number
            self.updateSelectionStatus()
        }
    }
    
    var actionProgress: Double = 0 {
        didSet {
            self.updateActionProgress()
        }
    }
}

// MARK: - Appearance
private extension DayCell {
    
    func updateActionProgress() {
        guard let day = day else { return }
        if day.isWithinDisplayedMonth {
            self.background.backgroundColor = .black
            if self.actionProgress >= 1 {
                self.background.alpha = 1.0
                self.dayLabel.textColor = .white
            } else if self.actionProgress >= 0.5 {
                self.background.alpha = 0.5
                self.dayLabel.textColor = .white
            }else if self.actionProgress >= 0 {
                self.background.alpha = 0.1
                self.dayLabel.textColor = .black
            } else {
                self.background.alpha = 0
                self.dayLabel.textColor = .black
            }
        }
    }
    
    func updateSelectionStatus() {
        guard let day = day else { return }
        if day.isSelected {
            applySelectedStyle()
        } else {
            applyDefaultStyle(isWithinDisplayedMonth: day.isWithinDisplayedMonth)
        }
    }
    
    func applySelectedStyle() {
//        self.dayLabel.textColor = .white
//        self.backgroundColor = .black
//        self.background.backgroundColor = .black
        self.selectPointView.isHidden = false
        //    selectionBackgroundView.isHidden = isSmallScreenSize
    }
    
    
    func applyDefaultStyle(isWithinDisplayedMonth: Bool) {
        self.dayLabel.textColor = isWithinDisplayedMonth ? .black : UIColor(red: 143/255,
                                                                            green: 155/255,
                                                                            blue: 179/255,
                                                                            alpha: 1.0)
        self.background.backgroundColor = .white
        self.backgroundColor = .white
        self.selectPointView.isHidden = true
    }
}

