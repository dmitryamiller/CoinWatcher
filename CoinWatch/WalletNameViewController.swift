//
//  WalletNameViewController.swift
//  CoinWatch
//
//  Created by Dmitry Miller on 8/23/17.
//  Copyright © 2017 Dmitry Miller. All rights reserved.
//

import UIKit
import RealmSwift


class WalletNameViewController: UITableViewController, UITextFieldDelegate {
    @IBOutlet weak var textField: UITextField!
    
    var name: String?
    var didEnterName: ((String)->())?
    
    override func viewDidLoad() {
        self.textField.text = self.name
        self.textField.becomeFirstResponder()
    }
    
    // MARK: - 
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.textField.becomeFirstResponder()
    }
    
    // MARK: - UITextFieldDelegate
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.name = (textField.text ?? "").trimmingCharacters(in: .whitespaces)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let name = (textField.text ?? "").trimmingCharacters(in: .whitespaces)
        if name.characters.count == 0 {
            return false
        }
        
        self.name = name
        self.didEnterName?(name)
        
        return true
    }
}
