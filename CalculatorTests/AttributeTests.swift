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
        
        let label = try! attr.describe(resolve: false, within: nil)
        XCTAssert("3d6" == label)
    }

    func testAddress() {
        let testValue = Address(["a", "b", "c"])
        let attr = Attribute(testValue)
        let value = try! attr.asAddress()
        XCTAssert(value == testValue)
        XCTAssert(equalAny(lhv: testValue!, rhv: attr.rawValue(), baseType: Address.self))
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
    
    func testAttributionValue() {
        let testValue = Attribution()
        
        testValue.add(for: "xxx", value: Attribute(3))      // wrapped
        testValue.add(for: "yyy", value: 3)                 // raw
        
        if let xxx = testValue.get(for: "xxx"),
            let yyy = testValue.get(for: "yyy") {
            XCTAssert(xxx.isEqual(other: yyy))
        }
        else {
            XCTFail()
        }
    }
    
    func testAttributionRemove() {
        let testValue = Attribution()
            .add(for: "a", value: Attribute("x"))
            .add(for: "b", value: Attribute(3))
            .add(for: "c", value: Attribute(false))
        
        XCTAssert(testValue.containsKey(for: "a"))
        XCTAssert(3 == testValue.count())
        
        testValue.add(for: "a", value: nil)             // remove by add (nil)
        XCTAssert(!testValue.containsKey(for: "a"))
        XCTAssert(2 == testValue.count())
        
        XCTAssert(testValue.containsKey(for: "c"))
        testValue.remove(for: "c")                      // remove by remove
        XCTAssert(!testValue.containsKey(for: "c"))
        XCTAssert(1 == testValue.count())
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
        let value = try! attr.asDistribution(of: String.self)                   // content type
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
        let value = try! attr.asDistribution(of: Attribute<String>.self)        // content type
        XCTAssert(value == testValue)
        XCTAssert(equalAny(lhv: testValue as Any, rhv: attr.rawValue(), baseType: type(of: testValue)))  // Distribution<Attribute<String>>.self))
        XCTAssertThrowsError(try attr.asDice())
        
        let other = try! attr.asType(Distribution<Attribute<String>>.self)      // distribution incl. content type
        XCTAssert(other == testValue)
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
        let value = try! attr.asDistribution(of: Attribution.self)              // content type
        XCTAssert(value == testValue)
        XCTAssert(equalAny(lhv: testValue as Any, rhv: attr.rawValue(), baseType: type(of: testValue)))  // Distribution<Attribute<String>>.self))
        XCTAssertThrowsError(try attr.asDice())
    }
    
    func testContainerAsType() {
        let testValue = TestContainer(size: 5)
        testValue.add(thing: Attribution())
        testValue.add(thing: Attribution())
        testValue.add(thing: Attribution())
        testValue.add(thing: Attribution())
        
        let attr = Attribute(testValue)
        let value = try! attr.asType(TestContainer.self)
        XCTAssert(value == testValue)
        XCTAssert(equalAny(lhv: testValue as Any, rhv: attr.rawValue(), baseType: type(of: testValue)))  // Distribution<Attribute<String>>.self))
        XCTAssertThrowsError(try attr.asDice())
    }
    
    func testContainerAsContainer() {
        let testValue = TestContainer(size: 5)
        testValue.add(thing: Attribution())
        testValue.add(thing: Attribution())
        testValue.add(thing: Attribution())
        testValue.add(thing: Attribution())
        
        let attr = Attribute(testValue)
        let value = try! attr.asContainer()
        XCTAssert(value == testValue)
        XCTAssert(equalAny(lhv: testValue as Any, rhv: attr.rawValue(), baseType: type(of: testValue)))  // Container<Attribution>.self))
        do {
            _ = try attr.asContainer()
//            throw AttributionError.runtimeError(error: "exception expected")
        } catch AttributionError.invalidDereference(let message) {
            print(AttributionError.invalidDereference(error: message).errorDescription!)
        } catch {
            print(error)
            XCTFail()
        }
    }
    
    // NB: cannot retrieve container of subtype objects!
    func testContainerAsSubTypeContainer() {
        let testValue = TestContainer(size: 5)
        testValue.add(thing: Card())
        testValue.add(thing: Card())
        testValue.add(thing: Card())
        testValue.add(thing: Card())
        
        let attr = Attribute(testValue)
        XCTAssert(equalAny(lhv: testValue as Any, rhv: attr.rawValue(), baseType: type(of: testValue))) // Container<Card>.self))
        let value = try! attr.asContainer()     // content type
        XCTAssert(value == testValue)
        let other = try! attr.asType(Container.self)   // container type
        XCTAssert(other == testValue)

        do {
            _ = try attr.asType(Container.self)              // container incl. content
            // throw AttributionError.runtimeError(error: "exception expected")
        } catch AttributionError.invalidDereference(let message) {
            print(AttributionError.invalidDereference(error: message).errorDescription!)
        } catch {
            print(error)
            XCTFail()
        }

//      XCTAssert(third.isEqual(other: testValue))
        
        // comparisons that do work
        XCTAssert(equalAny(lhv: other, rhv: testValue, baseType: TestContainer.self))
        XCTAssert(equalAny(lhv: other, rhv: testValue, baseType: Container.self))
        
        // comparisons that don't work
        XCTAssert(!equalAny(lhv: other, rhv: testValue, baseType: Container.self))    // NOT EQUAL!
    }
    
    func testExceptionMessages() {
        var message = AttributionError.missingAttribute(for: "name").errorDescription
        XCTAssert(message == "missing attribute: name")
        message = AttributionError.invalidDereference(error: "dereference").errorDescription
        XCTAssert(message == "invalid: dereference")
        message = AttributionError.invalidDistribution(error: "distribution").errorDescription
        XCTAssert(message == "invalid: distribution")
        message = AttributionError.invalidFetch(expected: "type", received: "other").errorDescription
        XCTAssert(message == "expected: type received: other")
        message = AttributionError.containerFull(max: 3).errorDescription
        XCTAssert(message == "container full (max=3)")
        message = AttributionError.runtimeError(error: "unknown").errorDescription
        XCTAssert(message == "invalid: unknown")
    }

//    func testPerformanceExample() {
//        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//        }
//    }

}
