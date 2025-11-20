//
//  AppProgressHUD.swift
//  Internet Archive
//
//  Created by mac-admin on 6/13/18.
//  Copyright © 2018 mac-admin. All rights reserved.
//

import UIKit

@MainActor
class AppProgressHUD: NSObject {
    static let sharedManager = AppProgressHUD()

    private var indicator = UIActivityIndicatorView(style: .large)

    func show(view: UIView) {
        indicator.center = view.center
        indicator.hidesWhenStopped = true
        indicator.startAnimating()
        view.addSubview(indicator)
    }

    func hide() {
        indicator.stopAnimating()
        indicator.removeFromSuperview()
    }
}
