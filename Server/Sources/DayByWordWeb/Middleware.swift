import HTTPTypes
import Hummingbird
import Logging

/// Logs one line per request with request metadata only: the method, the
/// matched route pattern (never the concrete path or query), the status, and
/// the duration. Server logs never record passages, plans, reading events, or
/// personal data (docs/decisions.md E17).
struct RequestLogMiddleware<Context: RequestContext>: RouterMiddleware {
    func handle(
        _ request: Request,
        context: Context,
        next: (Request, Context) async throws -> Response
    ) async throws -> Response {
        let start = ContinuousClock.now
        do {
            let response = try await next(request, context)
            log(request, context, status: response.status, since: start)
            return response
        } catch {
            let status = (error as? any HTTPResponseError)?.status ?? .internalServerError
            log(request, context, status: status, since: start)
            throw error
        }
    }

    private func log(_ request: Request, _ context: Context, status: HTTPResponse.Status, since start: ContinuousClock.Instant) {
        let elapsed = (ContinuousClock.now - start).components
        let milliseconds = elapsed.seconds * 1000 + elapsed.attoseconds / 1_000_000_000_000_000
        context.logger.info(
            "request",
            metadata: [
                "method": "\(request.method.rawValue)",
                "route": "\(context.endpointPath ?? "unmatched")",
                "status": "\(status.code)",
                "ms": "\(milliseconds)",
            ]
        )
    }
}

/// Adds the security headers every response carries, errors included: a
/// strict Content Security Policy that allows nothing from other hosts
/// (docs/decisions.md E11), a Permissions Policy that turns off powerful
/// features the site never uses, and the usual hardening headers. HSTS is set
/// by Caddy in front of the server (docs/deploy.md).
struct SecurityHeadersMiddleware<Context: RequestContext>: RouterMiddleware {
    static var headers: HTTPFields {
        var headers = HTTPFields()
        headers[.contentSecurityPolicy] = [
            "default-src 'none'",
            "script-src 'self'",
            "style-src 'self'",
            "img-src 'self'",
            "font-src 'self'",
            "connect-src 'self'",
            "manifest-src 'self'",
            "worker-src 'self'",
            "form-action 'self'",
            "base-uri 'none'",
            "frame-ancestors 'none'",
        ].joined(separator: "; ")
        headers[HTTPField.Name("Permissions-Policy")!] =
            "camera=(), microphone=(), geolocation=(), payment=(), usb=()"
        headers[HTTPField.Name("X-Content-Type-Options")!] = "nosniff"
        headers[HTTPField.Name("Referrer-Policy")!] = "no-referrer"
        headers[HTTPField.Name("Cross-Origin-Opener-Policy")!] = "same-origin"
        headers[HTTPField.Name("X-Frame-Options")!] = "DENY"
        return headers
    }

    func handle(
        _ request: Request,
        context: Context,
        next: (Request, Context) async throws -> Response
    ) async throws -> Response {
        var response: Response
        do {
            response = try await next(request, context)
        } catch let error as any HTTPResponseError {
            response = try error.response(from: request, context: context)
        }
        for field in Self.headers where response.headers[field.name] == nil {
            response.headers.append(field)
        }
        return response
    }
}
