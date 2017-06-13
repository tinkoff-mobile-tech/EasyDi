//
//  Test_Injections.swift
//  EasyDi
//
//  Created by Andrey Zarembo-godzyatskiy on 28.04.17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation

import UIKit
import XCTest
import EasyDi

class Test_Injection: XCTestCase {

    class TestObject {
        
        var intParameter: Int = 0
        var stringParamter: String = ""
        var arrayParameter: [String] = []
        
        weak var selfParameter: TestObject? = nil
    }
    
    func testInitWithInjection() {
        
        class TestAssembly: Assembly {
            
            var testObject: TestObject {
                return define(init: TestObject()) {
                    $0.intParameter = 10
                    $0.stringParamter = "TestString"
                    $0.arrayParameter = ["a","b","c"]
                }
            }
        }
        
        // Test
        let testObject = TestAssembly.instance().testObject
        XCTAssertEqual(testObject.intParameter, 10)
        XCTAssertEqual(testObject.stringParamter, "TestString")
        XCTAssertEqual(testObject.arrayParameter, ["a","b","c"])
    }
 
    func testInjectionInExistingObject(){
        
        class TestAssembly: Assembly {
            func inject(into testObject: TestObject) {
                let _:TestObject = define(init: testObject) {
                    $0.intParameter = 10
                    $0.stringParamter = "TestString"
                    $0.arrayParameter = ["a","b","c"]
                }
            }
        }
        
        // Test
        let testObject = TestObject()
        TestAssembly.instance().inject(into: testObject)
        XCTAssertEqual(testObject.intParameter, 10)
        XCTAssertEqual(testObject.stringParamter, "TestString")
        XCTAssertEqual(testObject.arrayParameter, ["a","b","c"])
    }
    
    func testReinjectionWithKey() {
        
        class TestAssembly: Assembly {
            
            func inject(into testObject: TestObject) {
                let _:TestObject = define(key: "testObject",init: testObject) {
                    $0.intParameter = 10
                    $0.stringParamter = "TestString"
                    $0.arrayParameter = ["a","b","c"]
                    $0.selfParameter = self.testObject
                }
            }
            
            var testObject: TestObject {
                return define(key: "testObject", init: TestObject())
            }
        }
        
        // Test
        let testObject = TestObject()
        TestAssembly.instance().inject(into: testObject)
        XCTAssertEqual(testObject.intParameter, 10)
        XCTAssertEqual(testObject.stringParamter, "TestString")
        XCTAssertEqual(testObject.arrayParameter, ["a","b","c"])
        XCTAssertTrue(testObject === testObject.selfParameter)
        
    }
}
