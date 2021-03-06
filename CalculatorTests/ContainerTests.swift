//
//  ContainerTests.swift
//  CalculatorTests
//
//  Created by Michael McGhan on 3/2/19.
//  Copyright © 2019 MSQR Laboratories. All rights reserved.
//

import XCTest
@testable import Calculator

class ContainerTests: XCTestCase {

//    override func setUp() {
//        // Put setup code here. This method is called before the invocation of each test method in the class.
//    }
//
//    override func tearDown() {
//        // Put teardown code here. This method is called after the invocation of each test method in the class.
//    }

    func testUnlimited() {
        XCTAssert(-1 == TestContainer.UNLIMITED)
    }
    
    func testAdd() {
        let container = TestContainer(size: 5)
        XCTAssert(container.isEmpty)
        let result = container.add(thing: Attribution())
        XCTAssert(result)
        XCTAssert(!container.isEmpty)
        XCTAssert(1 == container.count)
    }
    
    func testAddSubType() {
        let container = TestContainer(size: 5)
        XCTAssert(container.add(thing: Attribution()))
        XCTAssert(container.add(thing: Card(suit: Card.SUITS[0], rank: 1)))
        
        guard let thing = container[1] as? Card else {
            XCTFail()
            return
        }
        XCTAssert("A" == thing.rankName())
    }
    
    func testCapacityExceeded() {
        let container = TestContainer(size: 2)
        var count = 0
        while (container.add(thing: Attribution())) {
            count += 1
        }
        XCTAssert(2 == count)
    }
    
    func testUnlimitedCapacity() {
        let container = TestContainer(size: TestContainer.UNLIMITED)
        var count = 100
        while (0 < count) {
            XCTAssert(container.add(thing: Attribution()))
            count -= 1
        }
        XCTAssert(0 == count)
        XCTAssert(container.add(thing: Attribution()))
    }
    
    func testRemove() {
        let container = TestContainer(size: 2)
        var count = 0
        while (container.add(thing: Attribution())) {
            count += 1
        }
        XCTAssert(2 == container.count)     // container is at capacity
        
        for thing in container.things {
            XCTAssert(container.remove(thing: thing))
        }
        XCTAssert(container.isEmpty)
        
        // can now add another
        XCTAssert(container.add(thing: Attribution()))
        XCTAssert(!container.isEmpty)
    }
    
    // contains all ranks of all suits, in order
    private func verifyDeck(cards: [Card]) -> Int {
        var ix = -1
        var expected = 0
        var result = 0
        
        var unique = [String]()
        
        for card in cards {
            let rank = card.rank()
            if (0 == expected % 13) {
                ix += 1
            }
            if (expected % 13 + 1 != rank || Card.SUITS[ix] != card.suitName()) {
                result = 1                      // not ordered
            }
            expected += 1
            
            // also test that the card names (not just rank and suit) are unique
            let name = card.name()
            if (unique.contains(name)) {
                return -2                       // not unique
            }
            unique.append(name)
        }
        return (52 == expected) ? result : -1   // ordered and unique
    }
    
    func testShuffle() {
        let deck = Card.makeDeck()
        XCTAssert(0 == verifyDeck(cards: deck.things as! [Card]))

        let shuffled = deck.shuffle()
        XCTAssert(1 == verifyDeck(cards: shuffled as! [Card]))
        XCTAssert(0 == verifyDeck(cards: deck.things as! [Card]))
        
        // debug info
        for card in shuffled {
            let card = card as! Card
            print(card.name())
        }
    }
    
    func testSort() {
        let deck = Card.makeDeck()
        XCTAssert(0 == verifyDeck(cards: deck.things as! [Card]))
        
        let newdeck = Container(things: deck.shuffle(), parent: nil)
        
        let sorted = try! newdeck.sort(by: "suit", "rank")
        XCTAssert(1 == verifyDeck(cards: sorted as! [Card]))

        XCTAssert(try! sorted == deck.sort(by: "suit", "rank"))
        XCTAssert(try! sorted != deck.sort(by: "rank", "suit"))
    }
    
    func testConstructorFromObjects() {
        let aces = [
            Card(suit: Card.SUITS[0], rank: 1),
            Card(suit: Card.SUITS[1], rank: 1),
            Card(suit: Card.SUITS[2], rank: 1),
            Card(suit: Card.SUITS[3], rank: 1),
        ]
        let deck = Container(things: aces, parent: nil)
        
        XCTAssert(aces.count == deck.count)
        
        var ix = Card.SUITS.count
        while (0 < ix) {
            ix -= 1
            
            let card = deck.things[ix] as! Card
            XCTAssert(card.suitName() == Card.SUITS[ix])
            XCTAssert(card.rank() == 1)
        }
        
        // inextensible
        XCTAssert(!deck.add(thing: Card(suit: "None", rank: 1)))
    }
    
    func testConstructorFromObjectsExtensible() {
        let aces = [
            Card(suit: Card.SUITS[0], rank: 1),
            Card(suit: Card.SUITS[1], rank: 1),
            Card(suit: Card.SUITS[2], rank: 1),
            Card(suit: Card.SUITS[3], rank: 1),
        ]
        let deck = Container(things: aces, size: 5, parent: nil)!
        
        XCTAssert(aces.count == deck.count)
        
        // extensible
        XCTAssert(deck.add(thing: Card(suit: "None", rank: 1)))

        var ix = deck.count
        while (0 < ix) {
            ix -= 1
            
            let card = deck.things[ix] as! Card
            XCTAssert(card.suitName() == ((4 == ix) ? "None" : Card.SUITS[ix]))
            XCTAssert(card.rank() == 1)
        }
    }
    
    // containers are lists, and allow duplicate objects
    func testContainerWithDuplicates() {
        let spadeAce = Card(suit: Card.SUITS[0], rank: 1)
        let heartAce = Card(suit: Card.SUITS[1], rank: 1)
        let container = Container(things: [spadeAce, heartAce, spadeAce], parent: nil)
        
        XCTAssert(3 == container.count)
        XCTAssert(container.things[0] != container.things[1])
        XCTAssert(container.things[0] == container.things[2])
    }

    // two containers are equal when they contain equal attributions
    func testEquality() {
        let spadeAce = Card(suit: Card.SUITS[0], rank: 1)
        let heartAce = Card(suit: Card.SUITS[1], rank: 1)
        let firstContainer = Container(things: [spadeAce, heartAce], parent: nil)
        let secondContainer = Container(things: [heartAce, spadeAce], parent: nil)
        let thirdContainer = Container(things: [
            Card(suit: Card.SUITS[0], rank: 1),
            Card(suit: Card.SUITS[1], rank: 1)
        ], parent: nil)
        let fourthContainer = Container(things: [
            Card(suit: Card.SUITS[0], rank: 1),
            Card(suit: Card.SUITS[1], rank: 1),
            Card(suit: Card.SUITS[2], rank: 1)
        ], parent: nil)

        XCTAssert(firstContainer == firstContainer)     // identity
        XCTAssert(firstContainer != secondContainer)    // unequal
        XCTAssert(firstContainer == thirdContainer)     // equal
        XCTAssert(firstContainer != fourthContainer)    // different sizes
    }
    
    // containers are lists, and allow duplicate objects
    func testFind() {
        let spadeAce = Card(suit: Card.SUITS[0], rank: 1)
        let heartAce = Card(suit: Card.SUITS[1], rank: 1)
        let container = Container(things: [spadeAce, heartAce, spadeAce], parent: nil)
        
        var found = container.find(matching: (key: "suit", value: Card.SUITS[0]))
        XCTAssert(2 == found.count)
        XCTAssert(found[0] == found[1])
        
        found = container.find(matching: ("rank", value: 1))
        XCTAssert(3 == found.count)
        
        found = container.find(matching: ("rank", value: 2))
        XCTAssert(found.isEmpty)
    }
    
    func testIterator() {
        let deck = Card.makeDeck()
        
        var expected = 0
        for card in deck {
            let rankNo = expected % 13 + 1
            let suitNo = (expected / 13)
            
            let card = card as! Card
            
            XCTAssert(card.rank() == rankNo)
            XCTAssert(card.suitName() == Card.SUITS[suitNo])
            
            expected += 1
        }
    }
}
