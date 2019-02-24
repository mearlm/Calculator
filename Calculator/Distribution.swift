//
//  Distribution.swift
//  Calculator
//
//  Created by Michael McGhan on 2/24/19.
//  Copyright © 2019 MSQR Laboratories. All rights reserved.
//

import Foundation

// NB: in a given distribution, all values are the same type (T), e.g. String
public typealias Membership<T> = [(weight: Int, value: T)]

// weights: an ascending sequence of Ints greater than (or equal to) 1, and ending at 100
// describing the probability of selecting the associated value
public struct Distribution<T: Equatable>: Equatable {
    private var members = Membership<T>()
    private var last: (weight: Int, value: T) {
        get { return members.last! }
    }
    
    public init(members: Membership<T>) throws {
        guard validate(members) else {
            throw AttributionError.invalidDistribution(error: "invalid membership")
        }
        self.members = members
    }
    
    private func logError(error: String) {
        // ToDo: add a proper error logging service
        print(error)
    }
    
    private func validate(_ members: Membership<T>) -> Bool {
        var weight = 0
        for member in members {
            if member.weight <= weight {
                logError(error: "Distribution not ascending after \(weight).")
                return false
            }
            weight = member.weight
        }
        if (100 != weight) {
            logError(error: "Distribution unterminated at \(weight).")
            return false
        }
        return true
    }
    
    public func select() -> T {
        let selector = Calculator.rand(self.last.weight)    // e.g. 0 - 99
        for member in self.members {
            if (member.weight > selector) {                 // NB: 10 > 9, but 10 !> 10 => selector = 10 is next element above weight = 10
                return member.value
            }
        }
        return self.last.value                              // should never happen (since last member's weight = 100)
    }
    
    // NB: this works as a "find" if by = 0
    public func rotate(from: T, by: Int) throws -> T {
        let found = self.members.enumerated().filter { $0.element.value == from }.map {$0.offset}
        if (found.count != 1) {
            throw AttributionError.missingAttribute(for: String(describing: from))
        }
        var index = (found[0] as Int + by) % self.members.count
        if 0 > index {
            index += members.count
        }
        
        return self.members[index].value
    }
    
    public static func ==(lhs: Distribution, rhs: Distribution) -> Bool {
        guard lhs.members.count == rhs.members.count else {
            return false
        }
        
        for ix in lhs.members.indices {
            if lhs.members[ix] != rhs.members[ix] {
                return false
            }
        }
        return true
    }
}
