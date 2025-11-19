//
//  LoginVC.swift
//  Internet Archive
//
//  Created by Eagle19243 on 5/8/18.
//  Copyright © 2018 Eagle19243. All rights reserved.
//
//  Updated for Sprint 6: Async/await migration with typed models
//

import UIKit

@MainActor
class LoginVC: UIViewController {

    @IBOutlet weak var txtEmail: UITextField!
    @IBOutlet weak var txtPassword: UITextField!

    @IBAction func onLogin(_ sender: Any) {
        guard validate() else {
            return
        }

        guard let email = txtEmail.text, !email.isEmpty,
              let password = txtPassword.text, !password.isEmpty else {
            return
        }

        AppProgressHUD.sharedManager.show(view: self.view)

        Task {
            do {
                // Login with typed response
                let authResponse = try await APIManager.sharedManager.loginTyped(email: email, password: password)

                guard authResponse.isSuccess else {
                    AppProgressHUD.sharedManager.hide()
                    let errorMessage = authResponse.error ?? "Login failed"
                    Global.showAlert(title: "Error", message: errorMessage, target: self)
                    return
                }

                // Get account info with typed response
                let accountInfo = try await APIManager.sharedManager.getAccountInfoTyped(email: email)
                AppProgressHUD.sharedManager.hide()

                guard let values = accountInfo.values,
                      let username = values.screenname else {
                    Global.showAlert(title: "Error", message: "Failed to retrieve account information", target: self)
                    return
                }

                Global.saveUserData(userData: [
                    "username": username,
                    "email": email,
                    "password": password,
                    "logged-in": true
                ])

                if let accountNC = self.navigationController as? AccountNC {
                    accountNC.gotoAccountVC()
                }

            } catch {
                AppProgressHUD.sharedManager.hide()
                let errorMessage = (error as? NetworkError)?.localizedDescription ?? error.localizedDescription
                Global.showAlert(title: "Error", message: errorMessage, target: self)
            }
        }
    }

    func validate() -> Bool {
        guard let email = txtEmail.text, !email.isEmpty else {
            Global.showAlert(title: "Error", message: "Please enter an email address", target: self)
            return false
        }

        guard let password = txtPassword.text, !password.isEmpty else {
            Global.showAlert(title: "Error", message: "Please enter a password", target: self)
            return false
        }

        return true
    }
}
