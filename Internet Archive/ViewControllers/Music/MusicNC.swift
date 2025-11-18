//
//  ProfileNC.swift
//  Internet Archive
//
//  Created by Eagle19243 on 5/8/18.
//  Copyright © 2018 Eagle19243. All rights reserved.
//

import UIKit

class MusicNC: BaseNC {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        gotoMusicVC()
    }
    
    func gotoMusicVC() -> Void {
        let musicVC = self.storyboard?.instantiateViewController(withIdentifier: "MusicVC") as! MusicVC
        self.viewControllers = [musicVC]
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
