//
//  ServiceAssembly.swift
//  EasyDi
//
//  Created by Andrey Zarembo
//

import Foundation
import EasyDi

class ServiceAssembly: Assembly {
    
    var xkcdService: IXKCDService {
        return define(scope: .lazySingleton, init: XKCDService()) {
            $0.apiClient = self.apiClient
            $0.baseURL = URL(string: "https://xkcd.com")
            $0.stripURLSuffix = "/info.0.json"
        }
    }
    
    var apiClient: IJSONAPIClient {
        return define(scope: .lazySingleton,init: JSONAPIClient()) {
            $0.session = self.session
        }
    }
    
    var imageService: ImageService {
        return define(scope: .lazySingleton, init: ImageService()) {
            $0.session = self.session
        }
    }
    
    var session: IURLSession {
        return define(scope: .lazySingleton, init: URLSession(configuration: self.sessionConfiguration))
    }
    
    var sessionConfiguration: URLSessionConfiguration {
        return define(scope: .lazySingleton, init: URLSessionConfiguration.default )
    }
}
