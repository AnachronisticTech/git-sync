//
//  Checkable.swift
//  git-sync
//
//  Created by Daniel Marriner on 25/03/2020.
//  Copyright © 2020 Daniel Marriner. All rights reserved.
//

import Foundation

protocol Checkable {
    var subdirectories: [GSDirectory] { get }
    var repositories: [GSRepository] { get }
}

extension Checkable {
    func containsNameConflict() -> Bool {
        /// Check for duplicate local directory names
        if (subdirectories.map({ $0.name }) + repositories.filter({ $0.visible }).map({ $0.name })).containsDuplicates() {
            return true
        }
        
        /// Recursively check sub-directories with early exit condition
        for i in self.subdirectories {
            if i.containsNameConflict() {
                return true
            }
        }
        
        return false
    }
    
    func flatten() -> [GSRepository] {
        var repos: [GSRepository] = repositories
        subdirectories.forEach({ repos += $0.flatten() })
        return repos
    }
}
