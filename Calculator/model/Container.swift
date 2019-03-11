//
//  Container.swift
//  iRogue
//
//  Created by Michael McGhan on 6/10/18.
//  Copyright © 2018 MSQR Laboratories. All rights reserved.
//

import Foundation

//public protocol Container: AnyObject {
//    associatedtype T : Attributed
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

open class Container<T: Attributed & Equatable>: Attribution, Collection {
    internal static var THING : String {
        get { return "[things]" }     // address key => member of a collection
    }
    public static var UNLIMITED : Int {
        get { return -1 }
    }

    public var things: [T]
    public var capacity: Int
    
    public init(size: Int) {
        self.things = []
        self.capacity = size
        
        super.init()
    }

    public convenience init(things: [T]) {
        self.init(size: things.count)
        self.things = things
    }
    
    public convenience init?(things: [T], size: Int) {
        guard size >= things.count else {
            return nil
        }
        self.init(size: size)
        self.things = things
    }
    
    @discardableResult
    public func add(thing: T) -> Bool {
        guard capacity == Container.UNLIMITED || things.count < capacity else {
            return false
        }
        things.append(thing)
        return true
    }
    
    @discardableResult
    public func remove(thing: T) -> Bool {
        if let index = things.index(of: thing) {
            things.remove(at: index)
            return true
        }
        return false
    }
    
    override
    public func findChildKey(for childId: Int) -> String? {
        // look in the things collection to see if the child is present
        let found = self.things.filter {
            if let value = $0 as? Addressable {
                return childId == value.getUniqueId()
            }
            return false
        }
        return (!found.isEmpty) ? Container.THING : nil
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
    
    public func find(matching: (key: String, value: Any)...) -> [T] {
        var found = things
        for identifier in matching {
            found = found.filter {
                if let value = $0.attributes.get(for: identifier.key) {
                    return Attribute(identifier.value).isEqual(other: value)
                }
                return false
            }
        }
        return found
    }
    
    override
    internal func isEqual(other: Attribution) -> Bool {
        guard let rhs = other as? Container<T>,
            self.things.count == rhs.things.count else {
            return false
        }
        
        var ix = self.things.count - 1
        while (0 < ix) {
            if self.things[ix] != rhs.things[ix] {
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
    
    public subscript(position: Int) -> T {
        return things[position]
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
