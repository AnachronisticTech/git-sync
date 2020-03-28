//
//  GSDirectory.swift
//  git-sync
//
//  Created by Daniel Marriner on 25/03/2020.
//  Copyright © 2020 Daniel Marriner. All rights reserved.
//

import Foundation

struct GSDirectory: Codable {
    let name: String
    let subdirectories: [GSDirectory]
    var repositories: [GSRepository]
}

extension GSDirectory: Checkable {
    func create() {
        /// Check if directory already exists
        if FileManager.default.fileExists(atPath: currentDirectory + directoryStack.last! + "/\(self.name)/") {
            print("Folder \(self.name) already exists")
        }
        
        /// Ignore directory if it will be empty
        if self.subdirectories.count == 0 && self.repositories.filter({ $0.visible }).count == 0 { return }
        
        /// Create and enter directory
        do {
            try FileManager.default.createDirectory(atPath: currentDirectory + directoryStack.last! + "/\(self.name)", withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("ERROR: Unable to create directory \(self.name)")
        }
        directoryStack.append(directoryStack.last! + "\(self.name)/")
        
        /// Create sub-directories
        self.subdirectories.forEach { $0.create() }
        
        /// Clone repositories in this directory
        self.repositories.forEach { $0.create() }
        
        /// Get contents of directory and delete if empty
        do {
            let contents = try FileManager.default.contentsOfDirectory(atPath: currentDirectory + directoryStack.last!)
            if contents.count == 0 {
                try FileManager.default.removeItem(atPath: currentDirectory + directoryStack.last!)
            }
        } catch {
            print("ERROR: Unable to delete empty directory \(directoryStack.last!)")
        }
        
        /// Exit directory
        let _ = directoryStack.popLast()
    }
    
    func write(with depth: Int) -> String {
        let indent = Array(repeating: "\t", count: depth)
        var arr = [
            "\(indent.string())in \(self.name) {\n"
        ]
        self.subdirectories.forEach { dir in
            arr.append(dir.write(with: depth + 1) + "\n")
        }
        self.repositories.forEach { repo in
            arr.append(repo.write(with: depth + 1) + "\n")
        }
        arr.append("\(indent.string())}\n")
        return arr.string()
    }
}
