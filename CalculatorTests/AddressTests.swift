//
//  AddressTests.swift
//  CalculatorTests
//
//  Created by Michael McGhan on 2/20/19.
//  Copyright © 2019 MSQR Laboratories. All rights reserved.
//

import XCTest
@testable import Calculator

class AddressTests: XCTestCase {
    let cval = "attribute_c"
    func setAddress() -> (root: Attribution, addr: Address) {
        let x2 = Attribution()
        x2.add(for: "c", value: cval)
        
        let x1 = Attribution()
        x1.add(for: "b", value: x2)
        
        let x0 = Attribution()
        x0.add(for: "a", value: x1)
        
        return (x0, Address(["a", "b", "c"])!)
    }
    func setBadAddress() -> (root: Attribution, addr: Address) {
        let x2 = Attribution()
        x2.add(for: "c", value: cval)
        
        let x1 = Attribution()
        x1.add(for: "x", value: x2)
        
        let x0 = Attribution()
        x0.add(for: "a", value: x1)
        
        return (x0, Address(["a", "b", "c"])!)
    }

    override func setUp() {
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testResolve() {
        let testValue = setAddress()
        XCTAssert(testValue.root.containsKey(for: "a"))
        XCTAssert(try testValue.addr.exists(args: testValue.root))
        
        let badValue = setBadAddress()
        XCTAssert(badValue.root.containsKey(for: "a"))
        XCTAssert(try !badValue.addr.exists(args: badValue.root))
    }
    
    func testFetch() {
        let testValue = setAddress()
        do {
            if let value = try testValue.addr.fetch(args: testValue.root) {
                XCTAssert(value.isEqual(other: Attribute(cval)))
            }
        }
        catch {
            print(error)
            XCTFail()
        }
    }
    
    func testFetchFail() {
        let testValue = setBadAddress()
        do {
            let _ = try testValue.addr.fetch(args: testValue.root)
        }
        catch AttributionError.missingAttribute(for: let message) {
            XCTAssert("address a.b.c at b" == message)
        }
        catch {
            print(error)
            XCTFail()
        }
    }
    
    func testFetchRaw() {
        let testValue = setAddress()
        do {
            if let value = try testValue.addr.fetch(args: testValue.root)?.asString() {
                XCTAssert(value == cval)
            }
        }
        catch {
            print(error)
            XCTFail()
        }
    }
    
    func testStore() {
        let newValue = "new_attribute"
        let testValue = setAddress()
        try! testValue.addr.store(value: newValue, args: testValue.root)
        if let value = try! testValue.addr.fetch(args: testValue.root) {
            XCTAssert(value.isEqual(other: Attribute(newValue)))
        }
    }
    
    func testStoreAttribute() {
        let newValue = "new_attribute"
        let testValue = setAddress()
        try! testValue.addr.store(value: Attribute(newValue), args: testValue.root)
        if let value = try! testValue.addr.fetch(args: testValue.root) {
            XCTAssert(value.isEqual(other: Attribute(newValue)))
        }
    }

    func testStoreFail() {
        let newValue = "new_attribute"
        let testValue = setBadAddress()
        do {
            try testValue.addr.store(value: newValue, args: testValue.root)
        }
        catch AttributionError.missingAttribute(for: let message) {
            XCTAssert("address a.b.c at b" == message)
        }
        catch {
            print(error)
            XCTFail()
        }
    }
    
    func testDescribeAddress() {
        let testValue = setAddress()
        let addr = Attribute(testValue.addr)
        
        let labeldefault = try! addr.describe()
        XCTAssert("a.b.c" == labeldefault)

        let label = try! addr.describe(resolve: false, within: nil)
        XCTAssert("a.b.c" == label)
        
        let labelnoresolve = try! addr.describe(resolve: true, within: nil)
        XCTAssert("a.b.c" == labelnoresolve)

        let value = try! addr.describe(resolve: true, within: testValue.root)
        XCTAssert(cval == value)
    }
    
    func testAddressEquality() {
        let testValue = setAddress()
        let otherValue = Address(["a", "b", "c"])
        XCTAssert(testValue.addr == otherValue)
        
        let longValue = Address(["a", "b", "c", "d"])
        XCTAssert(testValue.addr != longValue)
        
        let shortValue = Address(["a", "b"])
        XCTAssert(testValue.addr != shortValue)
        
        let similarValue = Address(["a", "d", "c"])
        XCTAssert(testValue.addr != similarValue)

        let badValue = Address(["x", "y", "z"])
        XCTAssert(testValue.addr != badValue)
    }

//    func testPerformanceExample() {
//        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//        }
//    }

}
