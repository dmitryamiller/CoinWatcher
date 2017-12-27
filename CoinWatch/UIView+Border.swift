//
//  UIView+Border.swift
//  CoinWatch
//
//  Created by Dmitry Miller on 12/26/17.
//  Copyright © 2017 Dmitry Miller. All rights reserved.
//

import UIKit

extension UIView {
    @IBInspectable
    public var borderWidth: CGFloat {
        get {
            return self.layer.borderWidth
        } set {
            self.layer.borderWidth = self.borderWidth
        }
    }
    
    @IBInspectable
    public var borderColor: UIColor? {
        get {
            guard let borderColor = self.layer.borderColor else { return nil }
            return UIColor(cgColor: borderColor)
        } set {
            self.layer.borderColor = self.borderColor?.cgColor
        }
    }
}
