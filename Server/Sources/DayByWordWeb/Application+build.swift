import Hummingbird
import Logging
import ReadingData
import ReadingEngine

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
        router: buildRouter(configuration, logger: logger),
        configuration: .init(address: .hostname(configuration.host, port: configuration.port)),
        logger: logger
    )
}

/// The routes and the middleware around them.
func buildRouter(_ configuration: ServerConfiguration, logger: Logger) -> Router<BasicRequestContext> {
    let router = Router()
    router.add(middleware: RequestLogMiddleware())
    router.add(middleware: SecurityHeadersMiddleware())
    router.add(middleware: NotFoundPageMiddleware())
    router.add(middleware: FileMiddleware(configuration.publicDirectory, searchForIndexHtml: false, logger: logger))

    router.get("/") { _, _ in Pages.home() }
    router.get("/today") { _, _ in Pages.today() }
    router.get("/plans") { _, _ in Pages.plans() }
    router.get("/plans/:id") { _, context in
        Pages.plan(try planID(context))
    }
    router.get("/plans/:id/week") { request, context in
        Pages.planWeek(try planID(context), start: Pages.startDate(request.uri.queryParameters["start"]))
    }
    router.get("/progress") { _, _ in Pages.progress() }
    router.get("/settings") { _, _ in Pages.settings(commit: configuration.commit) }

    if configuration.environment == .development {
        router.get("/dev/components") { _, _ in Pages.componentGallery() }
    }

    // The health check that Caddy, deploys, and monitoring use.
    router.get("/up") { _, _ in
        var headers = HTTPFields()
        headers[.contentType] = "text/plain; charset=utf-8"
        headers[.cacheControl] = "no-store"
        return Response(status: .ok, headers: headers, body: .init(byteBuffer: ByteBuffer(string: "OK\n")))
    }

    return router
}

/// The plan id in an address. Anything that is not a plan id is not found
/// (docs/urls.md).
private func planID(_ context: some RequestContext) throws -> PlanID {
    guard let text = context.parameters.get("id"), let id = PlanID(text) else {
        throw HTTPError(.notFound)
    }
    return id
}
