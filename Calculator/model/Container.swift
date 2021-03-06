//
//  Container.swift
//  iRogue
//
//  Created by Michael McGhan on 6/10/18.
//  Copyright © 2018 MSQR Laboratories. All rights reserved.
//

import Foundation

//public protocol Container: AnyObject {
//    associatedtype T : Attribution
//
//    var things: [T] { get set }
//    var capacity: Int { get }
//
//    func add(thing: T) -> Bool          // @discardableResult
//    func remove(thing: T) -> Bool       // @discardableResult
//
//    func shuffle() throws -> [T]
//    func sort(by keys: String...) throws -> [T]
//    func find(matching: (key: String, value: Attributable)...) -> [T]
//}

// collections of similarly typed things, accessible by address
open class Container: Subject, Equatable, Collection {
    internal static var THING : String {
        get { return "[things]" }     // address key => member of a collection
    }
    public static var UNLIMITED : Int {
        get { return -1 }
    }

    public var things: [Attribution]
    public var capacity: Int
    
    public init(size: Int) {
        self.things = []
        self.capacity = size

        super.init()
        
        _id = Attribution.getNextId()
    }

    public convenience init(things: [Attribution], parent: Addressable?) {
        self.init(size: things.count)
        self.things = things
        self._parent = parent
    }
    
    public convenience init?(things: [Attribution], size: Int, parent: Addressable?) {
        guard size >= things.count else {
            return nil
        }
        self.init(things: things, parent: parent)
        self.capacity = size
    }
    
    private func fullPath(index: Int) -> Address {
        var parts: [String] = []
        if let address = self.getAddress() {
            parts = address.asParts()
        }
        return Address(parts + ["@\(index)"])!
    }

    @discardableResult
    public func add(thing: Attribution) -> Bool {
        guard capacity == Container.UNLIMITED || things.count < capacity else {
            return false
        }
        thing.reparent(parent: self)
        things.append(thing)

        notify(at: fullPath(index: things.count-1), was: nil)
        return true
    }
    
    @discardableResult
    public func remove(thing: Attribution) -> Bool {
        if let index = things.firstIndex(of: thing) {
            if let previous = things.remove(at: index) as? Attributable {
                notify(at: fullPath(index: things.count-1), was: previous)
                // ToDo: should the (removed and discarded) child be reparented to nil?
            }
            return true
        }
        return false
    }
    
    override
    public func findChildKey(for childId: Int) -> String? {
        // look in the things collection to see if the child is present
        let found = self.things.filter {
            return childId == $0.getUniqueId()
        }
        return (!found.isEmpty) ? "\(Container.THING):\(childId)" : nil
    }

    // NB: the original container is not changed
    public func shuffle() -> [Attribution] {
        var shuffled: [Attribution] = []
        var indexes = self.things.enumerated().map { $0.offset }
        while (indexes.count > 0) {
            let ix = Calculator.rand(indexes.count)
            shuffled.append(self.things[indexes[ix]])
            indexes.remove(at: ix)
        }
        return shuffled
    }
    
    // NB: the original container is not changed
    public func sort(by keys: String...) throws -> [Attribution] {
        let sorted = try self.things.sorted {
            var key0: String = ""
            var key1: String = ""
            for key in keys {
                if let val0 = $0.get(for: key),
                    let val1 = $1.get(for: key) {
                    key0 += try val0.describe(resolve: true, within: $0) + ":"
                    key1 += try val1.describe(resolve: true, within: $1) + ":"
                }
            }
            return key0 < key1
        }
        
        return sorted
    }
    
    public func find<E: Equatable>(matching: (key: String, value: E)...) -> [Attribution] {
        var found = things
        for identifier in matching {
            found = found.filter {
                if let value = $0.get(for: identifier.key) {
                    return Attribute(identifier.value).isEqual(other: value)
                }
                return false
            }
        }
        return found
    }
    
    internal func isEqual(other: Container) -> Bool {
        guard self.things.count == other.things.count else {
            return false
        }
        
        var ix = self.things.count - 1
        while (0 < ix) {
            if self.things[ix] != other.things[ix] {
                return false
            }
            ix -= 1
        }
        return true
    }

    // conformance to Collection
    public var startIndex: Int {
        return things.startIndex
        
    }
    
    public var endIndex: Int {
        return things.endIndex
    }
    
    public func index(after index: Int) -> Int {
        return things.index(after: index)
    }
    
    public subscript(position: Int) -> Attribution {
        return things[position]
    }
    
    public static func == (lhs: Container, rhs: Container) -> Bool {
        if (lhs === rhs) {
            return true
        }
        return lhs.isEqual(other: rhs)
    }
}

// type erasure?
// c.f. https://appventure.me/2017/12/10/patterns-for-working-with-associated-types/
//open class AnyContainer<T: Attributed & Equatable>: Container<T> {
//    private let _decode: (_ data: Data) -> T?
//    private let _encode: () -> Data?
//    init<U: Cachable>(_ cachable: U) where U.CacheType == T {
//        _decode = cachable.decode
//        _encode = cachable.encode
//    }
//    func decode(_ data: Data) -> T? {
//        return _decode(data)
//    }
//    func encode() -> Data? {
//        return _encode()
//    }
//}
