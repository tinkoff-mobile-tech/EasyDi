//
//  Test_SingletoneDuplication.swift
//  EasyDi-iOS-Tests
//
//  Created by Andrey Konoplyankin on 29.03.2021.
//  Copyright © 2021 AndreyZarembo. All rights reserved.
//

import XCTest
@testable import EasyDi

fileprivate class SomeObjectA {
    let objectB: SomeObjectB
    
    init(objectB: SomeObjectB) {
        self.objectB = objectB
    }
}

fileprivate class SomeObjectB {
    var objectA: SomeObjectA?
}

fileprivate class TestAssembly: Assembly {
    var objectA: SomeObjectA {
        return define(scope: .lazySingleton, init: SomeObjectA(objectB: self.objectB))
    }
    
    var objectB: SomeObjectB {
        return define(scope: .lazySingleton, init: SomeObjectB()) {
            $0.objectA = self.objectA
            return $0
        }
    }
}

final class Test_SingletonDuplication: XCTestCase {
    func testSingletonDuplication() {
        let context = DIContext()
        let assembly = TestAssembly.instance(from: context)
        
        let error = FalatErrorHandler(test: self).catchFatalError {
            let _ = assembly.objectA
            let _ = assembly.objectB
        }
        XCTAssertEqual(error, "Singleton already exist, inspect your dependencies graph")
    }
}

private struct FalatErrorHandler {
    let test: XCTestCase
    
    func catchFatalError(handler: @escaping () -> Void) -> String? {
        let expectation = test.expectation(description: "fatal_error")
        var result: String?
        EasyDi.fatalError = { message, _, _ in
            result = message()
            expectation.fulfill()
            while (true) { RunLoop.current.run() }
        }
        
        DispatchQueue.global(qos: .background).async(execute: handler)
        test.waitForExpectations(timeout: 0.1, handler: nil)
        EasyDi.fatalError = Swift.fatalError
        return result
    }
}
