import Foundation
import HeliumLogger
import Kitura
import KituraCompression

HeliumLogger.use(.info)

let router: Router = {
    let router = Router()
    router.all(middleware: BodyParser())
    router.all(middleware: Compression())
    return router
}()

let cache: Cache = {
    return Cache(router: router)
}()

Kitura.addHTTPServer(
    onPort: Int(ProcessInfo.processInfo.environment["PORT"] ?? "8080") ?? 8080,
    with: router
)

Kitura.run()
