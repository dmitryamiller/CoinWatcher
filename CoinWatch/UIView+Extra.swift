//
//  UIView+Extra.swift
//  CoinWatch
//
//  Created by Dmitry Miller on 9/3/17.
//  Copyright © 2017 Dmitry Miller. All rights reserved.
//

import UIKit

@IBDesignable
extension UIView {
    @IBInspectable var cornerRadius: CGFloat {
        get {
            return self.layer.cornerRadius
        } set {
            self.layer.cornerRadius = newValue
        }
    }
}
