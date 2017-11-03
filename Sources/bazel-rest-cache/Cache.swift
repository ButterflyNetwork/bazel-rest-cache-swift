import Foundation
import Kitura
import LoggerAPI
import SwiftRedis

final class Cache {

    init(router: Router) {
        addRoutes(router: router)
    }

    // MARK: Private

    private let byteCountFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [
            .useKB,
            .useMB,
            .useGB,
        ]
        return formatter
    }()

    private func addRoutes(router: Router) {
        let prefixes = [
            "ac",  // ActionCache.
            "cas", // Content-aware storage.
        ]
        prefixes.forEach { prefix in
            let path = "/cache/\(prefix)/:key"
            router.head(path) { request, response, next in
                self.head(
                    prefix: prefix,
                    request: request,
                    response: response,
                    next: next
                )
            }
            router.get(path) { request, response, next in
                self.get(
                    prefix: prefix,
                    request: request,
                    response: response,
                    next: next
                )
            }
            router.put(path) { request, response, next in
                self.put(
                    prefix: prefix,
                    request: request,
                    response: response,
                    next: next
                )
            }
        }
    }

    private func head(
        prefix: String,
        request: RouterRequest,
        response: RouterResponse,
        next: @escaping () -> Void
    ) {
        if let key = request.parameters["key"] {
            let cacheKey = prefixKey(prefix: prefix, key: key)
            redis().exists(cacheKey) { (count, err) in
                if let count = count, count > 0 {
                    Log.info("HEAD - HIT: \(cacheKey)",
                        functionName: ""
                    )
                    response
                        .status(.OK)
                        .send("")
                } else {
                    Log.info("HEAD - MISS: \(cacheKey)",
                        functionName: ""
                    )
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

    private func get(
        prefix: String,
        request: RouterRequest,
        response: RouterResponse,
        next: @escaping () -> Void
    ) {
        if let key = request.parameters["key"] {
            let cacheKey = prefixKey(prefix: prefix, key: key)
            redis().get(cacheKey) { (str, err) in
                if let data = str?.asData {
                    let byteCount = byteCountFormatter.string(fromByteCount: Int64(data.count))
                    Log.info("GET - HIT: \(byteCount) -> \(cacheKey)",
                        functionName: ""
                    )
                    response
                        .status(.OK)
                        .send(data: data)
                } else {
                    Log.info("GET - MISS: \(cacheKey)",
                        functionName: ""
                    )
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


    private func put(
        prefix: String,
        request: RouterRequest,
        response: RouterResponse,
        next: @escaping () -> Void
    ) {
        if let key = request.parameters["key"],
            let body = request.body {
            let cacheKey = prefixKey(prefix: prefix, key: key)
            switch body {
            case .raw(let data):
                let byteCount = byteCountFormatter.string(fromByteCount: Int64(data.count))
                Log.info("PUT: \(byteCount) -> \(cacheKey)",
                    functionName: ""
                )
                redis().set(cacheKey, value: RedisString(data)) { (didSet, err) in
                    if didSet {
                        response
                            .status(.OK)
                            .send("")
                    } else {
                        if let err = err {
                            Log.error("PUT: Error: \(String(describing: err))",
                                functionName: ""
                            )
                        }
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

    private func prefixKey(prefix: String, key: String) -> String {
        return "\(prefix)_\(key)"
    }

}
