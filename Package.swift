import PackageDescription

let package = Package(
    name: "GithubIssueManager",
  	dependencies: [
      .Package(url: "https://github.com/noppoMan/Slimane.git", majorVersion: 0, minor: 4),
      .Package(url: "https://github.com/slimane-swift/BodyParser.git", majorVersion: 0, minor: 3),
      .Package(url: "https://github.com/slimane-swift/Render.git", majorVersion: 0, minor: 3),
      .Package(url: "https://github.com/slimane-swift/MustacheViewEngine.git", majorVersion: 0, minor: 3),
      .Package(url: "https://github.com/slimane-swift/WS.git", majorVersion: 0, minor: 2),
      .Package(url: "https://github.com/slimane-swift/Time.git", majorVersion: 0, minor: 2),
      .Package(url: "https://github.com/slimane-swift/QWFuture.git", majorVersion: 0, minor: 1),
      .Package(url: "https://github.com/noppoMan/Thrush.git", majorVersion: 0, minor: 1),
      .Package(url: "https://github.com/slimane-swift/JSON.git", majorVersion: 0, minor: 7),
      .Package(url: "https://github.com/slimane-swift/SessionRedisStore.git", majorVersion: 0, minor: 3),
      .Package(url: "https://github.com/IBM-Swift/CCurl.git", majorVersion: 0, minor: 1),
   ]
)
