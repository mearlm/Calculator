//
//  Address.swift
//  Calculator
//
//  Created by Michael McGhan on 2/24/19.
//  Copyright © 2019 MSQR Laboratories. All rights reserved.
//

import Foundation

// container Attribute types [Distribution, Container and Attribution (map)] are all Addressable
// other primitive Attribute types are not
// so not all children are Addressable, but all parents must be
public protocol Addressable {
    var _parent: Addressable? { get set }               // the root object(s) have no parent
    var _id: Int { get }
    func getAddress() -> Address?
    func getUniqueId() -> Int
    func findChildKey(for childId: Int) -> String?
    @discardableResult
    mutating func reparent(parent: Addressable?) -> Addressable?
}
extension Addressable {
    public func getUniqueId() -> Int {
        return self._id
    }
    
    public func getAddress() -> Address? {
        guard let ancestor = self._parent else {
            return nil
        }
        
        if let key = ancestor.findChildKey(for: self._id) {
            if let path = ancestor.getAddress() {
                let parts = Address.splitKey(address: path.asString())
                return Address(Address.composeKey(path: parts, key: key))
            }
            return Address(key)
        }
        return nil
    }
    
    // reparent for structs; classes need to implement non-mutating reparent methods
    // see: https://www.bignerdranch.com/blog/protocol-oriented-problems-and-the-immutable-self-error/
    @discardableResult
    public mutating func reparent(parent: Addressable?) -> Addressable? {
        let result = self._parent
        self._parent = parent
        
        return result
    }
}

public class Address : Equatable {
    private static let SEP_CHAR = "."
    
    public static func composeKey(path: [String], key: String) -> String {
        let keys = path + [key]
        return keys.joined(separator: Address.SEP_CHAR)
    }
    public static func splitKey(address: String) -> [String] {
        return address.components(separatedBy: Address.SEP_CHAR)
    }
    
    private let key: String
    private let path: [String]
    
    init?(_ address: String) {
        var parts = address.components(separatedBy: Address.SEP_CHAR)
        if 0 == parts.count {
            return nil
        }
        self.key = String(parts.removeLast())
        self.path = parts.map{String($0)}
    }
    
    private func resolvePath(args: Attribution) throws -> Attribution {
        var attribution = args
        
        for part in self.path {
            guard let next = attribution.get(for: part) else {
                let message = "address \(self.asString()) at \(part)"
                throw AttributionError.missingAttribute(for: message)
            }
            attribution = try next.asAttribution()
        }
        return attribution
    }
    
    func exists(args: Attribution) throws -> Bool {
        if let attribution = try? resolvePath(args: args) {
            return attribution.containsKey(for: self.key)
        }
        return false
    }
    
    func fetch(args: Attribution) throws -> Attributable? {
        let attribution = try resolvePath(args: args)
        return attribution.get(for: self.key)
    }

//    func fetch<T>(args: Attribution) throws -> T {
//        let value = try self.fetch(args: args)
//        if let result = value as? T {
//            return result
//        }
//        throw AttributionError.invalidFetch(expected: String(describing: T.self), received: String(describing: type(of: value)))
//    }
    
    // NB: store a nil value => delete key from Attribution
    func store(value: Attributable?, args: Attribution) throws {
        let attribution = try resolvePath(args: args)
        attribution.add(for: key, value: value)
    }
    
    // NB: can't distinguish value-types for attribution.add at compile time
    func store<T>(value: T?, args: Attribution) throws {
        let attribution = try resolvePath(args: args)
        attribution.add(for: key, value: value)
    }
    
    func asString() -> String {
        return Address.composeKey(path: self.path, key: self.key)
    }
    
    public static func ==(lhs: Address, rhs: Address) -> Bool {
        return lhs.key == rhs.key && lhs.path == rhs.path
    }
}
