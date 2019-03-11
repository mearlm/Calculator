//
//  File.swift
//  CalculatorTests
//
//  Created by Michael McGhan on 3/2/19.
//  Copyright © 2019 MSQR Laboratories. All rights reserved.
//

import Foundation
import Calculator

class TestContainer : Container<TestContainee> {
}

class TestContainee : Attributed, Equatable {
    var attributes: Attribution
    
    init(with value: Attribution) {
        attributes = value
    }
    
    static func == (lhs: TestContainee, rhs: TestContainee) -> Bool {
        return lhs.attributes == rhs.attributes
    }
}

class TestContaineeSubType : TestContainee {
    let subType = true
}

class Card: Attributed, Equatable {
    static let SUITS = ["Spades", "Hearts", "Diamonds", "Clubs"]

    var attributes: Attribution
    
    private init(with value: CardAttribution) {
        attributes = value
    }
    
    convenience init(suit: String, rank: Int) {
        self.init(with: CardAttribution(suit: suit, rank: rank))
    }
    
    func suitName() -> String {
        if let attr = attributes.get(for: "suit") {
            return try! attr.asString()
        }
        return "?"
    }
    
    func rank() -> Int {
        if let attr = attributes.get(for: "rank") {
            return try! attr.asInt()
        }
        return 0
    }
    
    func rankName() -> String {
        let rank = self.rank()
        switch (rank) {
        case 1:
            return "A"
        case 11:
            return "J"
        case 12:
            return "Q"
        case 13:
            return "K"
        default:
            return String(rank)
        }
    }

    func name() -> String {
        let rank = self.rankName()
        if let suit = self.suitName().uppercased().first {
            return "\(rank)\(suit)"
        }
        return "\(rank)?"
    }
    
    static func == (lhs: Card, rhs: Card) -> Bool {
        return lhs.attributes == rhs.attributes
    }
}

class CardAttribution: Attribution {
    init(suit: String, rank: Int) {
        super.init()
        self.add(for: "suit", value: Attribute(suit))
        self.add(for: "rank", value: Attribute(rank))
    }
}
