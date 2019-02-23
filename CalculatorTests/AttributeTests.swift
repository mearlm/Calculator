//
//  AttributeTests.swift
//  CalculatorTests
//
//  Created by Michael McGhan on 2/20/19.
//  Copyright © 2019 MSQR Laboratories. All rights reserved.
//

import XCTest
@testable import Calculator

class AttributeTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testInt() {
        let intAttr = Attribute(3)
        let value = try! intAttr.asInt()
        XCTAssert(value == 3)
        XCTAssert(intAttr.rawValue() == 3)
        XCTAssertThrowsError(try intAttr.asBool())
    }
    
    func testString() {
        let testValue = "test"
        let strAttr = Attribute(testValue)
        let value = try! strAttr.asString()
        XCTAssert(value == testValue)
        XCTAssert(strAttr.rawValue() == testValue)
        XCTAssertThrowsError(try strAttr.asInt())
    }
    
    func testBool() {
        let testValue = true
        let strAttr = Attribute(testValue)
        let value = try! strAttr.asBool()
        XCTAssert(value == testValue)
        XCTAssert(strAttr.rawValue() == testValue)
        XCTAssertThrowsError(try strAttr.asString())
    }

    func testDice() {
        let testValue = Dice(count: 3, sides: 6)
        let strAttr = Attribute(testValue)
        let value = try! strAttr.asDice()
        XCTAssert(value == testValue)
        XCTAssert(strAttr.rawValue() == testValue)
        XCTAssertThrowsError(try strAttr.asBool())
    }

//    func testAddress() {
//        let testValue = Address("a.b.c")
//        let strAttr = Attribute(testValue)
//        let value = try! strAttr.asAddress()
//        XCTAssert(value == testValue)
//        XCTAssert(strAttr.rawValue() == testValue)
//        XCTAssertThrowsError(try strAttr.asAttribution())
//    }
//
//    func testAttribution() {
//        let testValue = Attribution()
//        testValue.add(for: "a", value: "x")
//            .add(for: "b", value: 3)
//            .add(for: "c", value: false)
//
//        let strAttr = Attribute(testValue)
//        let value = try! strAttr.asAttribution()
//        XCTAssert(value == testValue)
//        XCTAssert(strAttr.rawValue() == testValue)
//        XCTAssertThrowsError(try strAttr.asDistribution())
//    }

    func testDistribution() {
        let members = [
            (weight: 10, value: Attribute("a")),
            (weight: 15, value: Attribute("b")),
            (weight: 30, value: Attribute("c")),
            (weight: 55, value: Attribute("d")),
            (weight: 75, value: Attribute("e")),
            (weight: 100, value: Attribute("f"))
        ]
        // [(weight: Int, value: Attribute<Any>)]
        let testValue = Distribution(members: members)
        
        let strAttr = Attribute(testValue)
        let value = strAttr.rawValue()
        XCTAssert(value == testValue)
        XCTAssertThrowsError(try strAttr.asInt())
    }

//    func testPerformanceExample() {
//        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//        }
//    }

}
