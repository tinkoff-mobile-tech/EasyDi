//
//  IURLService.swift
//  EasyDi
//
//  Created by Andrey Zarembo
//

import Foundation


enum IURLSessionError: Error {
    case invalidResponse(_: URLResponse?, with: Data?)
}

protocol IURLSession {
    func load(with url: URL, then completion: @escaping NetworkRequestCompletionClosure<Data>)
}
