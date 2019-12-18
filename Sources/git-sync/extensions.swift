//
//  extensions.swift
//  git-sync
//
//  Created by Daniel Marriner on 17/12/2019.
//

import Foundation

let currentDirectory: String = FileManager.default.currentDirectoryPath + "/Git"
var directoryStack: [String] = ["/"]
let directoryBlacklist: [String] = [".DS_Store", ".git-sync"]

struct Root: Codable {
    let subdirs: [Directory]
    let repositories: [Repo]
    
    func create() {
        /// Reset directory stack and current path
        directoryStack = ["/"]
        
        /// Check if directory structure matches git-sync file
        if !checkDir() {
            return
        }
        
        /// Create sub-directories recursively
        self.subdirs.forEach { $0.create() }
        
        /// Clone repositories in this directory
        self.repositories.forEach { $0.create() }
    }
    
    func checkDir() -> Bool {
        /// Reset directory stack and current path
        directoryStack = ["/"]
        
        /// Get contents of current directory
        let directoryContents: [String]
        do {
            directoryContents = try FileManager.default.contentsOfDirectory(atPath: currentDirectory + directoryStack.last!).filter({ !directoryBlacklist.contains($0) }).sorted()
        } catch {
            print("ERROR: Unable to read contents of directory.")
            return false
        }
        let gitSyncDirContents = (self.subdirs.map({ $0.name }) + self.repositories.filter({ !$0.hidden }).map({ $0.name })).sorted()
        
        /// Check if directory contents contain any .git-sync contents
        if directoryContents.containsAny(ofElementsIn: gitSyncDirContents) {
            print("ERROR: Directory contains some git-sync folders that would be")
            print("       overwritten. Please check the folder structure matches")
            print("       your git-sync configuration file and try again.")
            return false
        }
        
        /// Directory clear for creating structure and cloning repositories
        return true
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

public extension Array where Element == String {
    func containsAny(ofElementsIn array: [String]) -> Bool {
        for i in array {
            if self.contains(i) {
                return true
            }
        }
        return false
    }
}
