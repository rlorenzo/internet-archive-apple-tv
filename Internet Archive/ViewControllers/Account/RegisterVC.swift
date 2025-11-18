//
//  SignupVC.swift
//  Internet Archive
//
//  Created by Eagle19243 on 5/8/18.
//  Copyright © 2018 Eagle19243. All rights reserved.
//

import UIKit

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
        if !validate() {
            return
        }
        
        AppProgressHUD.sharedManager.show(view: self.view)
        
        let email = txtEmail.text!
        let password = txtPassword.text!
        let username = txtUsername.text!
        
        APIManager.sharedManager.register(params: [
            "email" : email,
            "password" : password,
            "screenname" : username,
            "verified" : false
        ]) { (data) in
            AppProgressHUD.sharedManager.hide()
            
            if data == nil {
                Global.showAlert(title: "Error", message: "Server error", target: self)
                return
            }
            
            if data!["success"] as! Bool {
                Global.saveUserData(userData: [
                    "username" : "username",
                    "email" : "email",
                    "password" : "password",
                    "logged-in" : false
                    ])
                
                let alertController = UIAlertController(title: "Action Required", message: "We just sent verification email. Please try to verify your account.", preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "OK", style: .default) {action in
                    self.navigationController?.popViewController(animated: true)
                })
                self.present(alertController, animated: true)
            } else {
                Global.showAlert(title: "Error", message: "Username is already in use", target: self)
            }
            
            
        }
    }
    
    @IBAction func onCancel(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    func validate() -> Bool {
        if txtUsername.text!.isEmpty {
            Global.showAlert(title: "Error", message: "Please enter a username", target: self)
            return false
        }
        
        if txtEmail.text!.isEmpty {
            Global.showAlert(title: "Error", message: "Please enter an email address", target: self)
            return false
        }
        
        if txtPassword.text!.isEmpty {
            Global.showAlert(title: "Error", message: "Please enter a password", target: self)
            return false
        }
        
        if txtPassword.text! != txtConfirm.text! {
            Global.showAlert(title: "Error", message: "Incorrect password", target: self)
            return false
        }
        
        return true
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
