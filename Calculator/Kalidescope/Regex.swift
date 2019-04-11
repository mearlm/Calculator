//
//  Regex.swift
//  Kaleidoscope
//
//  Created by Matthew Cheok on 15/11/15.
//  Copyright © 2015 Matthew Cheok. All rights reserved.
//

import Foundation

var expressions = [String: NSRegularExpression]()
public extension String {
    private var _DEBUG : Bool { get {
        return false
    }}
    private func dprint(_ text: String) {
        if _DEBUG {
            print(text)
        }
    }
    
    func match(regex: String) -> [String]? {
        dprint("regex: \(regex), string: \"\(self)\"")

        let expression: NSRegularExpression
        if let exists = expressions[regex] {
            expression = exists
        } else {
            expression = try! NSRegularExpression(pattern: "^\(regex)", options: [])
            expressions[regex] = expression
        }
        
        let string = self as NSString
        
        let matches = expression.matches(in: self, options: [], range: NSRange(location: 0, length: string.length))
        
        // ToDo: handle multiple matches
        guard let match = matches.first else { return nil }
        dprint("count: \(matches.count), \(match.numberOfRanges)")

        // Note: Index 1 is 1st capture group, 2 is 2nd, ..., while index 0 is full match which we don't use
        var results = [String]()
        
        for i in 0..<match.numberOfRanges {
            let capturedGroupIndex = match.range(at: i)
            dprint("group \(i) @ \(capturedGroupIndex)")
            let matchedString = (self as NSString).substring(with: capturedGroupIndex)
            results.append(matchedString)
        }

        dprint(String(describing: results))

        return results
    }
}
