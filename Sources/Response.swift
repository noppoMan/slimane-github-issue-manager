//
//  Response.swift
//  GithubIssueManager
//
//  Created by Yuki Takei on 5/29/16.
//
//

import HTTP
import MustacheViewEngine
import Render

extension Response {
    static func render(_ path: String, data: TemplateData = ["foo": "bar"]) -> Response {
        let render = Render(engine: MustacheViewEngine(templateData: data), path: path)
        return Response(custom: render)
    }
    
    init(status: Status = .ok, headers: Headers = [:], json: JSON) {
        var headers = headers
        headers["Content-Type"] = Header("application/json")
        self.init(status: status, headers: headers, body: JSONSerializer().serialize(json: json))
    }
}
