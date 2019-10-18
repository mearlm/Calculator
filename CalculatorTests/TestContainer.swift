//
//  File.swift
//  CalculatorTests
//
//  Created by Michael McGhan on 3/2/19.
//  Copyright © 2019 MSQR Laboratories. All rights reserved.
//

import Foundation
import Calculator

class TestContainer : Container {
}

class TestContainee : Attribution {
}

class Card: Attribution {
    static let SUITS = ["Spades", "Hearts", "Diamonds", "Clubs"]

    convenience init(suit: String, rank: Int) {
        self.init()
        self.add(for: "suit", value: Attribute(suit))
        self.add(for: "rank", value: Attribute(rank))
    }
    
    func suitName() -> String {
        if let attr = get(for: "suit") {
            return try! attr.asString()
        }
        return "?"
    }
    
    func rank() -> Int {
        if let attr = get(for: "rank") {
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
    
    static func makeDeck() -> Container {
        let deck = Container(size: 52)
        
        for suit in Card.SUITS {
            for rank in 1...13 {
                deck.add(thing: Card(suit: suit, rank: rank))
            }
        }
        return deck
    }
}
