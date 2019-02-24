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
    
    private func equalAny<BaseType: Equatable>(lhv: Any, rhv: Any, baseType: BaseType.Type) -> Bool {
        guard let lhsEquatable = lhv as? BaseType,
            let rhsEquatable = rhv as? BaseType else {
                return false
        }
        return lhsEquatable == rhsEquatable
    }

    func testInt() {
        let testValue = 3
        let attr = Attribute(testValue)
        let value = try! attr.asInt()
        XCTAssert(value == testValue)
        XCTAssert(equalAny(lhv: testValue, rhv: attr.rawValue(), baseType: Int.self))
        XCTAssertThrowsError(try attr.asString())
    }
    
    func testString() {
        let testValue = "test"
        let attr = Attribute(testValue)
        let value = try! attr.asString()
        XCTAssert(value == testValue)
        XCTAssert(equalAny(lhv: testValue, rhv: attr.rawValue(), baseType: String.self))
        XCTAssertThrowsError(try attr.asBool())
    }
    
    func testBool() {
        let testValue = true
        let attr = Attribute(testValue)
        let value = try! attr.asBool()
        XCTAssert(value == testValue)
        XCTAssert(equalAny(lhv: testValue, rhv: attr.rawValue(), baseType: Bool.self))
        XCTAssertThrowsError(try attr.asDice())
    }

    func testDice() {
        let testValue = Dice(count: 3, sides: 6)
        let attr = Attribute(testValue)
        let value = try! attr.asDice()
        XCTAssert(value == testValue)
        XCTAssert(equalAny(lhv: testValue, rhv: attr.rawValue(), baseType: Dice.self))
        XCTAssertThrowsError(try attr.asInt())
    }

    func testAddress() {
        let testValue = Address("a.b.c")
        let attr = Attribute(testValue)
        let value = try! attr.asAddress()
        XCTAssert(value == testValue)
        XCTAssert(equalAny(lhv: testValue, rhv: attr.rawValue(), baseType: Address.self))
        XCTAssertThrowsError(try attr.asInt())
    }

    func testAttribution() {
        let testValue = Attribution()
            .add(for: "a", value: Attribute("x"))
            .add(for: "b", value: Attribute(3))
            .add(for: "c", value: Attribute(false))

        let attr = Attribute(testValue)
        let value = try! attr.asAttribution()
        XCTAssert(value == testValue)
        XCTAssert(equalAny(lhv: testValue, rhv: attr.rawValue(), baseType: Attribution.self))
        XCTAssertThrowsError(try attr.asDistribution(of: String.self))
    }

    func testDistributionOfStrings() {
        let members = [
            (weight: 10, value: "a"),
            (weight: 15, value: "b"),
            (weight: 30, value: "c"),
            (weight: 55, value: "d"),
            (weight: 75, value: "e"),
            (weight: 100, value: "f")
        ]
        // [(weight: Int, value: Attribute<Any>)]
        let testValue = try! Distribution(members: members)
        let attr = Attribute(testValue)
        let value = try! attr.asDistribution(of: String.self)
        XCTAssert(value == testValue)
        XCTAssert(equalAny(lhv: testValue as Any, rhv: attr.rawValue(), baseType: type(of: testValue)))  // Distribution<Attribute<String>>.self))
        XCTAssertThrowsError(try attr.asAttribution())
    }
    
    func testDistributionOfAttributes() {
        let members = [
            (weight: 10, value: Attribute("a")),
            (weight: 15, value: Attribute("b")),
            (weight: 30, value: Attribute("c")),
            (weight: 55, value: Attribute("d")),
            (weight: 75, value: Attribute("e")),
            (weight: 100, value: Attribute("f"))
        ]
        // [(weight: Int, value: Attribute<Any>)]
        let testValue = try! Distribution(members: members)
        let attr = Attribute(testValue)
        let value = try! attr.asDistribution(of: Attribute<String>.self)
        XCTAssert(value == testValue)
        XCTAssert(equalAny(lhv: testValue as Any, rhv: attr.rawValue(), baseType: type(of: testValue)))  // Distribution<Attribute<String>>.self))
        XCTAssertThrowsError(try attr.asDice())
    }

    func testDistributionOfAttributions() {
        let members = [
            (weight: 10, value: Attribution().add(for: "key", value: Attribute("a"))),
            (weight: 15, value: Attribution().add(for: "key", value: Attribute(0))),
            (weight: 30, value: Attribution().add(for: "key", value: Attribute(true))),
            (weight: 55, value: Attribution().add(for: "key", value: Attribute(Dice(count: 2, sides: 8)))),
            (weight: 75, value: Attribution().add(for: "key", value: nil)),
            (weight: 100, value: Attribution().add(for: "key", value: Attribute(Attribution().add(for: "name", value: Attribute("f")))))
        ]
        // [(weight: Int, value: Attribute<Any>)]
        let testValue = try! Distribution(members: members)
        let attr = Attribute(testValue)
        let value = try! attr.asDistribution(of: Attribution.self)
        XCTAssert(value == testValue)
        XCTAssert(equalAny(lhv: testValue as Any, rhv: attr.rawValue(), baseType: type(of: testValue)))  // Distribution<Attribute<String>>.self))
        XCTAssertThrowsError(try attr.asDice())
    }
    
    func testContainer() {
        let testValue = TestContainer(size: 5)
        testValue.add(thing: TestContainee())
        testValue.add(thing: TestContainee())
        testValue.add(thing: TestContainee())
        testValue.add(thing: TestContainee())
        
        let attr = Attribute(testValue)
        let value = try! attr.asType(TestContainer.self)
        XCTAssert(value == testValue)
        XCTAssert(equalAny(lhv: testValue as Any, rhv: attr.rawValue(), baseType: type(of: testValue)))  // Distribution<Attribute<String>>.self))
        XCTAssertThrowsError(try attr.asDice())
    }

//    func testPerformanceExample() {
//        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//        }
//    }

}

class TestContainer : Container {
    typealias T = TestContainee
    
    init(size: Int) {
        self.things = []
        self.capacity = size
    }
    
    var things: [T]
    var capacity: Int
    
    @discardableResult
    func add(thing: T) -> Bool {
        guard (self.things.count < self.capacity) else {
            return false
        }
        self.things.append(thing)
        return true
    }
 
   @discardableResult
   func remove(thing: T) -> Bool {
        if let index = self.things.index(of: thing) {
            self.things.remove(at: index)
            return true
        }
        return false
    }

    static func == (lhs: TestContainer, rhs: TestContainer) -> Bool {
        guard (lhs.things.count == rhs.things.count) else {
            return false
        }
        for ix in lhs.things.indices {
            if lhs.things[ix] != rhs.things[ix] {
                return false
            }
        }
        return true
    }
}

class TestContainee : Attributed, Equatable {
    var attributes: Attribution
    
    init() {
        attributes = Attribution()
    }
    
    static func == (lhs: TestContainee, rhs: TestContainee) -> Bool {
        return lhs.attributes == rhs.attributes
    }
}
