//
//  IURLService.swift
//  EasyDi
//
//  Created by Andrey Zarembo on 05.06.17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation


enum IURLSessionError: Error {
    case invalidResponse(_: URLResponse?, with: Data?)
}

protocol IURLSession {
    func load(with url: URL, then completion: @escaping NetworkRequestCompletionClosure<Data>)
}
