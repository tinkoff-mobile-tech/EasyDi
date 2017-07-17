//
//  ImageService.swift
//  EasyDi
//
//  Created by Andrey Zarembo on 01.06.17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation
import UIKit

enum ImageServiceError: Error {
    case sessionNotInjected
    case invalidResponse
}

protocol IImageService {
    func loadImage(url: URL, then completion: @escaping NetworkRequestCompletionClosure<UIImage>)
}

class ImageService : IImageService {
    
    var session: IURLSession?
    
    func loadImage(url: URL, then completion: @escaping NetworkRequestCompletionClosure<UIImage>) {
        
        guard let session = self.session else {
            completion(.fail(with: ImageServiceError.sessionNotInjected))
            return
        }
        
        session.load(with: url) { (result) in
         
            guard case let .success(data) = result else {
                completion(result.reFail())
                return
            }
            
            guard let image = UIImage(data: data) else {
                completion(.fail(with: ImageServiceError.invalidResponse))
                return
            }
            
            completion(.success(with: image))
        }
    }
}
