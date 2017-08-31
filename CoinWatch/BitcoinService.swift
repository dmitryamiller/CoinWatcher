//
//  BitcoinService.swift
//  CoinWatch
//
//  Created by Dmitry Miller on 8/30/17.
//  Copyright © 2017 Dmitry Miller. All rights reserved.
//

import UIKit
import PromiseKit

class BitcoinService: NSObject {
    static let instance = BitcoinService()
    
    private static let minDelay: TimeInterval = 11.0 // sec
    
    private var queue = [ServiceCall]()
    private var currentCall: ServiceCall?
    private var lastExecuted: TimeInterval = 0
    
    
    func schedule(serviceCall: ServiceCall, priority: Bool = false) {
        if priority {
            self.queue.insert(serviceCall, at: 0)
        } else {
            self.queue.append(serviceCall)
        }
        
        self.executeNextCallIfAplicable()
    }
    
    private func executeNextCallIfAplicable() {
        print("Schedule execute next service \(Date())")
        guard self.currentCall == nil else { return }
        
        if let serviceCall = self.queue.first {
            self.currentCall = serviceCall
            let timeDiff = Date().timeIntervalSince1970 - self.lastExecuted
            serviceCall.delay = timeDiff >= BitcoinService.minDelay ? 0 : timeDiff
            
            print("Executing with delay: \(serviceCall.delay)")
            
            let p = Promise<Any> { fulfill, reject in
                serviceCall.callback = { result, error in
                    if let error = error {
                        reject(error)
                    } else if let result = result {
                        fulfill(result)
                    } else {
                        reject(NSError(domain: "bad-reponse", code: 0, userInfo: nil))
                    }
                }
                
                serviceCall.execute()
            }
            
            p.always { [weak self] in
                print("Complete execution: \(Date())")
                self?.lastExecuted = Date().timeIntervalSince1970
                self?.currentCall = nil
                self?.executeNextCallIfAplicable()                
            }
        } else {
            print("Queue empty")
        }
    }
    
    class ServiceCall  {
        static let serviceQueue = DispatchQueue(label: "com.goblin77.CoinEatcher.BitcoinService")
        
        var url: String = ""
        var transform: ((Data) -> Any?)?
        var callback: ((Any?, Error?)->())?
        var delay: TimeInterval = 0
        
        func execute() {
            if self.delay <= 0 {
                ServiceCall.serviceQueue.async { [weak self] in
                    self?.doExecute()
                }
            }else {
                ServiceCall.serviceQueue.asyncAfter(deadline: DispatchTime.now()) { [weak self] in
                    self?.doExecute()
                }
            }
        }
        
        func doExecute() {
            guard let url = URL(string: self.url) else { self.callback?(nil, NSError(domain: "url", code: 0, userInfo: nil)); return }
            let request = URLRequest(url: url)
            let session = URLSession.shared
            
            let dataTask = session.dataTask(with: request) { [weak self] data, response, error in
                if let data = data {
                    if let result = self?.transform?(data) {
                        self?.callback?(result, nil)
                    } else {
                        self?.callback?(nil, NSError(domain: "bad-reponse", code: 0, userInfo: nil))
                    }
                } else {
                    self?.callback?(nil, error)
                }
            }
            
            dataTask.resume()
        }
    }
}

public func jsonRootNodeTransformer(_ data: Data) -> [String : Any]? {
    let res = try? JSONSerialization.jsonObject(with: data, options: [.allowFragments])
    return res as? [String : Any]
}
