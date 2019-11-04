//
//  Test_ImplicitlyUnwrappedOptional.swift
//  EasyDi
//
//  Created by a.teplyakov on 14/08/2018.
//  Copyright © 2018 AndreyZarembo. All rights reserved.
//

import Foundation
import XCTest
import EasyDi
/*
 As part of fully implementing (SE–0054), ImplicitlyUnwrappedOptional<T> is now an unavailable typealias of Optional<T>. Declarations annotated with ‘!’ have the type Optional<T>. If an expression involving one of these values will not compile successfully with the type Optional<T>, it is implicitly unwrapped, producing a value of type T. In some cases this will cause code that previously compiled to require updating. Please see this blog post for more information: (Reimplementation of Implicitly Unwrapped Optionals). (33272674)
 
 https://swift.org/blog/iuo/
 */
class Test_ImplicitlyUnwrappedOptional: XCTestCase {
    fileprivate class ObjectGraphAssembly: Assembly {
        var testObject: TestObject {
            return define(init: TestObject.object()) {
                return $0
            }
        }
    }
    
    fileprivate class TestObject {
        class func object() -> TestObject! {
            return TestObject()
        }
    }
    
    func testClassInitializator() {
        let testObject = ObjectGraphAssembly.instance().testObject
        XCTAssertNotNil(testObject)
    }
}
