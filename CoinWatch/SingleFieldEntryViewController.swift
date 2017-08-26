//
//  SingleFieldEntryViewController.swift
//  CoinWatch
//
//  Created by Dmitry Miller on 8/26/17.
//  Copyright © 2017 Dmitry Miller. All rights reserved.
//

import UIKit

class SingleFieldEntryViewController: UITableViewController {
    @IBOutlet weak var textField: UITextField!
    
    var isEntryValid:((String?)->(Bool))?
    var didCompleteEntry: ((String?)->())?
    
    var promptText: String?
    var placeholderText: String?
    var entryValue: String?
    
    private var didLoad = false
    private var isFocusPending = false
    
    override func viewDidLoad() {
        self.didLoad = true
        self.textField.placeholder = self.placeholderText
        self.textField.text = self.entryValue
        if self.isFocusPending {
            self.textField.becomeFirstResponder()
            self.isFocusPending = false
        }
    }
        
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.promptText
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.textField.becomeFirstResponder()
    }
    
    // MARK: - misc
    func setFocusToTextField() {
        if self.didLoad {
            self.textField.becomeFirstResponder()
        } else {
            self.isFocusPending = true
        }
    }
}

extension SingleFieldEntryViewController : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.text = textField.text?.trimmingCharacters(in: .whitespaces)
        if self.isEntryValid?(textField.text) ?? false {
            self.didCompleteEntry?(textField.text)
            return true
        }
        
        return false
    }
}
