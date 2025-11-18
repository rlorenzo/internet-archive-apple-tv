//
//  FavoriteNC.swift
//  Internet Archive
//
//  Created by Eagle19243 on 5/20/18.
//  Copyright © 2018 Eagle19243. All rights reserved.
//

import UIKit

class FavoriteNC: BaseNC {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        gotoFavoriteVC()
    }
    
    func gotoFavoriteVC() -> Void {
        let favoriteVC = self.storyboard?.instantiateViewController(withIdentifier: "FavoriteVC") as! FavoriteVC
        self.viewControllers = [favoriteVC]
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
