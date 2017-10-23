//
//  Test_ProtocolBasedInjection.swift
//  EasyDi
//
//  Created by Andrey Zarembo
//

import Foundation
import XCTest
import EasyDi

protocol TestProtocol {
    
    var intParameter: Int { get }
}

class Test_ProtocolInjection: XCTestCase {
    
    class TestObject: TestProtocol {
        
        var intParameter: Int = 0
    }
    
    class TestAssembly: Assembly {
        
        var testObject: TestProtocol {
            return define(init: TestObject()) {
                $0.intParameter = 10
                return $0
            }
        }
    }
    
    func testProtocolInjection() {
        let testObject = TestAssembly.instance().testObject
        XCTAssertEqual(testObject.intParameter, 10)
    }
}
