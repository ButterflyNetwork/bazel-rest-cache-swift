import Foundation
import HeliumLogger
import Kitura
import LoggerAPI
import SwiftRedis

HeliumLogger.use()

let router = Router()

func redis() -> Redis {
    let redis = Redis()
    let redisUrl = URL(string: ProcessInfo.processInfo.environment["REDIS_URL"]!)!
    Log.info("Redis: Connecting to \(redisUrl)")

    redis.connect(
        host: redisUrl.host!,
        port: Int32(redisUrl.port!)
    ) { (error) in
        if let error = error {
            Log.error("Redis: \(error)")
            fatalError()
        } else {
            Log.info("Redis: Connected to \(redisUrl)")

            redis.auth(redisUrl.password!) { (error) in
                if let error = error {
                    Log.error("Redis: Failed to authenticate \(error)")
                    fatalError()
                } else {
                    Log.info("Redis: Authenticated")
                }
            }
        }
    }

    return redis
}

router.get("/") { request, response, next in
    redis().incr("HELLO_WORLD") { (value, error) in
        defer { next() }

        if let error = error {
            Log.error("Redis: \(error)")
            response.send("Sad world :(")
        } else {
            if let value = value {
                response.send("Hello, World! #\(value)")
            } else {
                response.send("Sad world :(")
            }
        }
    }
}

Kitura.addHTTPServer(
    onPort: Int(ProcessInfo.processInfo.environment["PORT"] ?? "8090") ?? 8090,
    with: router
)

Kitura.run()
