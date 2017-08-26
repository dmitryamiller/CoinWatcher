//
//  UITableView+CoinWatch.swift
//  CoinWatch
//
//  Created by Dmitry Miller on 8/22/17.
//  Copyright © 2017 Dmitry Miller. All rights reserved.
//

import UIKit

extension UITableView {
    public func dequeReusableCell<T:UITableViewCell>(withType type: T.Type) -> T {
        let cellIdentifier = String(describing: type.self)
        return self.dequeueReusableCell(withIdentifier: cellIdentifier) as! T
    }
}
