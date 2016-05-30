//
//  GithubAPIRequest.swift
//  GithubIssueManager
//
//  Created by Yuki Takei on 5/30/16.
//
//

struct GithubApiRequest {
    let uriRoot = GITHUB_API_BASE_URL
    
    let method: S4.Method
    
    let resource: String
    
    let headers: Headers
    
    let body: Data
    
    init(token: String, method: S4.Method = .get, resource: String, body: Data = []) {
        self.init(method: method, resource: resource, headers: ["Authorization": Header("token \(token)")], body: body)
    }
    
    init(method: S4.Method = .get, resource: String, headers: Headers = [:], body: Data = []) {
        self.method = method
        self.resource = resource
        self.headers = headers
        self.body = body
    }
    
    func send() -> Promise<Response> {
        let client = RestClient(method: method, uri: "\(uriRoot)\(resource)", headers: headers, body: body)
        return client.send()
    }
}
