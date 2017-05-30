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
    Log.info("HEAD: \(request.parameters["key"] ?? "")")

    if let key = request.parameters["key"] {
        redis().exists(key) { (count, err) in
            if let count = count, count > 0 {
                Log.info("Hit: \(request.parameters["key"] ?? "")")
                response
                    .status(.OK)
                    .send("")
            } else {
                Log.info("Miss: \(request.parameters["key"] ?? "")")
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
    Log.info("GET: \(request.parameters["key"] ?? "")")

    if let key = request.parameters["key"] {
        redis().get(key) { (str, err) in
            if let data = str?.asData {
                Log.info("Hit: \(request.parameters["key"] ?? "")")
                response
                    .status(.OK)
                    .send(data: data)
            } else {
                Log.info("Miss: \(request.parameters["key"] ?? "")")
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
    Log.info("PUT: \(request.parameters["key"] ?? "")")

    if let key = request.parameters["key"],
       let body = request.body {
        switch body {
        case .raw(let data):
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
