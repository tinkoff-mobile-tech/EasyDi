//
//  Test_StructsInjection.swift
//  EasyDi_Example
//
//  Created by Andrey Zarembo
//

import Foundation
import XCTest
import EasyDi

protocol TestStructsInjectionProtocol {
    var intValue: Int? { get }
    var stringValue: String? { get }
}

protocol TestStructProtocol {
    var anotherStruct: TestStructProtocol? { get }
}

class Test_StructsInjection: XCTestCase {
    
    func testInjectionIntoStructure() {
        
        struct TestStruct: TestStructsInjectionProtocol {
            var intValue: Int?
            var stringValue: String?
        }
        
        class TestAssembly: Assembly {
            
            var testObject: TestStructsInjectionProtocol {
                return define(init: TestStruct()) {
                    $0.intValue = 10
                    $0.stringValue = "TestString"
                }
            }
        }
        
        let diContext = DIContext()
        let testAssembly = TestAssembly.instance(from: diContext)
        
        let object = testAssembly.testObject
        
        XCTAssertEqual(object.intValue, 10)
        XCTAssertEqual(object.stringValue, "TestString")
    }
    
    func testCrossStructureInjections() {
        
        struct TestStructA: TestStructProtocol {
            var anotherStruct: TestStructProtocol?
        }
        
        struct TestStructB: TestStructProtocol {
            var anotherStruct: TestStructProtocol?
        }
        
        class TestAssembly: Assembly {
            
            var structA: TestStructProtocol {
                return define(init: TestStructA()) {
                    $0.anotherStruct = self.structB
                }
            }
            
            var structB: TestStructProtocol {
                return define(init: TestStructB()) {
                    $0.anotherStruct = self.structA
                }
            }
        }
        
        let diContext = DIContext()
        let testAssembly = TestAssembly.instance(from: diContext)
        
        let object = testAssembly.structA
        
        XCTAssertNotNil(object)
        XCTAssertNotNil(object.anotherStruct)
        XCTAssertNotNil(object.anotherStruct?.anotherStruct)
    }
    
}
