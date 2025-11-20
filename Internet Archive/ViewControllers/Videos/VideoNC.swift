//
//  ProfileNC.swift
//  Internet Archive
//
//  Created by Eagle19243 on 5/8/18.
//  Copyright © 2018 Eagle19243. All rights reserved.
//

import UIKit

@MainActor
class VideoNC: BaseNC {

    override func viewDidLoad() {
        super.viewDidLoad()

        gotoVideoVC()
    }

    func gotoVideoVC() {
        guard let videoVC = self.storyboard?.instantiateViewController(withIdentifier: "VideoVC") as? VideoVC else {
            return
        }
        self.viewControllers = [videoVC]
    }

    // MARK: AVPlayerViewControllerDelegate

    /*
     // MARK: - Navigation

     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */

}
