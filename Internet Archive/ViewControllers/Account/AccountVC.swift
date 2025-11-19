//
//  ViewController.swift
//  Internet Archive
//
//  Created by Eagle19243 on 5/8/18.
//  Copyright © 2018 Eagle19243. All rights reserved.
//

import UIKit

class AccountVC: UIViewController {

    @IBOutlet weak var txtDescription: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        if let userData = Global.getUserData(),
           let username = userData["username"] as? String {
            txtDescription.text = "You are logged into the Internet Archive as \(username)"
        } else {
            txtDescription.text = "You are logged into the Internet Archive"
        }
    }

    @IBAction func onLogout(_ sender: Any) {
        Global.saveUserData(userData: [
            "username": "",
            "email": "",
            "password": "",
            "logged-in": false

        ])

        let accountNC = self.navigationController as? AccountNC
        accountNC?.gotoLoginVC()
    }

}
