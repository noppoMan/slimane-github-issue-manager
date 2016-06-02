//
//  Redis.swift
//  GithubIssueManager
//
//  Created by Yuki Takei on 5/29/16.
//
//

import SwiftRedis

enum RedisReply {
    case list([String])
    case string(String)
}

extension Redis {
    static func commandAsync(_ connection: SwiftRedis.Connection, command: SwiftRedis.Commands) -> Promise<RedisReply> {
        return Promise<RedisReply> { resolve, reject in
            self.command(connection, command: command) { result in
                if case .Error(let error) = result {
                    reject(error)
                }
                else if case .Success(let rep) = result {
                    if let rep = rep as? [String] {
                        resolve(.list(rep))
                    }
                    else if let rep = rep as? String {
                        resolve(.string(rep))
                    }
                }
            }
        }
    }

    public static func publish(_ connection: SwiftRedis.Connection, channel: String, data: String,  callback: (SwiftRedis.GenericResult<Any>) -> ()) {
        Redis.command(connection, command: .RAW(["PUBLISH", channel, data]), completion: callback)
    }
    
    public static func subscribe(_ connection: SwiftRedis.Connection, channel: String, callback: (SwiftRedis.GenericResult<Any>) -> ()) {
        Redis.command(connection, command: .RAW(["SUBSCRIBE", channel]), completion: callback)
    }
    
    public static func unsubscribe(_ connection: SwiftRedis.Connection, channel: String, callback: (SwiftRedis.GenericResult<Any>) -> ()) {
        Redis.command(connection, command: .RAW(["UNSUBSCRIBE", channel]), completion: callback)
    }
}
