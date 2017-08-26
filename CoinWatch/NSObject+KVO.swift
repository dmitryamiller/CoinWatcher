//
//  NSObject+KVO.swift
//  CoinWatch
//
//  Created by Dmitry Miller on 8/23/17.
//  Copyright © 2017 Dmitry Miller. All rights reserved.
//

import UIKit

public protocol Watcher : NSObjectProtocol  {
    var handler: (()->()) { get }
    
}

fileprivate protocol MutableWatcher : Watcher {
    var handler: (() -> ()) { get set }
}

public extension NSObject {
    struct WatcherInternals {
        static var watchersKey  = "watchers"
        static var kvoContext: Int = 1
    }
    
    fileprivate class SinglePropertyWatcher : NSObject, MutableWatcher {
        private var object: NSObject
        private var propertyName:String
        var handler: (()->())
        
        required init(object: NSObject, propertyName:String, handler:@escaping (()->())) {
            self.object = object
            self.propertyName = propertyName
            self.handler = handler
            super.init()
            
            // start observing
            self.object.addObserver(self, forKeyPath: self.propertyName, options: [.initial, .new], context: &WatcherInternals.kvoContext)
        }
        
        deinit {
            // stop observing
            self.object.removeObserver(self, forKeyPath: self.propertyName, context: &WatcherInternals.kvoContext)
        }
        
        // MARK: - KVO
        override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
            DispatchQueue.main.async { [weak self] in
                self?.handler()
            }
        }
    }
    
    fileprivate class MultiplePropertyWatcher : NSObject, Watcher  {
        static let CoalescingTimeInterval = TimeInterval(0.02) // 50 fps
        
        internal var handler: (() -> ())
        private var object: NSObject
        private var propertyNames: [String]
        private var watcherItems: [Watcher]
        private var coalescing: Bool
        
        
        private var coalescingHandleFireScheduled: Bool = false
        
        required init(with object: NSObject, propertyNames: [String], handler: @escaping (()->()), coalescing: Bool) {
            self.object = object
            self.propertyNames = propertyNames
            self.coalescing = coalescing
            self.handler = handler
            self.watcherItems = [Watcher]()
            
            super.init()
            
            for propertyName in self.propertyNames {
                self.object.addObserver(self, forKeyPath: propertyName, options: [.initial, .new], context: &WatcherInternals.kvoContext)
            }
        }
        
        deinit {
            for propertyName in self.propertyNames {
                self.object.removeObserver(self, forKeyPath: propertyName, context: &WatcherInternals.kvoContext)
            }
        }
        
        // MARK: - KVO
        override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
            if self.coalescing {
                self.callCoalescingHandler()
            } else {
                self.callHandler()
            }
        }
        
        // MARK: - Misc functions
        private func callCoalescingHandler() {
            if self.coalescingHandleFireScheduled {
                return
            }
            
            self.coalescingHandleFireScheduled = true
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + MultiplePropertyWatcher.CoalescingTimeInterval) { [weak self] in
                self?.handler()
                self?.coalescingHandleFireScheduled = false
            }
        }
        
        private func callHandler() {
            DispatchQueue.main.async { [weak self] in
                self?.handler()
            }
        }
    }
    
    private var watchers:Array<Watcher>? {
        get {
            return objc_getAssociatedObject(self, &WatcherInternals.watchersKey) as? Array<Watcher>
        } set {
            
            objc_setAssociatedObject(self, &WatcherInternals.watchersKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    func watch(object: NSObject, propertyName:String, handler: @escaping (()->()))  {
        var newWatchers = [Watcher]()
        
        if let watchers = self.watchers {
            newWatchers.append(contentsOf: watchers)
        }
        
        let watcher  = SinglePropertyWatcher(object: object, propertyName: propertyName, handler: handler)
        newWatchers.append(watcher)
        self.watchers = newWatchers
    }
    
    func watch(object: NSObject, propertyNames: [String], coalescing: Bool = true, handler: @escaping (()->())) {
        if propertyNames.count == 0 {
            print("no properties are being watched")
        }
        
        var newWatchers = [Watcher]()
        
        if let watchers = self.watchers {
            newWatchers.append(contentsOf: watchers)
        }
        
        let watcher = MultiplePropertyWatcher(with: object, propertyNames: propertyNames, handler: handler, coalescing: coalescing)
        newWatchers.append(watcher)
        self.watchers = newWatchers
    }
    
    func unwatch(watcher : Watcher?) {
        guard let watcher = watcher,
            var watchers = self.watchers
            else { return }
        
        if let index = watchers.index(where: { $0 === watcher }) {
            watchers.remove(at: index)
            self.watchers = watchers.count > 0 ? watchers : nil
        }
    }
    
    func unwatchAll() {
        self.watchers = nil
    }
}
