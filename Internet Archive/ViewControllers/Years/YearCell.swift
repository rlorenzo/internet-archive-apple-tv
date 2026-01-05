//
//  YearCell.swift
//  Internet Archive
//
//  Created by mac-admin on 5/29/18.
//  Copyright © 2018 mac-admin. All rights reserved.
//

import UIKit

@MainActor
class YearCell: UITableViewCell {

    @IBOutlet weak var lblYear: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Accessibility setup on MainActor since awakeFromNib is nonisolated
        Task { @MainActor in
            self.isAccessibilityElement = true
            self.accessibilityTraits = .button
        }
    }

    /// Configure the cell with a year
    func configure(with year: String) {
        lblYear.text = year
        accessibilityLabel = "Year \(year)"
        accessibilityHint = "Double-tap to view items from \(year)"
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)

        coordinator.addCoordinatedAnimations({
            if self.isFocused {
                // When focused, use dark text on light background
                self.lblYear.textColor = .black
            } else {
                // When not focused, use label color (adapts to appearance)
                self.lblYear.textColor = .label
            }
        }, completion: nil)
    }
}
