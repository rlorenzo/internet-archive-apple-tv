//
//  ProfileNC.swift
//  Internet Archive
//
//  Created by Eagle19243 on 5/8/18.
//  Copyright © 2018 Eagle19243. All rights reserved.
//

import UIKit

class AccountNC: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()

        if Global.isLoggedIn() {
            gotoAccountVC()
        } else {
            gotoLoginVC()
        }
    }

    func gotoLoginVC() -> Void {
        let loginVC = self.storyboard?.instantiateViewController(withIdentifier: "LoginVC") as! LoginVC
        self.viewControllers = [loginVC]
    }
    
    func gotoAccountVC() -> Void {
        let accountVC = self.storyboard?.instantiateViewController(withIdentifier: "AccountVC") as! AccountVC
        self.viewControllers = [accountVC]
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
