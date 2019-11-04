//
//  Test_Threadsafety.swift
//  EasyDi-iOS-Tests
//
//  Created by Sergey V. Krupov on 21.11.2018.
//  Copyright © 2018 AndreyZarembo. All rights reserved.
//

import XCTest
import EasyDi

fileprivate protocol SomeProtocol {
}

fileprivate class SomeObject: SomeProtocol {
    var values = Array<String>(repeating: "", count: 4000)
}

fileprivate class TestAssembly: Assembly {
    var someObject: SomeProtocol {
        return define(init: SomeObject()) {
            for i in 0 ..< $0.values.count {
                $0.values[i] = self.getSomeValue(at: i)
            }
            return $0
        }
    }

    // Сделано для того, чтобы стабильно воспроизводить падение. Вряд ли в реальном приложении будет такой код.
    private func getSomeValue(at index: Int) -> String {
        return define(key: "getSomeValue_\(index)", init: "value-\(index)")
    }
}

final class Test_Threadsafety: XCTestCase {
    func test_ThreadSafety() {

        let context = DIContext()
        let assembly = TestAssembly.instance(from: context)

        // Явно создаю 2 потока, т.к. не известно на скольких потоках будет работать concurrent dispatch queue

        let queue1 = DispatchQueue(label: "Queue1")
        let expectation1 = expectation(description: "Queue-1")
        queue1.async {
            for _ in 1 ..< 10 {
                _ = assembly.someObject
            }
            expectation1.fulfill()
        }

        let queue2 = DispatchQueue(label: "Queue2")
        let expectation2 = expectation(description: "Queue-2")
        queue2.async {
            for _ in 1 ..< 10 {
                _ = assembly.someObject
            }
            expectation2.fulfill()
        }

        wait(for: [expectation1, expectation2], timeout: 10)
    }
}
