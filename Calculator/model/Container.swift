//
//  Container.swift
//  iRogue
//
//  Created by Michael McGhan on 6/10/18.
//  Copyright © 2018 MSQR Laboratories. All rights reserved.
//

import Foundation

public protocol Container: Sequence, Equatable {
    associatedtype T : Attributed
    
    var things: [T] { get }
    var capacity: Int { get }

    func add(thing: T) -> Bool
    func remove(thing: T) -> Bool
    
    func shuffle() throws -> [T]
    func sort(by keys: String...) throws -> [T]
    func find(matching: (key: String, value: Attributable)...) -> [T]
    
    //func makeIterator() -> Array<Attributed>.Iterator
}
extension Container {
    public static var UNLIMITED : Int {
        get {
            return -1
        }
    }
    
    // NB: the original container is not changed
    public func shuffle() -> [T] {
        var shuffled: [T] = []
        var indexes = self.things.enumerated().map { $0.offset }
        while (indexes.count > 0) {
            let ix = Calculator.rand(indexes.count)
            shuffled.append(self.things[indexes[ix]])
            indexes.remove(at: ix)
        }
        return shuffled
    }
    
    // NB: the original container is not changed
    public func sort(by keys: String...) throws -> [T] {
        let sorted = try self.things.sorted {
            var key0: String = ""
            var key1: String = ""
            for key in keys {
                if let val0 = $0.attributes.get(for: key),
                    let val1 = $1.attributes.get(for: key) {
                    key0 += try val0.describe(resolve: true, within: $0.attributes) + ":"
                    key1 += try val1.describe(resolve: true, within: $1.attributes) + ":"
                }
            }
            return key0 < key1
        }
        
        return sorted
    }
    
    public func find(matching: (key: String, value: Attributable)...) -> [T] {
        var found = things
        for identifier in matching {
            found = found.filter {
                if let value = $0.attributes.get(for: identifier.key) {
                    return identifier.value.isEqual(other: value)
                }
                return false
            }
        }
        return found
    }
    
    public func makeIterator() -> IndexingIterator<[Self.T]> {
        return things.makeIterator()
    }
}
