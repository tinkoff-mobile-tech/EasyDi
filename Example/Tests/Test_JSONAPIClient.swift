//
//  Test_XKCDService.swift
//  EasyDi
//
//  Created by Andrey Zarembo on 31.05.17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation

import UIKit
import XCTest
import EasyDi
@testable import EasyDi_Example

class Test_JSONAPIClient: XCTestCase {

    func testLoadsStrip() {
        
        class SuccessURLSessionMock: IURLSession {
            func load(with url: URL, then completion: @escaping (NetworkResult<Data>) -> Void) {
                let jsonString = "{\"num\":12}"
                let jsonData = jsonString.data(using: .utf8)!
                completion(.success(with: jsonData))
            }
        }
        
        let diContext = DIContext()
        let serviceAssembly = ServiceAssembly.instance(from: diContext)
        serviceAssembly.addPatch(for: "session") {
            return SuccessURLSessionMock()
        }
        
        let apiClient = serviceAssembly.apiClient
        let expectation = self.expectation(description: "")
        
        let url = URL(string: "https://xkcd.com/12/info.0.json")!
        apiClient.loadJSON(from: url) { (result) in
            
            switch result {
            case .fail:
                XCTFail()
            case .success(let jsonDictionary):
                XCTAssertNotNil( jsonDictionary["num"] )
            }
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 10) { (error) in
            XCTAssertNil(error)
        }        
    }

}
