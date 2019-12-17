//
//  extensions.swift
//  OctoKit
//
//  Created by Daniel Marriner on 17/12/2019.
//

import Foundation

struct Directory: Codable {
    let name: String
    let subdirs: [Directory]
    let repositories: [Repo]
}

struct Repo: Codable {
    let name: String
    let link: String
    let hidden: Bool
}
