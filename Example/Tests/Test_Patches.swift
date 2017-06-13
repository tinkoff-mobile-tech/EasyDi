//
//  Test_Patches.swift
//  EasyDi
//
//  Created by Andrey Zarembo on 20.05.17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation

import UIKit
import XCTest
import EasyDi

protocol ITestPatchObject {
    var intParameter: Int { get }
    var testChild: ChildTestPatchObject? { get }
}

class ChildTestPatchObject {
    var parent: ITestPatchObject?
}

class Test_Patches: XCTestCase {
    
    
    
    class TestObject: NSObject, ITestPatchObject {
        @objc var intParameter: Int = 0
        var testChild: ChildTestPatchObject?
    }
    class TestObject2: NSObject, ITestPatchObject {
        @objc var intParameter: Int = 0
        var testChild: ChildTestPatchObject?
    }
    
    class TestAssembly: Assembly {
        
        var testObject: ITestPatchObject {
            return define(init: TestObject()) {
                $0.intParameter = 10
                $0.testChild = self.childTestObject
            }
        }
        
        var testInteger: Int {
            return define(init: Int(20))
        }
        
        var childTestObject: ChildTestPatchObject {
            return define(init: ChildTestPatchObject()) {
                $0.parent = self.testObject
            }
        }
    }
    
    func testPatchWithSimpleObject() {
        
        let testAssembly = TestAssembly.instance()
        testAssembly.addPatch(for: "testObject") { ()->TestObject in
            let result = TestObject()
            result.intParameter = 30
            return result
        }
        
        let patchedObject = testAssembly.testObject
        XCTAssertEqual(patchedObject.intParameter, 30)
        XCTAssertTrue(patchedObject is TestObject)
        
        testAssembly.removePatch(for: "testObject")
        let testObject = testAssembly.testObject
        XCTAssertEqual(patchedObject.intParameter, 30)
        XCTAssertTrue(testObject is TestObject)
    }
    
    func testPatchWithDefinition() {
        
        let testAssembly = TestAssembly.instance()
        testAssembly.addPatch(for: "testObject") {
            return testAssembly.define(init: TestObject2()) { testObj in
                testObj.intParameter = testAssembly.testInteger
                testObj.testChild = testAssembly.childTestObject
            } as ITestPatchObject
        }
        
        let patchedObject = testAssembly.testObject
        XCTAssertEqual(patchedObject.intParameter, 20)
        XCTAssertTrue(patchedObject is TestObject2)
        XCTAssertNotNil(patchedObject.testChild)
        XCTAssertNotNil(patchedObject.testChild?.parent)
        XCTAssertTrue((patchedObject as? NSObject) == (patchedObject.testChild?.parent as! NSObject?))
        
        testAssembly.removePatch(for: "testObject")
        let testObject = testAssembly.testObject
        XCTAssertEqual(testObject.intParameter, 10)
        XCTAssertTrue(testObject is TestObject)
    }
}

