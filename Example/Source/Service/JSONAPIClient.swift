//
//  JSONAPIClient.swift
//  EasyDi
//
//  Created by Andrey Zarembo
//

import Foundation

enum JSONAPIClientError: Error {
    case sessionNotInjected
    case invalidResponse(with: Data)
}

enum NetworkResult<DataType> {
    case fail(with: Error)
    case success(with: DataType)
    
    func reFail<OtherDataType>() -> NetworkResult<OtherDataType> {
        guard case let .fail(error) = self else {
            fatalError("Can reFail onlty error")
        }
        return NetworkResult<OtherDataType>.fail(with: error)
    }
}

typealias NetworkRequestCompletionClosure<DataType> = (_ result: NetworkResult<DataType>) -> Void

protocol IJSONAPIClient {
    typealias JSONDictionary = [String: Any]    
    func loadJSON(from url: URL, then completion: @escaping NetworkRequestCompletionClosure<JSONDictionary>)
}

class JSONAPIClient: IJSONAPIClient {

    var session: IURLSession?
    
    func loadJSON(from url: URL, then completion: @escaping NetworkRequestCompletionClosure<JSONDictionary>) {
        
        guard let session = self.session else {
            completion(.fail(with: JSONAPIClientError.sessionNotInjected))
            return
        }
        
        session.load(with: url) { (result) in
            
            guard case let .success(data) = result else {
                completion(result.reFail())
                return
            }
            
            guard
                let json = try? JSONSerialization.jsonObject(with: data, options: []),
                let jsonDictionary = json as? [String: Any]
                else {
                    
                    completion(.fail(with: JSONAPIClientError.invalidResponse(with: data)))
                    return
            }
            
            completion(.success(with: jsonDictionary))
        }
    }
}
