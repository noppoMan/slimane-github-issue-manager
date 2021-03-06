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

let GITHUB_CLIENT_ID = "8d2581dfffc02599a56e"

let GITHUB_CLIENT_SECRET = "e56778cf29c73cdcb4ab9327f87d452028990467"

let APP_BASE_URL = "http://localhost:\(PORT)"

let GITHUB_API_BASE_URL = "https://api.github.com"

let GITHUB_AUTH_BASE_URL = "https://github.com"