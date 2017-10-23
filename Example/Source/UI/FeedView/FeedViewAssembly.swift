//
//  FeedViewAssembly.swift
//  EasyDi
//
//  Created by Andrey Zarembo
//

import Foundation
import EasyDi

class FeedViewAssembly: Assembly {
    
    lazy var serviceAssembly: ServiceAssembly = self.context.assembly()
    
    func inject(into feedViewController: FeedViewController) {
        defineInjection(into: feedViewController) {
            $0.xkcdService = self.serviceAssembly.xkcdService
            $0.imageService = self.serviceAssembly.imageService
            return $0
        }
    }
}
