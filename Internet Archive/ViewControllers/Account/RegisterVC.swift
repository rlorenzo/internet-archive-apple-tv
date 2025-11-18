//
//  RegisterVC.swift
//  Internet Archive
//
//  Created by Eagle19243 on 5/8/18.
//  Copyright © 2018 Eagle19243. All rights reserved.
//
//  Updated for Sprint 6: Async/await migration with typed models
//

import UIKit

@MainActor
class RegisterVC: UIViewController {

    @IBOutlet weak var txtUsername: UITextField!
    @IBOutlet weak var txtEmail: UITextField!
    @IBOutlet weak var txtPassword: UITextField!
    @IBOutlet weak var txtConfirm: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func onRegister(_ sender: Any) {
        guard validate() else {
            return
        }

        guard let email = txtEmail.text, !email.isEmpty,
              let password = txtPassword.text, !password.isEmpty,
              let username = txtUsername.text, !username.isEmpty else {
            return
        }

        AppProgressHUD.sharedManager.show(view: self.view)

        Task {
            do {
                let authResponse = try await APIManager.sharedManager.registerTyped(params: [
                    "email": email,
                    "password": password,
                    "screenname": username,
                    "verified": false
                ])

                AppProgressHUD.sharedManager.hide()

                guard authResponse.isSuccess else {
                    let errorMessage = authResponse.error ?? "Username is already in use"
                    Global.showAlert(title: "Error", message: errorMessage, target: self)
                    return
                }

                Global.saveUserData(userData: [
                    "username": username,
                    "email": email,
                    "password": password,
                    "logged-in": false
                ])

                let alertController = UIAlertController(
                    title: "Action Required",
                    message: "We just sent verification email. Please try to verify your account.",
                    preferredStyle: .alert
                )
                alertController.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                    self.navigationController?.popViewController(animated: true)
                })
                self.present(alertController, animated: true)

            } catch {
                AppProgressHUD.sharedManager.hide()
                let errorMessage = (error as? NetworkError)?.localizedDescription ?? error.localizedDescription
                Global.showAlert(title: "Error", message: errorMessage, target: self)
            }
        }
    }

    @IBAction func onCancel(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }

    func validate() -> Bool {
        guard let username = txtUsername.text, !username.isEmpty else {
            Global.showAlert(title: "Error", message: "Please enter a username", target: self)
            return false
        }

        guard let email = txtEmail.text, !email.isEmpty else {
            Global.showAlert(title: "Error", message: "Please enter an email address", target: self)
            return false
        }

        guard let password = txtPassword.text, !password.isEmpty else {
            Global.showAlert(title: "Error", message: "Please enter a password", target: self)
            return false
        }

        guard let confirmPassword = txtConfirm.text, password == confirmPassword else {
            Global.showAlert(title: "Error", message: "Passwords do not match", target: self)
            return false
        }

        return true
    }
}
