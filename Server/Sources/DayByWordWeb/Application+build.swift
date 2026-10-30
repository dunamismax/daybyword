import Hummingbird
import Logging
import ReadingData

/// Builds the application from its configuration, checking the catalog first
/// so that a missing or unreadable catalog stops the server at start-up with a
/// clear message rather than failing later on a reader's request.
public func buildApplication(_ configuration: ServerConfiguration) throws -> some ApplicationProtocol {
    var logger = Logger(label: "DayByWordServer")
    logger.logLevel = configuration.logLevel

    if let path = configuration.catalogPath {
        let catalog = try CatalogMetadata.read(path: path)
        logger.info(
            "catalog opened",
            metadata: ["schema": "\(catalog.schemaVersion)", "build": "\(catalog.buildMode)"]
        )
    } else {
        logger.notice("no catalog configured (DBW_CATALOG); serving without one in development")
    }

    return Application(
        router: buildRouter(configuration),
        configuration: .init(address: .hostname(configuration.host, port: configuration.port)),
        logger: logger
    )
}

/// The routes and the middleware around them.
func buildRouter(_ configuration: ServerConfiguration) -> Router<BasicRequestContext> {
    let router = Router()
    router.add(middleware: RequestLogMiddleware())
    router.add(middleware: SecurityHeadersMiddleware())
    router.add(middleware: FileMiddleware(configuration.publicDirectory, searchForIndexHtml: false))

    router.get("/") { _, _ in Pages.home() }

    // The health check that Caddy, deploys, and monitoring use.
    router.get("/up") { _, _ in
        var headers = HTTPFields()
        headers[.contentType] = "text/plain; charset=utf-8"
        headers[.cacheControl] = "no-store"
        return Response(status: .ok, headers: headers, body: .init(byteBuffer: ByteBuffer(string: "OK\n")))
    }

    return router
}
