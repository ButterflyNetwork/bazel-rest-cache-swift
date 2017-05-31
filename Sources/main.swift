import Foundation
import HeliumLogger
import Kitura
import KituraCompression
import LoggerAPI
import SwiftRedis

HeliumLogger.use(.info)

let router: Router = {
    let router = Router()
    router.all(middleware: BodyParser())
    router.all(middleware: Compression())
    return router
}()

let byteCountFormatter: ByteCountFormatter = {
    let formatter = ByteCountFormatter()
    formatter.allowedUnits = [
        .useKB,
        .useMB,
        .useGB,
    ]
    return formatter
}()

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

router.head("/cache/:key") { request, response, next in
    if let key = request.parameters["key"] {
        redis().exists(key) { (count, err) in
            if let count = count, count > 0 {
                Log.info("HEAD - HIT: \(request.parameters["key"] ?? "")")
                response
                    .status(.OK)
                    .send("")
            } else {
                Log.info("HEAD - MISS: \(request.parameters["key"] ?? "")")
                response
                    .status(.notFound)
                    .send("")
            }

            next()
        }
    } else {
        response
            .status(.badRequest)
            .send("")
        next()
    }
}

router.get("/cache/:key") { request, response, next in
    if let key = request.parameters["key"] {
        redis().get(key) { (str, err) in
            if let data = str?.asData {
                let byteCount = byteCountFormatter.string(fromByteCount: Int64(data.count))
                Log.info("GET - HIT: \(byteCount) -> \(request.parameters["key"] ?? "")")
                response
                    .status(.OK)
                    .send(data: data)
            } else {
                Log.info("GET - MISS: \(request.parameters["key"] ?? "")")
                response
                    .status(.notFound)
                    .send("")
            }

            next()
        }
    } else {
        response
            .status(.badRequest)
            .send("")
        next()
    }
}

router.put("/cache/:key") { request, response, next in
    if let key = request.parameters["key"],
       let body = request.body {
        switch body {
        case .raw(let data):
            let byteCount = byteCountFormatter.string(fromByteCount: Int64(data.count))
            Log.info("PUT: \(byteCount) -> \(request.parameters["key"] ?? "")")
            redis().set(key, value: RedisString(data)) { (didSet, err) in
                if didSet {
                    response
                        .status(.OK)
                        .send("")
                } else {
                    response
                        .status(.internalServerError)
                        .send("")
                }

                next()
            }
        default:
            response
                .status(.badRequest)
                .send("")
            next()
        }
    } else {
        response
            .status(.badRequest)
            .send("")
        next()
    }
}

Kitura.addHTTPServer(
    onPort: Int(ProcessInfo.processInfo.environment["PORT"] ?? "8080") ?? 8080,
    with: router
)

Kitura.run()
