//
//  SessionConfig.swift
//  GithubIssueManager
//
//  Created by Yuki Takei on 5/29/16.
//
//

import SessionRedisStore

func sessionConfig() throws -> SessionConfig {
    switch SLIMANE_ENV {
    default:
        return SessionConfig(
            secret: "aa4f0b4429960862cbaccba163b81d9bd4c06938",
            expires: 3600, // 1h
            store: try RedisStore(loop: Loop.defaultLoop, host: "127.0.0.1", port: 6379)
        )
    }
}