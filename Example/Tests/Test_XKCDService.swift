//
//  Test_XKCDService.swift
//  EasyDi
//
//  Created by Andrey Zarembo
//

import Foundation

import UIKit
import XCTest
import EasyDi
@testable import iOS_Example

class Test_XKCDService: XCTestCase {
    
    func testLoadsStrip() {
    
        
        let session = URLSession(configuration: .default)
        let apiClient = JSONAPIClient()
        apiClient.session = session
        
        let xkcdService = XKCDService()
        xkcdService.apiClient = apiClient
        xkcdService.baseURL = URL(string: "https://xkcd.com")!
        xkcdService.stripURLSuffix = "/info.0.json"
        
        let expectation = self.expectation(description: "")
        
        xkcdService.fetchCurrentStrip { (result) in
            
            switch result {
            case .fail:
                XCTFail()
            case .success(let stripId):
                XCTAssertNotEqual(stripId, 0)
            }
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 10) { (error) in
            XCTAssertNil(error)
        }
    }
    
    func testLoadStrips() {
        
        let session = URLSession(configuration: .default)
        let apiClient = JSONAPIClient()
        apiClient.session = session
        
        let xkcdService = XKCDService()
        xkcdService.apiClient = apiClient
        xkcdService.baseURL = URL(string: "https://xkcd.com")!
        xkcdService.stripURLSuffix = "/info.0.json"
        
        let expectation = self.expectation(description: "")
        
        let requestedCount: Int = 10
        
        xkcdService.fetchStrips(from: 12..<(12+requestedCount)) { (result) in
            
            switch result {
            case .fail:
                XCTFail()
            case .success(let strips):
                XCTAssertEqual(strips.count, requestedCount)
            }
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 10) { (error) in
            XCTAssertNil(error)
        }
    }
    
}

