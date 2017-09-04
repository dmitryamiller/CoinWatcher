//
//  BusyIndicatorManager.swift
//  CoinWatch
//
//  Created by Dmitry Miller on 9/3/17.
//  Copyright © 2017 Dmitry Miller. All rights reserved.
//

import UIKit

class BusyIndicatorManager: NSObject {
    static let instance = BusyIndicatorManager()
    
    lazy var buzyIndicatorView: UIView = {
        let nib = UINib(nibName: "BusyIndicatorView", bundle: Bundle.main)
        let view = nib.instantiate(withOwner: nil, options: nil).first as! UIView
        view.frame = UIScreen.main.bounds
        return view
    }()
    
    private var isShown = false
    
    func show() {
        guard false == isShown else { return }
        guard let view = UIApplication.shared.keyWindow?.rootViewController?.view else { return }
        
        self.isShown = true
        view.addSubview(self.buzyIndicatorView)
        
    }
    
    func hide() {
        guard self.isShown else { return }
        self.buzyIndicatorView.removeFromSuperview()
        self.isShown = false
        
    }

}
