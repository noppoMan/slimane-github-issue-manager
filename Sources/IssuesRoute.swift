//
//  IssuesRoute.swift
//  GithubIssueManager
//
//  Created by Yuki Takei on 5/29/16.
//
//

import HTTP

struct IssuesRoute {
    static func index(req: Request, responder: ((Void) throws -> Response) -> Void){
        GithubApiRequest(
            token: req.currentUser!.accessToken,
            resource: "/repos/\(req.params["owner"]!)/\(req.params["repo"]!)/issues"
        )
        .send()
        .then { response in
            responder {
                Response(json: response.jsonData!)
            }
        }
    }
}
