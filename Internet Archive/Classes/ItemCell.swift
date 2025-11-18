//
//  ItemCell.swift
//  Internet Archive
//
//  Created by Eagle19243 on 5/8/18.
//  Copyright © 2018 Eagle19243. All rights reserved.
//

import UIKit

class ItemCell: UICollectionViewCell {
    @IBOutlet weak var itemImage: UIImageView!
    @IBOutlet weak var itemTitle: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        itemImage.adjustsImageWhenAncestorFocused = true
        itemImage.clipsToBounds = false
    }
    
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        coordinator.addCoordinatedAnimations({
//            if self.isFocused {
//                self.itemImage.frame = CGRect(x: -17.5, y: -17.5, width: self.itemImage.frame.width + 35, height: self.itemImage.frame.height + 35)
//                self.itemImage.layer.shadowOpacity = 1
//            } else {
//                self.itemImage.frame = CGRect(x: 0, y: 0, width: self.itemImage.frame.width - 35, height: self.itemImage.frame.height - 35)
//                self.itemImage.layer.shadowOpacity = 0
//            }
        }, completion: nil)
    }
}
