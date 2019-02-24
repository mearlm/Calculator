//
//  Address.swift
//  Calculator
//
//  Created by Michael McGhan on 2/24/19.
//  Copyright © 2019 MSQR Laboratories. All rights reserved.
//

import Foundation

public class Address : Equatable {
    private let key: String
    private let path: [String]
    
    init(_ address: String) {
        var parts = address.split(separator: ".")
        self.key = String(parts.removeLast())
        self.path = parts.map{String($0)}
    }
    
    private func resolvePath(args: Attribution) throws -> Attribution {
        var attribution = args
        
        for part in self.path {
            guard let next = attribution.get(for: part) else {
                let message = "Attribution \(self.path.joined()) at \(part)"
                throw AttributionError.missingAttribute(for: message)
            }
            attribution = try next.asAttribution()
        }
        return attribution
    }
    
    func exists(args: Attribution) throws -> Bool {
        let attribution = try resolvePath(args: args)
        return attribution.containsKey(for: self.key)
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
    
    func asString() -> String {
        var parts = self.path
        parts.append(key)
        
        return parts.joined(separator: ".")
    }
    
    public static func ==(lhs: Address, rhs: Address) -> Bool {
        return lhs.key == rhs.key && lhs.path == rhs.path
    }
}
