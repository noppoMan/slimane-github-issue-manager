//
//  consts.swift
//  GithubIssueManager
//
//  Created by Yuki Takei on 5/29/16.
//
//

// constants for the app information
let SLIMANE_ENV = Process.env["SLIMANE_ENV"] ?? "development"

let PORT = Int(Process.env["PORT"] ?? "3000")!

let GITHUB_CLIENT_ID = ""

let GITHUB_CLIENT_SECRET = ""

let APP_BASE_URL = "http://localhost:\(PORT)"

let GITHUB_API_BASE_URL = "https://api.github.com"

let GITHUB_AUTH_BASE_URL = "https://github.com"