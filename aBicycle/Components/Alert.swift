//
//  Alert.swift
//  aBicycle
//
//  Created by 1 on 8/6/23.
//

import SwiftUI

func showAlert(title: String, msg: String, ConfirmBtnText: String, CancelBtnText: String = "Cancel") -> Bool {
    var result = false
    
    DispatchQueue.main.async {
        let alert = NSAlert()
        if title != "" {
            alert.messageText = title
        }
        alert.informativeText = msg
        alert.addButton(withTitle: ConfirmBtnText)
        alert.addButton(withTitle: CancelBtnText)
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            result = true
        }
    }
    
    return result
}



func showAlertOnlyPrompt(msgType: String? = nil, title: String, msg: String, confirmBtnText: String? = "OK") {
    DispatchQueue.main.async {
        let alert = NSAlert()
        if msgType == "warning" {
            alert.alertStyle = .critical
        }
        if title != "" {
            alert.messageText = title
        }
        alert.informativeText = msg
        
        if let buttonText = confirmBtnText {
            alert.addButton(withTitle: buttonText)
        }
        
        _ = alert.runModal()
    }
}
