//
//  Test_Substitutiones.swift
//  EasyDi
//
//  Created by Andrey Zarembo
//

import Foundation
import XCTest
import EasyDi

fileprivate protocol ITestSubstitutionObject {
    var intParameter: Int { get }
    var testChild: ChildTestSubstitutionObject? { get }
}

fileprivate class ChildTestSubstitutionObject {
    var parent: ITestSubstitutionObject?
}

class Test_Substitutions: XCTestCase {
    fileprivate class TestObject: NSObject, ITestSubstitutionObject {
        @objc var intParameter: Int = 0
        var testChild: ChildTestSubstitutionObject?
    }
    
    fileprivate class TestObject2: NSObject, ITestSubstitutionObject {
        @objc var intParameter: Int = 0
        var testChild: ChildTestSubstitutionObject?
    }
    
    fileprivate class TestAssembly: Assembly {
        var testObject: ITestSubstitutionObject {
            return define(init: TestObject()) {
                $0.intParameter = 10
                $0.testChild = self.childTestObject
                return $0
            }
        }
        
        var testInteger: Int {
            return define(init: Int(20))
        }
        
        var childTestObject: ChildTestSubstitutionObject {
            return define(init: ChildTestSubstitutionObject()) {
                $0.parent = self.testObject
                return $0
            }
        }
    }
    
    func testSubstitutionWithSimpleObject() {
        let context = DIContext()
        let testAssembly = TestAssembly.instance(from: context)
        testAssembly.addSubstitution(for: "testObject") { ()->TestObject in
            let result = TestObject()
            result.intParameter = 30
            return result
        }
        
        let SubstitutionedObject = testAssembly.testObject
        XCTAssertEqual(SubstitutionedObject.intParameter, 30)
        XCTAssertTrue(SubstitutionedObject is TestObject)
        
        testAssembly.removeSubstitution(for: "testObject")
        let testObject = testAssembly.testObject
        XCTAssertEqual(testObject.intParameter, 10)
        XCTAssertTrue(testObject is TestObject)
    }
    
    func testSubstitutionWithDefinition() {
        let context = DIContext()
        let testAssembly = TestAssembly.instance(from: context)
        testAssembly.addSubstitution(for: "testObject") {
            return testAssembly.define(init: TestObject2()) { testObj in
                testObj.intParameter = testAssembly.testInteger
                testObj.testChild = testAssembly.childTestObject
                return testObj
                } as ITestSubstitutionObject
        }
        
        let SubstitutionedObject = testAssembly.testObject
        XCTAssertEqual(SubstitutionedObject.intParameter, 20)
        XCTAssertTrue(SubstitutionedObject is TestObject2)
        XCTAssertNotNil(SubstitutionedObject.testChild)
        XCTAssertNotNil(SubstitutionedObject.testChild?.parent)
        XCTAssertTrue((SubstitutionedObject as? NSObject) == (SubstitutionedObject.testChild?.parent as! NSObject?))
        
        testAssembly.removeSubstitution(for: "testObject")
        let testObject = testAssembly.testObject
        XCTAssertEqual(testObject.intParameter, 10)
        XCTAssertTrue(testObject is TestObject)
    }
}

