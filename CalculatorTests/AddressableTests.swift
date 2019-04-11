//
//  AddressableTests.swift
//  CalculatorTests
//
//  Created by Michael McGhan on 3/16/19.
//  Copyright © 2019 MSQR Laboratories. All rights reserved.
//

import XCTest
@testable import Calculator

class AddressableTests: XCTestCase {

//    override func setUp() {
//        // Put setup code here. This method is called before the invocation of each test method in the class.
//    }
//
//    override func tearDown() {
//        // Put teardown code here. This method is called after the invocation of each test method in the class.
//    }
    
//    func getAddress() -> Address?
//    func getUniqueId() -> Int
//    func findChildKey(for childId: Int) -> String?

    func testGetAddressRoot() {
        let x0 = Attribution()
        let addr = x0.getAddress()
        XCTAssert(addr == nil)
    }
    
    func testGetAddressChild() {
        let root = Attribution()
        let x1 = Attribution()
        root.add(for: "a", value: x1)
        let addr = x1.getAddress()
        XCTAssert(addr != nil)
        XCTAssert(addr?.asString() == "a")
    }

//    func testPerformanceExample() {
//        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//        }
//    }

}
