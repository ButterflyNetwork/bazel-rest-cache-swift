import Foundation
import LoggerAPI
import SwiftRedis

func redis() -> Redis {
    let redis = Redis()
    let redisUrl = URL(string: ProcessInfo.processInfo.environment["REDIS_URL"]!)!

    let sem = DispatchSemaphore(value: 0)

    redis.connect(
        host: redisUrl.host!,
        port: Int32(redisUrl.port!)
    ) { (error) in
        if let error = error {
            Log.error("Redis: \(error)")
            fatalError()
        } else {
            if let password = redisUrl.password {
                redis.auth(password) { (error) in
                    if let error = error {
                        Log.error("Redis: Failed to authenticate \(error)")
                        fatalError()
                    } else {
                        _ = sem.signal()
                    }
                }
            } else {
                sem.signal()
            }
        }
    }

    sem.wait()

    return redis
}
