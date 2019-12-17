//
//  extensions.swift
//  git-sync
//
//  Created by Daniel Marriner on 17/12/2019.
//

import Foundation

var currentDirectory: String = FileManager.default.currentDirectoryPath
var directoryStack: [String] = ["/"]

struct Root: Codable {
    let subdirs: [Directory]
    let repositories: [Repo]
    
    func create() {
        /// Create sub-directories recursively
        self.subdirs.forEach { $0.create() }
        
        /// Clone repositories in this directory
        self.repositories.forEach { $0.create() }
    }
}

struct Directory: Codable {
    let name: String
    let subdirs: [Directory]
    let repositories: [Repo]
    
    func create() {
        /// Check if directory already exists
        if FileManager.default.fileExists(atPath: currentDirectory + directoryStack.last! + "/\(self.name)/") {
            print("Folder \(self.name) already exists")
        }
        
        /// Ignore directory if it will be empty
        if self.subdirs.count == 0 && self.repositories.filter({ !$0.hidden }).count == 0 {
            return
        }
        
        /// Create and enter directory
        do {
            try FileManager.default.createDirectory(atPath: currentDirectory + directoryStack.last! + "/\(self.name)", withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("ERROR: Unable to create directory \(self.name)")
        }
        directoryStack.append(directoryStack.last! + "\(self.name)/")
        
        /// Create sub-directories
        self.subdirs.forEach { $0.create() }
        
        /// Clone repositories in this directory
        self.repositories.forEach { $0.create() }
        
        /// Exit directory
        directoryStack.popLast()
    }
}

struct Repo: Codable {
    let name: String
    let link: String
    let hidden: Bool
    
    func create() {
        /// If repository not marked as hidden, clone into current directory with name
        if !self.hidden {
            print("git cloning \(self.name) in directory \(directoryStack.last!)")
            do {
                try FileManager.default.createDirectory(atPath: currentDirectory + directoryStack.last! + "/\(self.name)", withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("ERROR: Unable to create directory \(self.name)")
            }
        }
    }
}
