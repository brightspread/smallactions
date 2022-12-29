//
//  RoundedCornerView.swift
//  smallactions
//
//  Created by Jo on 2022/12/17.
//

import UIKit

@IBDesignable
class RoundedCornerView: UIView {
    
    private var shadowLayer: CAShapeLayer!

    @IBInspectable var cornerRadius: CGFloat = 0.0 {
        didSet {
            self.layer.cornerRadius = self.cornerRadius
        }
    }
    
    @IBInspectable var borderWidth: CGFloat = 0.0 {
        didSet {
            self.layer.borderWidth = self.borderWidth
            self.layer.borderColor = CGColor(red: 106/255, green: 106/255, blue: 106/255, alpha: 1.0)
        }
    }
    
    @IBInspectable var hasShadow: Bool = false
    
    override func layoutSubviews() {
        super.layoutSubviews()

        if self.shadowLayer == nil && hasShadow {
            self.shadowLayer = CAShapeLayer()
            self.shadowLayer.path = UIBezierPath(roundedRect: bounds, cornerRadius: 12).cgPath
            self.shadowLayer.fillColor = UIColor.white.cgColor

            self.shadowLayer.shadowColor = UIColor.darkGray.cgColor
            self.shadowLayer.shadowPath = self.shadowLayer.path
            self.shadowLayer.shadowOffset = CGSize(width: 2.0, height: 2.0)
            self.shadowLayer.shadowOpacity = 0.3
            self.shadowLayer.shadowRadius = 2

            self.layer.insertSublayer(self.shadowLayer, at: 0)
        }
    }
}

