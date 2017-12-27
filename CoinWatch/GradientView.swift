//
//  GradientView.swift
//  CoinWatch
//
//  Created by Dmitry Miller on 12/26/17.
//  Copyright © 2017 Dmitry Miller. All rights reserved.
//

import UIKit

public class GradientView: UIView {
    
    override public class var layerClass:  AnyClass {
        get {
            return CAGradientLayer.self
        }
    }
    
    @IBInspectable public var angle: Double = 0 {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    @IBInspectable public var firstColor: UIColor? {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    
    @IBInspectable public var secondColor: UIColor? {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    private func commonInit() {
        self.backgroundColor = UIColor.clear
    }
    
    override public func draw(_ rect: CGRect) {
        super.draw(rect)
        self.updateGradientIfApplicable()
    }
    
    private func updateGradientIfApplicable() {
        guard let firstColor = self.firstColor,
            let secondColor = self.secondColor,
            let gradient = self.layer as? CAGradientLayer
            else { return }
        
        gradient.colors = [firstColor.cgColor, secondColor.cgColor]
        let x: Double = self.angle / 360.0
        let a = pow(sinf(Float(2.0 * Double.pi * ((x + 0.75) / 2.0))),2.0);
        let b = pow(sinf(Float(2*Double.pi * ((x+0.0)/2))),2);
        let c = pow(sinf(Float(2*Double.pi * ((x+0.25)/2))),2);
        let d = pow(sinf(Float(2*Double.pi * ((x+0.5)/2))),2);
        
        gradient.endPoint = CGPoint(x: CGFloat(c),y: CGFloat(d))
        gradient.startPoint = CGPoint(x: CGFloat(a),y:CGFloat(b))
    }
}


