//
//  FeedViewAssembly.swift
//  EasyDi
//
//  Created by Andrey Zarembo on 31.05.17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation
import EasyDi

class FeedViewAssembly: Assembly {
    
    lazy var serviceAssembly: ServiceAssembly = self.context.assembly()
    
    func inject(into feedViewController: FeedViewController) {
        let _:FeedViewController = define(init: feedViewController) {
            $0.xkcdService = self.serviceAssembly.xkcdService
            $0.imageService = self.serviceAssembly.imageService
        }
    }
}
