import Foundation

/// The ways of naming the books of the Bible a reader can choose from (D29).
/// Common English is the default; the others give a tradition's own names
/// where they differ, such as "Song of Solomon" or "Canticle of Canticles".
public enum NamingConvention: String, CaseIterable, Sendable, Codable, CodingKeyRepresentable {
    case common
    case kjv
    case douay
}

public enum Testament: String, Sendable, Codable {
    case old
    case new
}

/// The books of the Bible, their names under each naming convention, the
/// canons that contain them, and the orders those canons are printed in,
/// read from `catalog/scripture/books.json` and checked as it is read
/// (docs/decisions.md E27).
public struct BookRegistry: Sendable {
    /// A book's name and its abbreviation under one convention. A name with
    /// no abbreviation is shown in full even where space is short, because
    /// the registry only abbreviates as its sources do.
    public struct BookName: Sendable, Hashable, Codable {
        public let name: String
        public let abbreviation: String?

        public init(name: String, abbreviation: String?) {
            self.name = name
            self.abbreviation = abbreviation
        }
    }

    public struct Book: Sendable, Hashable {
        public let id: BookID
        public let testament: Testament
        /// The common English name.
        public let commonName: BookName
        /// The names a convention gives where it differs from the common one.
        public let otherNames: [NamingConvention: BookName]
        public let note: String?

        public func name(in convention: NamingConvention) -> BookName {
            otherNames[convention] ?? commonName
        }
    }

    public struct Order: Sendable, Hashable {
        public let id: String
        public let label: String
        public let books: [BookID]
        public let sources: [String]
    }

    public struct Canon: Sendable, Hashable {
        public let id: String
        public let label: String
        public let description: String
        /// The orders this canon is printed in; every one lists the same books.
        public let orders: [Order]
        /// Material a listed book contains that other Bibles print apart, such
        /// as Daniel's Greek additions: `DAN` includes `S3Y`, `SUS`, and `BEL`.
        public let includes: [BookID: [BookID]]
        public let includesSources: [String]

        /// The books this canon lists, in its first order.
        public var books: [BookID] { orders[0].books }

        /// Whether the canon has this book, as a book of its own or inside one.
        public func contains(_ book: BookID) -> Bool {
            books.contains(book) || bookIncluding(book) != nil
        }

        /// The listed book that holds this material, if the canon includes it
        /// inside another book.
        public func bookIncluding(_ book: BookID) -> BookID? {
            includes.first { $0.value.contains(book) }?.key
        }
    }

    public struct Convention: Sendable, Hashable {
        public let id: NamingConvention
        public let label: String
        public let example: String
        public let rule: String
        public let sources: [String]
    }

    public struct Source: Sendable, Hashable, Codable {
        public let id: String
        public let title: String
        public let publisher: String
        public let url: String
        public let alsoChecked: String?
        public let checked: String
        public let usedFor: String
    }

    public let conventions: [Convention]
    public let books: [Book]
    public let canons: [Canon]
    public let sources: [Source]

    /// The registry format this build reads.
    public static let format = 1

    /// Reads and checks a registry, throwing the first problem found.
    public init(json: Data) throws {
        let file: File
        do {
            file = try JSONDecoder().decode(File.self, from: json)
        } catch {
            throw BookRegistryError.unreadable(String(describing: error))
        }
        guard file.format == Self.format else { throw BookRegistryError.unsupportedFormat(file.format) }

        let sourceIDs = try Self.unique(file.sources.map(\.id), BookRegistryError.duplicateSource)
        var usedSources: Set<String> = []
        func checkSources(_ ids: [String], in place: String) throws {
            for id in ids {
                guard sourceIDs.contains(id) else { throw BookRegistryError.unknownSource(id, in: place) }
                usedSources.insert(id)
            }
        }

        _ = try Self.unique(file.conventions.map(\.id), BookRegistryError.duplicateConvention)
        for convention in NamingConvention.allCases where !file.conventions.contains(where: { $0.id == convention }) {
            throw BookRegistryError.missingConvention(convention)
        }
        for convention in file.conventions { try checkSources(convention.sources, in: convention.id.rawValue) }

        let bookIDs = try Self.unique(file.books.map(\.id), BookRegistryError.duplicateBook)
        let books = try file.books.map { entry in
            let common = BookName(name: entry.name, abbreviation: entry.abbreviation)
            for name in [common] + (entry.names.map { Array($0.values) } ?? []) {
                guard !name.name.isEmpty, name.abbreviation?.isEmpty != true else {
                    throw BookRegistryError.emptyName(entry.id)
                }
            }
            for (convention, name) in entry.names ?? [:] where name == common || convention == .common {
                throw BookRegistryError.redundantName(entry.id, convention)
            }
            return Book(
                id: entry.id, testament: entry.testament, commonName: common, otherNames: entry.names ?? [:],
                note: entry.note)
        }

        for convention in NamingConvention.allCases {
            var names: Set<String> = []
            var abbreviations: Set<String> = []
            for book in books {
                let name = book.name(in: convention)
                guard names.insert(name.name.lowercased()).inserted else {
                    throw BookRegistryError.duplicateName(name.name, convention)
                }
                if let abbreviation = name.abbreviation {
                    guard abbreviations.insert(abbreviation.lowercased()).inserted else {
                        throw BookRegistryError.duplicateAbbreviation(abbreviation, convention)
                    }
                }
            }
        }

        let testaments = Dictionary(uniqueKeysWithValues: books.map { ($0.id, $0.testament) })
        var usedBooks: Set<BookID> = []
        _ = try Self.unique(file.canons.map(\.id), BookRegistryError.duplicateCanon)
        _ = try Self.unique(file.canons.flatMap { $0.orders.map(\.id) }, BookRegistryError.duplicateOrder)
        let canons = try file.canons.map { entry in
            guard let first = entry.orders.first else { throw BookRegistryError.canonWithoutOrder(entry.id) }
            let orders = try entry.orders.map { order in
                _ = try Self.unique(order.books) { BookRegistryError.repeatedBook($0, in: order.id) }
                for book in order.books where !bookIDs.contains(book) {
                    throw BookRegistryError.unknownBook(book, in: order.id)
                }
                guard Set(order.books) == Set(first.books) else {
                    throw BookRegistryError.ordersDisagree(canon: entry.id, order: order.id)
                }
                guard order.books.drop(while: { testaments[$0] == .old }).allSatisfy({ testaments[$0] == .new }) else {
                    throw BookRegistryError.testamentsMixed(order.id)
                }
                try checkSources(order.sources, in: order.id)
                usedBooks.formUnion(order.books)
                return Order(id: order.id, label: order.label, books: order.books, sources: order.sources)
            }
            let includes = entry.includes ?? [:]
            var included: Set<BookID> = []
            for (book, parts) in includes {
                guard first.books.contains(book) else { throw BookRegistryError.unknownBook(book, in: entry.id) }
                for part in parts {
                    guard bookIDs.contains(part) else { throw BookRegistryError.unknownBook(part, in: entry.id) }
                    guard !first.books.contains(part), included.insert(part).inserted else {
                        throw BookRegistryError.includedTwice(part, canon: entry.id)
                    }
                }
            }
            usedBooks.formUnion(included)
            if !includes.isEmpty, entry.includesSources?.isEmpty ?? true {
                throw BookRegistryError.unsourcedIncludes(entry.id)
            }
            try checkSources(entry.includesSources ?? [], in: entry.id)
            return Canon(
                id: entry.id, label: entry.label, description: entry.description, orders: orders, includes: includes,
                includesSources: entry.includesSources ?? [])
        }

        if let unused = books.first(where: { !usedBooks.contains($0.id) }) {
            throw BookRegistryError.bookInNoCanon(unused.id)
        }
        if let unused = file.sources.first(where: { !usedSources.contains($0.id) }) {
            throw BookRegistryError.unusedSource(unused.id)
        }

        self.conventions = file.conventions.map {
            Convention(id: $0.id, label: $0.label, example: $0.example, rule: $0.rule, sources: $0.sources)
        }
        self.books = books
        self.canons = canons
        self.sources = file.sources
        bookIndex = Dictionary(uniqueKeysWithValues: books.enumerated().map { ($1.id, $0) })
    }

    public func book(_ id: BookID) -> Book? {
        bookIndex[id].map { books[$0] }
    }

    public func canon(_ id: String) -> Canon? {
        canons.first { $0.id == id }
    }

    /// The canons that have this book, as a book of its own or inside another.
    public func canons(containing book: BookID) -> [Canon] {
        canons.filter { $0.contains(book) }
    }

    private let bookIndex: [BookID: Int]

    /// Returns the values as a set, throwing for the first one that repeats.
    private static func unique<T: Hashable>(_ values: [T], _ error: (T) -> BookRegistryError) throws -> Set<T> {
        var seen: Set<T> = []
        for value in values where !seen.insert(value).inserted { throw error(value) }
        return seen
    }

    // The file's shape, decoded before it is checked.

    private struct File: Decodable {
        let format: Int
        let conventions: [ConventionEntry]
        let books: [BookEntry]
        let canons: [CanonEntry]
        let sources: [Source]
    }

    private struct ConventionEntry: Decodable {
        let id: NamingConvention
        let label: String
        let example: String
        let rule: String
        let sources: [String]
    }

    private struct BookEntry: Decodable {
        let id: BookID
        let testament: Testament
        let name: String
        let abbreviation: String?
        let names: [NamingConvention: BookName]?
        let note: String?
    }

    private struct CanonEntry: Decodable {
        let id: String
        let label: String
        let description: String
        let includes: [BookID: [BookID]]?
        let includesSources: [String]?
        let orders: [OrderEntry]
    }

    private struct OrderEntry: Decodable {
        let id: String
        let label: String
        let sources: [String]
        let books: [BookID]
    }
}

/// A problem in the book registry. The catalog compiler refuses to build
/// while there is one.
public enum BookRegistryError: Error, Equatable, CustomStringConvertible {
    case unreadable(String)
    case unsupportedFormat(Int)
    case duplicateConvention(NamingConvention)
    case missingConvention(NamingConvention)
    case duplicateBook(BookID)
    case emptyName(BookID)
    case redundantName(BookID, NamingConvention)
    case duplicateName(String, NamingConvention)
    case duplicateAbbreviation(String, NamingConvention)
    case duplicateCanon(String)
    case duplicateOrder(String)
    case canonWithoutOrder(String)
    case unknownBook(BookID, in: String)
    case repeatedBook(BookID, in: String)
    case ordersDisagree(canon: String, order: String)
    case testamentsMixed(String)
    case includedTwice(BookID, canon: String)
    case unsourcedIncludes(String)
    case bookInNoCanon(BookID)
    case duplicateSource(String)
    case unknownSource(String, in: String)
    case unusedSource(String)

    public var description: String {
        switch self {
        case .unreadable(let detail): "the registry is not valid JSON of the expected shape: \(detail)"
        case .unsupportedFormat(let format): "format \(format) is not format \(BookRegistry.format)"
        case .duplicateConvention(let convention): "the convention \(convention.rawValue) is described twice"
        case .missingConvention(let convention): "the convention \(convention.rawValue) is not described"
        case .duplicateBook(let book): "\(book) is registered twice"
        case .emptyName(let book): "\(book) has an empty name or abbreviation"
        case .redundantName(let book, let convention):
            "\(book)'s \(convention.rawValue) name repeats its common name or is not another convention's"
        case .duplicateName(let name, let convention): "two books are called \"\(name)\" in \(convention.rawValue)"
        case .duplicateAbbreviation(let abbreviation, let convention):
            "two books are abbreviated \"\(abbreviation)\" in \(convention.rawValue)"
        case .duplicateCanon(let canon): "the canon \(canon) is described twice"
        case .duplicateOrder(let order): "the order \(order) is described twice"
        case .canonWithoutOrder(let canon): "the canon \(canon) has no order"
        case .unknownBook(let book, let place): "\(place) names \(book), which is not registered or not listed"
        case .repeatedBook(let book, let order): "the order \(order) lists \(book) twice"
        case .ordersDisagree(let canon, let order): "the order \(order) lists other books than the canon \(canon)"
        case .testamentsMixed(let order): "the order \(order) puts an Old Testament book after a New Testament one"
        case .includedTwice(let book, let canon): "the canon \(canon) has \(book) twice"
        case .unsourcedIncludes(let canon): "the canon \(canon)'s included material has no source"
        case .bookInNoCanon(let book): "\(book) belongs to no canon"
        case .duplicateSource(let source): "the source \(source) is described twice"
        case .unknownSource(let source, let place): "\(place) cites \(source), which is not described"
        case .unusedSource(let source): "the source \(source) is cited by nothing"
        }
    }
}
