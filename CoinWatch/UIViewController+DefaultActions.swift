//
//  UIViewController+DefaultActions.swift
//  CoinWatch
//
//  Created by Dmitry Miller on 8/22/17.
//  Copyright © 2017 Dmitry Miller. All rights reserved.
//

import UIKit

extension UIViewController {
    @IBAction func dismissSelf() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func popSelf() {
        self.navigationController?.popViewController(animated: true)
    }
}
