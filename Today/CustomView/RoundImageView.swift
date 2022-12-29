//
//  RoundImageView.swift
//  smallactions
//
//  Created by Jo on 2022/12/17.
//

import UIKit

@IBDesignable
class RoundImageView: UIImageView {
    
    private var shadowLayer: CAShapeLayer!

    override func layoutSubviews() {
        super.layoutSubviews()

        if self.shadowLayer == nil {
            self.shadowLayer = CAShapeLayer()
            self.shadowLayer.path = UIBezierPath(roundedRect: bounds, cornerRadius: self.bounds.height/2).cgPath
            self.shadowLayer.fillColor = UIColor.clear.cgColor

            self.shadowLayer.shadowColor = UIColor.black.cgColor
            self.shadowLayer.shadowPath = self.shadowLayer.path
            self.shadowLayer.shadowOffset = CGSize(width: 1.0, height: 1.0)
            self.shadowLayer.shadowOpacity = 0.2
            self.shadowLayer.shadowRadius = 2

            self.layer.insertSublayer(self.shadowLayer, at: 0)
        }
    }
}
