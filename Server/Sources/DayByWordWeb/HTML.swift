import Hummingbird

/// A fragment of HTML.
///
/// Markup is written as string literals, and interpolated text is escaped
/// unless it is itself `HTML`, so a reader's input or a plan's title can never
/// become markup by accident (docs/decisions.md E19).
///
///     let title = "Psalms & Proverbs"
///     let heading: HTML = "<h1>\(title)</h1>"   // <h1>Psalms &amp; Proverbs</h1>
public struct HTML: Sendable, Equatable, ExpressibleByStringInterpolation, ResponseGenerator {
    /// The markup, ready to send.
    public let rendered: String

    public init(stringLiteral literal: String) {
        rendered = literal
    }

    public init(stringInterpolation interpolation: StringInterpolation) {
        rendered = interpolation.output
    }

    /// Joins fragments, as for the rows of a list.
    public init(_ fragments: some Sequence<HTML>) {
        rendered = fragments.map(\.rendered).joined()
    }

    public struct StringInterpolation: StringInterpolationProtocol {
        var output = ""

        public init(literalCapacity: Int, interpolationCount: Int) {
            output.reserveCapacity(literalCapacity + interpolationCount * 16)
        }

        public mutating func appendLiteral(_ literal: String) {
            output += literal
        }

        /// Text, escaped.
        public mutating func appendInterpolation(_ text: String) {
            output += HTML.escape(text)
        }

        /// A number, written in plain digits.
        public mutating func appendInterpolation(_ number: Int) {
            output += String(number)
        }

        /// Markup, included as it is.
        public mutating func appendInterpolation(_ html: HTML) {
            output += html.rendered
        }
    }

    /// Escapes the characters that are significant in HTML text and in quoted
    /// attribute values.
    public static func escape(_ text: String) -> String {
        var escaped = ""
        escaped.reserveCapacity(text.utf8.count)
        for character in text {
            switch character {
            case "&": escaped += "&amp;"
            case "<": escaped += "&lt;"
            case ">": escaped += "&gt;"
            case "\"": escaped += "&quot;"
            case "'": escaped += "&#39;"
            default: escaped.append(character)
            }
        }
        return escaped
    }

    public func response(from request: Request, context: some RequestContext) throws -> Response {
        var headers = HTTPFields()
        headers[.contentType] = "text/html; charset=utf-8"
        return Response(status: .ok, headers: headers, body: .init(byteBuffer: ByteBuffer(string: rendered)))
    }
}
