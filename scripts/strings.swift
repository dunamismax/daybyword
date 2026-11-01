// Keeps the app's String Catalog, apple/Shared/Localizable.xcstrings, in step
// with the code (docs/decisions.md E15, E25; BUILD.md P2.10). The keys come
// from the .stringsdata files Xcode writes when it builds the app and the
// widget (SWIFT_EMIT_LOC_STRINGS), so build first (make build or make test-app).
//
//   swift scripts/strings.swift sync    add new keys to the catalog and drop stale ones
//   swift scripts/strings.swift check   fail on a key missing from the catalog, a stale
//                                       key, or interface text that skips localization
import Foundation

let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
let catalogURL = root.appendingPathComponent("apple/Shared/Localizable.xcstrings")
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

/// Every key the code uses, from the build's .stringsdata files, skipping
/// files whose source no longer exists (a deleted file's data stays behind
/// in DerivedData).
func keysInCode() -> Set<String> {
    var keys: Set<String> = []
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
                guard table == "Localizable" else { fail("\(source) uses the table \(table); use Localizable") }
                keys.formUnion(entries.compactMap { $0["key"] as? String })
            }
        }
    }
    if !found { fail("no .stringsdata in \(buildDirectory.path); run make build first") }
    return keys
}

func readCatalog() -> [String: Any] {
    guard let data = try? Data(contentsOf: catalogURL),
        let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    else { return ["sourceLanguage": "en", "strings": [String: Any](), "version": "1.0"] }
    return json
}

func writeCatalog(_ catalog: [String: Any]) {
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

let mode = CommandLine.arguments.dropFirst().first ?? ""
let code = keysInCode()
var catalog = readCatalog()
let strings = catalog["strings"] as? [String: Any] ?? [:]
let missing = code.subtracting(strings.keys).sorted()
let stale = Set(strings.keys).subtracting(code).sorted()

switch mode {
case "sync":
    var updated = strings.filter { code.contains($0.key) }
    for key in missing { updated[key] = [String: Any]() }
    catalog["strings"] = updated
    writeCatalog(catalog)
    print("strings: \(updated.count) keys; added \(missing.count), removed \(stale.count)")
case "check":
    var problems = missing.map { "missing from the catalog: \($0)" } + stale.map { "stale in the catalog: \($0)" }
    problems += unlocalizedText()
    if catalog["sourceLanguage"] as? String != "en" { problems.append("the catalog's source language is not en") }
    if !problems.isEmpty {
        fail(problems.joined(separator: "\n") + "\nrun make strings to update the catalog")
    }
    print("strings: \(code.count) keys, all in the catalog")
default:
    fail("usage: swift scripts/strings.swift sync|check")
}
