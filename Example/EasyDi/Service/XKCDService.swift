//
//  XKCDService.swift
//  EasyDi
//
//  Created by Andrey Zarembo on 29.05.17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation
import Dispatch

enum XKCDServiceError: Error {
    case apiClientNotInjected
    case failedToCreateURL
    case invalidResponse
}

protocol IXKCDService {
    
    func fetchCurrentStrip(then completion: @escaping NetworkRequestCompletionClosure<Int>)
    func fetchStrips(from range: CountableRange<Int>, then completion: @escaping NetworkRequestCompletionClosure<[XKCDStrip]>)
}

class XKCDService : IXKCDService {
    
    var baseURL: URL?
    var stripURLSuffix: String?
    var apiClient: IJSONAPIClient?
    
    func fetchCurrentStrip(then completion: @escaping NetworkRequestCompletionClosure<Int>) {
        
        guard let baseURL = self.baseURL, let stripURLSuffix = self.stripURLSuffix else {
            completion(.fail(with: XKCDServiceError.failedToCreateURL))
            return
        }
        
        let url = baseURL.appendingPathComponent(stripURLSuffix)
        
        self.fetchStrip(with: url) { (result) in
            
            guard case let .success(strip) = result else {
                completion(result.reFail())
                return
            }
            
            completion(.success(with: strip.id))
        }
    }
    
    func fetchStrips(from range: CountableRange<Int>, then completion: @escaping NetworkRequestCompletionClosure<[XKCDStrip]>) {
        
        guard let _ = self.apiClient else {
            completion(.fail(with: XKCDServiceError.apiClientNotInjected))
            return
        }
        
        let group = DispatchGroup()
        var loadedStrips = [XKCDStrip]()
        
        for stripId in range {
            group.enter()
            self.fetchStrip(with: stripId, then: { (result) in
                if case let .success(strip) = result {
                    loadedStrips.append(strip)
                }
                group.leave()
            })
        }
        
        group.notify(queue: DispatchQueue.global(qos: .userInteractive)) { 
            completion(.success(with: loadedStrips.sorted{ $0.id > $1.id }))
        }
    }
    
    func fetchStrip(with id: Int, then completion: @escaping NetworkRequestCompletionClosure<XKCDStrip>) {
        
        guard let baseURL = self.baseURL, let stripURLSuffix = self.stripURLSuffix else {
            completion(.fail(with: XKCDServiceError.failedToCreateURL))
            return
        }
        
        let url = baseURL.appendingPathComponent("/\(id)").appendingPathComponent(stripURLSuffix)
        
        self.fetchStrip(with: url, then: completion)
    }
    
    func fetchStrip(with url: URL, then completion: @escaping NetworkRequestCompletionClosure<XKCDStrip>) {
        
        guard let apiClient = self.apiClient else {
            completion(.fail(with: XKCDServiceError.apiClientNotInjected))
            return
        }
        
        apiClient.loadJSON(from: url) { (result) in
            switch result {
            case .fail(let error):
                completion(.fail(with: error))
            case .success(let jsonDictionary):
                guard let xkcdStrip = jsonDictionary.xkcdStrip else {
                    completion(.fail(with: XKCDServiceError.invalidResponse))
                    return
                }
                completion(.success(with: xkcdStrip))
            }
        }
    }
    
}
