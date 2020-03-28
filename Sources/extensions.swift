//
//  extensions.swift
//  git-sync
//
//  Created by Daniel Marriner on 17/12/2019.
//

import Foundation

public extension Array where Element == String {
    func containsAny(ofElementsIn array: [String]) -> Bool {
        for i in array {
            if self.contains(i) {
                return true
            }
        }
        return false
    }
    
    func containsDuplicates() -> Bool {
        return self.sorted() != Array(Set(self)).sorted()
    }
    
    func string() -> String {
        var tmp = ""
        self.forEach { tmp += $0 }
        return tmp
    }
}

public extension String {
    func getPrefix(regex: String) -> String? {
        let expression = try! NSRegularExpression(pattern: "^\(regex)", options: [])
        let range = expression.rangeOfFirstMatch(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count))
        if range.location == 0 {
            return (self as NSString).substring(with: range)
        }
        return nil
    }
    
    mutating func trimLeadingWhitespace() {
        let i = startIndex
        while i < endIndex {
            guard CharacterSet.whitespacesAndNewlines.contains(self[i].unicodeScalars.first!) else {
                return
            }
            self.remove(at: i)
        }
    }
}

public extension Dictionary where Key == String, Value == String {
    func firstKey(for value: String) -> String? {
        for (key, val) in self {
            if val == value { return key }
        }
        return nil
    }
}
