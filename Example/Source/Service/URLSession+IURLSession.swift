//
//  URLSession+IURLSession.swift
//  EasyDi
//
//  Created by Andrey Zarembo on 05.06.17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation


extension URLSession: IURLSession {
    
    func load(with url: URL, then completion: @escaping NetworkRequestCompletionClosure<Data>) {
        
        let task = self.dataTask(with: url) { (data, response, error) in
            
            if let error = error {
                completion(.fail(with: error))
                return
            }
            
            guard let nonNilData = data else {
                    
                    completion(.fail(with: IURLSessionError.invalidResponse(response, with: data)))
                    return
            }
            
            completion(.success(with: nonNilData))
            
        }
        task.resume()
    }
}
