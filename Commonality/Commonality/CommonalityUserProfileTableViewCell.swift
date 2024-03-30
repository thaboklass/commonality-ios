//
//  CommonalityUserProfileTableViewCell.swift
//  Commonality
//
//  Created by Thabo David Klass on 06/06/2018.
//  Copyright © 2018 Spreebie, Inc. All rights reserved.
//

import UIKit

// The user profile table view cell
class CommonalityUserProfileTableViewCell: UITableViewCell {
    @IBOutlet weak var commonalityIcon: UIImageView!
    @IBOutlet weak var commonalityTitle: UILabel!
    @IBOutlet weak var commonalityMeta: UILabel!
    @IBOutlet weak var commonalityMetaBackground: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}
