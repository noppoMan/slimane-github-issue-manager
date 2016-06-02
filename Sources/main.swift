if Process.arguments.count > 1 {
    let mode = Process.arguments[1]
    
    if mode == "--cluster" {
        
        func observeWorker(_ worker: inout Worker){
            worker.send(.Message("message from master"))
            
            worker.on { event in
                if case .Message(let str) = event {
                    print(str)
                }
                    
                else if case .Online = event {
                    print("Worker: \(worker.id) is online")
                }
                    
                else if case .Exit(let status) = event {
                    print("Worker: \(worker.id) is dead. status: \(status)")
                    worker = try! Cluster.fork(silent: false)
                    observeWorker(&worker)
                }
            }
        }
        
        // For Cluster app
        if Cluster.isMaster {
            print("Cluster mode ready...")
            for _ in 0..<OS.cpuCount {
                var worker = try! Cluster.fork(silent: false)
                observeWorker(&worker)
            }
            
            try! Slimane().listen(port: PORT)
        } else {
            launchApp()
        }
    }
} else {
    // for single thread app
    launchApp()
}
