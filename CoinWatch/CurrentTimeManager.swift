//
//  CurrentTimeManager.swift
//  CoinWatch
//
//  Created by Dmitry Miller on 12/26/17.
//  Copyright © 2017 Dmitry Miller. All rights reserved.
//

import Foundation

class CurrentTimeManager: NSObject {
    public static let instance = CurrentTimeManager()
    
    dynamic private (set) var currentTime: TimeInterval = Date().timeIntervalSince1970
    
    private var timer:Timer!
    
    private override init() {
        super.init()
        self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.currentTime = Date().timeIntervalSince1970
        }
    }
}
