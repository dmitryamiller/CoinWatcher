//
//  Invalidator.swift
//  CoinWatch
//
//  Created by Dmitry Miller on 8/24/17.
//  Copyright © 2017 Dmitry Miller. All rights reserved.
//

import Foundation

class Invalidator {
    var queue: DispatchQueue = .main
    var interval: TimeInterval = 1 // 1 sec
    var callback: (()->())?
    
    private var scheduled: Bool = false
    
    required init(queue: DispatchQueue = .main, interval: TimeInterval = 1, callback: @escaping (()->())) {
        self.queue = queue
        self.interval = interval
        self.callback = callback
    }
    
    func invalidate() {
        self.queue.async { [weak self] in
            self?.doInvalidate()
        }
    }
    
    private func doInvalidate() {
        if self.scheduled {
            return
        }
        
        self.scheduled = true
        self.queue.asyncAfter(deadline: DispatchTime.now() + self.interval) { [weak self] in
            self?.callback?()
            self?.scheduled = false            
        }        
    }
}
