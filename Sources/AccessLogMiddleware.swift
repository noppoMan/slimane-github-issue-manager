//
//  AccessLogMiddleware.swift
//  GithubIssueManager
//
//  Created by Yuki Takei on 5/31/16.
//
//

// Session
public struct AccessLogMiddleware: MiddlewareType {
    public init(){}
    
    public func respond(_ req: Request, res: Response, next: MiddlewareChain) {
        print("[pid:\(Process.pid)]\t\(Time())\t\(req.path ?? "/")")
        next(.Chain(req, res))
    }
}

