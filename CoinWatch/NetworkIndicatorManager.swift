//
//  NetworkIndicatorManager.swift
//  CoinWatch
//
//  Created by Dmitry Miller on 8/28/17.
//  Copyright © 2017 Dmitry Miller. All rights reserved.
//

import UIKit

class NetworkIndicatorManager: NSObject {
    static let instance = NetworkIndicatorManager()
    
    private var counter: UInt = 0
    
    func show() {
//        DispatchQueue.main.async { [weak self] in
//            let counter = self?.counter ?? 0
//            self?.counter = counter + 1
//            self?.synchWithCounter()
//        }
    }
    
    func hide() {
//        DispatchQueue.main.async { [weak self] in
//            let counter = self?.counter ?? 0
//            self?.counter = max(counter - 1, 0)
//            self?.synchWithCounter()
//        }
    }
    
    private func synchWithCounter() {
        UIApplication.shared.isNetworkActivityIndicatorVisible = self.counter > 0
    }
}
