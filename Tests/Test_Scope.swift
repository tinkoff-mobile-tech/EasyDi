//
//  Test_Scope.swift
//  EasyDi
//
//  Created by Andrey Zarembo
//

import Foundation
import XCTest
import EasyDi

class Test_Scope: XCTestCase {

    // Test that Singleton object initializes only once
    func testSingleton() {
        
        // SETUP
        class TestSingletonObject: NSObject {
            
            @objc static var initCallsCount: Int = 0
            override init() {
                super.init()
                TestSingletonObject.initCallsCount += 1
            }
            
            @objc var injected: Bool = false
        }
        
        class SingletonAssembly: Assembly {
            
            var singleton: TestSingletonObject {
                return define(scope: .lazySingleton, init: TestSingletonObject()) {
                    $0.injected = true
                }
            }
        }
        
        // TEST
        let singletonInstance1 = SingletonAssembly.instance().singleton
        XCTAssertTrue(singletonInstance1.injected)
        
        let singletonInstance2 = SingletonAssembly.instance().singleton
        XCTAssertTrue(singletonInstance2.injected)
        XCTAssertEqual(singletonInstance1, singletonInstance2)
        XCTAssertEqual(TestSingletonObject.initCallsCount, 1)
    }
    
    
    // Test that ObjectGraph object creates only 1 instance per graph
    func testObjectGraph() {
        
        
        // Setup
        class ParentObject: NSObject {
            
            @objc static var initCallsCount: Int = 0
            override init() {
                super.init()
                ParentObject.initCallsCount += 1
            }
            @objc var child: ChildObject? = nil
        }
        
        class ChildObject: NSObject {
            @objc weak var parent: ParentObject? = nil
        }
        
        class ObjectGraphAssembly: Assembly {
            
            var parentObject: ParentObject {
                return define(init: ParentObject()) {
                    $0.child = self.childObject
                }
            }
            
            var childObject: ChildObject {
                return define(init: ChildObject()) {
                    $0.parent = self.parentObject
                }
            }
        }
        
        // Test
        let parentInstance1 = ObjectGraphAssembly.instance().parentObject
        XCTAssertEqual(ParentObject.initCallsCount, 1)
        XCTAssertNotNil(parentInstance1.child)
        XCTAssertNotNil(parentInstance1.child?.parent)
        XCTAssertEqual(parentInstance1.child?.parent, parentInstance1)
        
        let _ = ObjectGraphAssembly.instance().parentObject
        XCTAssertEqual(ParentObject.initCallsCount, 2)
    }
    
    // Test that prototype recreated each time
    func testPrototype() {
        
        // Setup
        class PrototypeObject: NSObject {
            
            @objc static var initCallsCount: Int = 0
            override init() {
                super.init()
                PrototypeObject.initCallsCount += 1
            }
            @objc var child: SupportChildObject? = nil
        }
        
        class SupportChildObject: NSObject {
            @objc var parent: PrototypeObject? = nil
        }
        
        class ObjectGraphAssembly: Assembly {
            
            var prototypeObject: PrototypeObject {
                return define(scope: .prototype, init: PrototypeObject()) {
                    $0.child = self.childObject
                }
            }
            
            var childObject: SupportChildObject {
                return define(init: SupportChildObject()) {
                    $0.parent = self.prototypeObject
                }
            }
        }

        
        // Test
        let prototypeInstance1 = ObjectGraphAssembly.instance().prototypeObject
        XCTAssertEqual(PrototypeObject.initCallsCount, 2)
        XCTAssertNotNil(prototypeInstance1.child)
        XCTAssertNotNil(prototypeInstance1.child?.parent)
        XCTAssertNotEqual(prototypeInstance1.child?.parent, prototypeInstance1)
    }
}

