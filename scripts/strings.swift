// Keeps the app's String Catalogs in step with the code (docs/decisions.md
// E15, E25; BUILD.md P2.10, P12.4): apple/Shared/Localizable.xcstrings for the
// interface, and apple/App/AppShortcuts.xcstrings for the phrases Siri hears. The keys come
// from the .stringsdata files Xcode writes when it builds the app and the
// widget (SWIFT_EMIT_LOC_STRINGS), so build first (make build or make test-app).
//
//   swift scripts/strings.swift sync    add new keys to the catalog and drop stale ones
//   swift scripts/strings.swift check   fail on a key missing from the catalog, a stale
//                                       key, or interface text that skips localization
import Foundation

let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
/// Each table the code may use, and its catalog.
let catalogs = [
    "Localizable": root.appendingPathComponent("apple/Shared/Localizable.xcstrings"),
    "AppShortcuts": root.appendingPathComponent("apple/App/AppShortcuts.xcstrings"),
]
let buildDirectory = root.appendingPathComponent(
    "build/DerivedData/Build/Intermediates.noindex/DayByWord.build/Debug-iphonesimulator")
/// The targets whose strings readers see. Tests are not among them.
let targets = ["App", "Widgets"]
/// Debug-only files whose text is invented sample content.
let sampleFiles: Set = ["ComponentGallery.swift"]

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data("strings: \(message)\n".utf8))
    exit(1)
}

/// Every key the code uses, by table, from the build's .stringsdata files,
/// skipping files whose source no longer exists (a deleted file's data stays
/// behind in DerivedData).
/// Each App Shortcut's phrases, by its key, as the code gives them.
var phrases: [String: [String]] = [:]

func keysInCode() -> [String: Set<String>] {
    var keys: [String: Set<String>] = [:]
    var found = false
    for target in targets {
        let directory = buildDirectory.appendingPathComponent("\(target).build")
        guard let files = FileManager.default.enumerator(at: directory, includingPropertiesForKeys: nil) else {
            continue
        }
        for case let file as URL in files where file.pathExtension == "stringsdata" {
            guard let data = try? Data(contentsOf: file),
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let source = json["source"] as? String,
                source.hasPrefix(root.path + "/apple/"),
                FileManager.default.fileExists(atPath: source)
            else { continue }
            found = true
            let tables = json["tables"] as? [String: [[String: Any]]] ?? [:]
            for (table, entries) in tables {
                guard catalogs[table] != nil else { fail("\(source) uses the table \(table); use Localizable") }
                keys[table, default: []].formUnion(entries.compactMap { $0["key"] as? String })
                // An App Shortcut's key is its first phrase; the catalog keeps all of them.
                for entry in entries {
                    if let key = entry["key"] as? String, let values = entry["values"] as? [String] {
                        phrases[key] = values
                    }
                }
            }
        }
    }
    if !found { fail("no .stringsdata in \(buildDirectory.path); run make build first") }
    return keys
}

func readCatalog(_ catalogURL: URL) -> [String: Any] {
    guard let data = try? Data(contentsOf: catalogURL),
        let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    else { return ["sourceLanguage": "en", "strings": [String: Any](), "version": "1.0"] }
    return json
}

func writeCatalog(_ catalog: [String: Any], to catalogURL: URL) {
    do {
        var data = try JSONSerialization.data(
            withJSONObject: catalog, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
        data.append(Data("\n".utf8))
        try data.write(to: catalogURL)
    } catch {
        fail("could not write \(catalogURL.path): \(error)")
    }
}

/// Words handed to SwiftUI without localization: a `Text(verbatim:)` string
/// literal with letters outside its interpolations, outside the debug
/// gallery's sample content. Punctuation ("·") and data ("\(label), \(spoken)")
/// are fine.
func unlocalizedText() -> [String] {
    var problems: [String] = []
    let pattern = try! Regex(#"Text\(verbatim:\s*"((?:[^"\\]|\\.)*)""#)
    for directory in ["apple/App", "apple/Widgets", "apple/Shared"] {
        guard let files = FileManager.default.enumerator(at: root.appendingPathComponent(directory), includingPropertiesForKeys: nil) else { continue }
        for case let file as URL in files where file.pathExtension == "swift" && !sampleFiles.contains(file.lastPathComponent) {
            let lines = (try? String(contentsOf: file, encoding: .utf8))?.components(separatedBy: "\n") ?? []
            for (number, line) in lines.enumerated() {
                for match in line.matches(of: pattern) {
                    let literal = String(match.output[1].substring ?? "")
                        .replacingOccurrences(of: #"\\\([^)]*\)"#, with: "", options: .regularExpression)
                    if literal.contains(where: \.isLetter) {
                        problems.append("\(directory)/\(file.lastPathComponent):\(number + 1): words in Text(verbatim:)")
                    }
                }
            }
        }
    }
    return problems
}

/// An App Shortcut's English phrases as the catalog keeps them.
func phraseEntry(_ values: [String]) -> [String: Any] {
    ["localizations": ["en": ["stringSet": ["state": "translated", "values": values]]]]
}

let mode = CommandLine.arguments.dropFirst().first ?? ""
guard mode == "sync" || mode == "check" else { fail("usage: swift scripts/strings.swift sync|check") }
let code = keysInCode()
var problems: [String] = []
var total = 0
for (table, catalogURL) in catalogs.sorted(by: { $0.key < $1.key }) {
    let keys = code[table] ?? []
    var catalog = readCatalog(catalogURL)
    let strings = catalog["strings"] as? [String: Any] ?? [:]
    let missing = keys.subtracting(strings.keys).sorted()
    let stale = Set(strings.keys).subtracting(keys).sorted()
    total += keys.count
    switch mode {
    case "sync":
        var updated = strings.filter { keys.contains($0.key) }
        for key in missing { updated[key] = [String: Any]() }
        for (key, values) in phrases where keys.contains(key) { updated[key] = phraseEntry(values) }
        catalog["strings"] = updated
        writeCatalog(catalog, to: catalogURL)
        print("strings: \(table): \(updated.count) keys; added \(missing.count), removed \(stale.count)")
    default:
        problems += missing.map { "\(table): missing from the catalog: \($0)" }
        problems += stale.map { "\(table): stale in the catalog: \($0)" }
        for (key, values) in phrases where keys.contains(key) {
            if let entry = strings[key], !NSDictionary(dictionary: phraseEntry(values)).isEqual(entry) {
                problems.append("\(table): the phrases for \"\(key)\" differ from the code")
            }
        }
        if catalog["sourceLanguage"] as? String != "en" { problems.append("\(table): the source language is not en") }
    }
}
if mode == "check" {
    problems += unlocalizedText()
    if !problems.isEmpty {
        fail(problems.joined(separator: "\n") + "\nrun make strings to update the catalogs")
    }
    print("strings: \(total) keys, all in the catalogs")
}
