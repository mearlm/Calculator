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

// weights: an ascending sequence of Ints greater than (or equal to) 1, and ending at limit
// describing the probability of selecting the associated value
public struct Distribution<T: Equatable>: Equatable, Addressable {
    private static var MEMBER : String {
        get { return "<member>" }
    }
    private static var DEFAULT_LIMIT : Int {
        get { return 100 }
    }
    
    private var members = Membership<T>()
    private var last: (weight: Int, value: T) {
        get { return members.last! }
    }
    private let limit: Int
    public let _id: Int                             // immutable, unique
    public var _parent: Addressable? = nil

    public init(members: Membership<T>, limit: Int, parent: Attribution?) throws {
        self._id = Attribution.getNextId()
        self._parent = parent

        self.limit = (limit > 0) ? limit : Distribution.DEFAULT_LIMIT

        guard validate(members) else {
            throw AttributionError.invalidDistribution(error: "invalid membership")
        }
        self.members = members
    }
    
    public init(members: Membership<T>, parent: Attribution?) throws {
        try self.init(members: members, limit: Distribution.DEFAULT_LIMIT, parent: parent)
    }
    
    public init(members: Membership<T>) throws {
        try self.init(members: members, limit: Distribution.DEFAULT_LIMIT, parent: nil)
    }
    
    public func findChildKey(for childId: Int) -> String? {
        // look in the members collection to see if the child is present
        let found = self.members.filter {
            if let value = $0.value as? Addressable {
                return childId == value.getUniqueId()
            }
            return false
        }
        return (!found.isEmpty) ? Distribution.MEMBER : nil
    }
    
    private func logError(error: String) {
        // ToDo: add a proper error logging service
        print(error)
    }
    
    private func validate(_ members: Membership<T>) -> Bool {
        var weight = 0
        for member in members {
            if member.weight <= weight {
                logError(error: "Distribution not ascending after \(weight) at \(String(describing: member))")
                return false
            }
            weight = member.weight
        }
        if (self.limit != weight) {
            logError(error: "Distribution unterminated at \(weight) [expected: \(self.limit)].")
            return false
        }
        return true
    }
    
    // based on the distribution weights, select an item randomly
    public func select() -> T {
        let selector = Calculator.rand(self.last.weight)    // e.g. 0 - 99
        for member in self.members {
            if (member.weight > selector) {                 // NB: 10 > 9, but 10 !> 10 => selector = 10 is next element above weight = 10
                return member.value
            }
        }
        return self.last.value                              // should never happen (since last member's weight = Distribution.DEFAULT_LIMIT)
    }
    
    // find which distribution item is rotated (bidirectionally)
    // from a given starting item, by a specified offset;
    // it considers the distribution items to exist in an endless circular buffer
    // NB: this works as a "find" when by = 0
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
