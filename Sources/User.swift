//
//  User.swift
//  GithubIssueManager
//
//  Created by Yuki Takei on 5/30/16.
//
//
import SwiftRedis

protocol Model {
    var id: String { get set }
    var jsonValue: JSON { get }
}

extension Model {
    func serialize() -> String {
        return JSONSerializer().serializeToString(json: jsonValue)
    }
}

struct User: Model {
    var id: String
    var accessToken: String
    var name: String
    var login: String
    var email: String
    var avatarUrl: String
    
    var jsonValue: JSON {
        let json: JSON = [
             "access_token": accessToken,
             "name": name,
             "login": login,
             "email": email,
             "avatar_url": avatarUrl
        ]
        
        return json
    }
    
    init(json: JSON) throws {
        do {
            id = try json["login"]!.asString()
            accessToken = try json["access_token"]!.asString()
            name = try json["name"]!.asString()
            login = try json["login"]!.asString()
            email = try json["email"]!.asString()
            avatarUrl = try json["avatar_url"]!.asString()
        } catch {
            throw error
        }
    }
}