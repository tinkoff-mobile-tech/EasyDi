//
//  XKCDStripCell.swift
//  EasyDi
//
//  Created by Andrey Zarembo on 01.06.17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation
import UIKit
import Dispatch

class XKCDStripCell: UITableViewCell {
    
    @IBOutlet var titleLabel: UILabel?
    @IBOutlet var altLabel: UILabel?
    @IBOutlet var stripImage: UIImageView?
    
    @objc var lastShownStripId: Int = 0
    
    func display(_ strip: XKCDStrip) {
        
        guard self.lastShownStripId != strip.id else {
            return
        }
        
        self.titleLabel?.text = "#\(strip.id) \(strip.title)"
        self.altLabel?.text = strip.notes
        self.stripImage?.image = nil
        self.lastShownStripId = strip.id
    }
    
    @objc func display(image: UIImage) {
        self.stripImage?.image = image
    }
    
}
