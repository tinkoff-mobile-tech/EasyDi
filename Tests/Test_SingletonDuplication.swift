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
        NSException.test_swizzleRaise()
        
        let context = DIContext()
        let assembly = TestAssembly.instance(from: context)
        
        let _ = assembly.objectA
        let _ = assembly.objectB
        
        XCTAssertEqual(NSException.last?.reason, "Singleton already exist, inspect your dependencies graph")
        NSException.last = nil
    }
}

extension NSException {
    static var last: NSException?
    static var alreadySwizzled = false
    
    static func test_swizzleRaise() {
        guard !alreadySwizzled else { return }
        
        let origin = class_getInstanceMethod(NSException.self, NSSelectorFromString("raise"))
        let new = class_getInstanceMethod(NSException.self, NSSelectorFromString("test_raise"))
        
        if let origin = origin, let new = new {
            method_exchangeImplementations(origin, new)
            alreadySwizzled = true
        }
    }
    
    @objc func test_raise() {
        NSException.last = self
    }
}
