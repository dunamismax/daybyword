// The rights audit (BUILD.md P18.1, D16): docs/rights-audit.md, generated
// from catalog/SOURCES.md and the plan files, says for every plan the catalog
// serves and every data source it uses whether its source is `cleared`, on
// what basis, with what credit, and where. Version 1.0 serves the US App
// Store and the website, which reaches everyone, so every served plan and
// every source whose data ships must be cleared everywhere (D16).
//
//   swift scripts/rights-audit.swift generate   rewrite docs/rights-audit.md
//   swift scripts/rights-audit.swift check      fail if it is stale, or if anything
//                                               served is not cleared everywhere
import Foundation

let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data("rights-audit: \(message)\n".utf8))
    exit(1)
}

func read(_ path: String) -> String {
    guard let text = try? String(contentsOf: root.appendingPathComponent(path), encoding: .utf8) else {
        fail("cannot read \(path)")
    }
    return text
}

// MARK: - The sources

struct Source {
    let id: String
    let title: String
    var fields: [String: String] = [:]

    /// The first word in backticks on the Status line, as the compiler reads it.
    var status: String {
        fields["Status"]?.firstMatch(of: #/`([a-z]+)`/#).map { String($0.1) } ?? ""
    }
    /// The status line after its first word: what the status covers.
    var statusNote: String {
        let line = fields["Status"] ?? ""
        guard let range = line.firstMatch(of: #/`[a-z]+`/#)?.range else { return "" }
        return line[range.upperBound...].trimmingCharacters(in: CharacterSet(charactersIn: " .,;"))
    }
}

func sources() -> [Source] {
    var all: [Source] = []
    var field: String?
    for line in read("catalog/SOURCES.md").split(separator: "\n", omittingEmptySubsequences: false) {
        let line = String(line)
        if let heading = line.wholeMatch(of: #/## ([a-z0-9-]+): (.+)/#) {
            all.append(Source(id: String(heading.1), title: String(heading.2)))
            field = nil
        } else if let start = line.wholeMatch(of: #/- \*\*([A-Za-z ]+):\*\* ?(.*)/#), !all.isEmpty {
            let name = String(start.1)
            all[all.count - 1].fields[name] = String(start.2)
            field = name
        } else if let field, line.hasPrefix("  "), !all.isEmpty {
            all[all.count - 1].fields[field, default: ""] += " " + line.trimmingCharacters(in: .whitespaces)
        } else if line.hasPrefix("##") || line == "---" {
            field = nil
        }
    }
    return all
}

// MARK: - The plans

struct Plan {
    let id: String
    let title: String
    let rights: String
    let review: String
}

func plans() -> [Plan] {
    let folder = root.appendingPathComponent("catalog/plans")
    let files = ((try? FileManager.default.contentsOfDirectory(atPath: folder.path)) ?? [])
        .filter { $0.hasSuffix(".plan") }.sorted()
    return files.map { file in
        var front: [String: String] = [:]
        for line in read("catalog/plans/\(file)").split(separator: "\n") {
            if line.hasPrefix("---") { break }
            if let field = String(line).wholeMatch(of: #/([a-z-]+): (.*)/#) {
                front[String(field.1)] = String(field.2)
            }
        }
        guard let id = front["id"], let title = front["title"], let rights = front["rights"] else {
            fail("catalog/plans/\(file) has no id, title or rights")
        }
        return Plan(id: id, title: title, rights: rights, review: front["review"] ?? "")
    }
}

// MARK: - The audit

/// A source's territories cover the US storefront and the web's readers.
func everywhere(_ source: Source) -> Bool {
    (source.fields["Territories"] ?? "").lowercased().hasPrefix("everywhere")
}

/// What does not hold, if anything.
func problems(_ plans: [Plan], _ sources: [Source]) -> [String] {
    let byID = Dictionary(uniqueKeysWithValues: sources.map { ($0.id, $0) })
    var found: [String] = []
    for plan in plans {
        guard let source = byID[plan.rights] else {
            found.append("\(plan.id) names \(plan.rights), which catalog/SOURCES.md does not have")
            continue
        }
        if source.status != "cleared" { found.append("\(plan.id)'s source \(source.id) is \(source.status)") }
        if !everywhere(source) { found.append("\(plan.id)'s source \(source.id) is not cleared everywhere") }
    }
    for source in sources where source.status == "cleared" && !everywhere(source) {
        found.append("\(source.id) is cleared, but not everywhere: version 1.0's readers are everywhere")
    }
    return found
}

func cell(_ text: String) -> String {
    text.replacingOccurrences(of: "|", with: "\\|").trimmingCharacters(in: .whitespaces)
}

func audit(_ plans: [Plan], _ sources: [Source]) -> String {
    let byID = Dictionary(uniqueKeysWithValues: sources.map { ($0.id, $0) })
    var out = """
        # Rights audit

        *Generated from `catalog/SOURCES.md` and `catalog/plans/` by
        `scripts/rights-audit.swift` (BUILD.md P18.1). Do not edit: change the
        sources or the plans and run `make rights-audit`. `make check` fails if
        this file is stale, or if anything served is not cleared everywhere.*

        Version 1.0 serves the US App Store (D16) and daybyword.com, which
        reaches readers everywhere, so every plan it serves and every source
        whose data ships must be `cleared` everywhere. The catalog compiler
        also refuses, in release mode, any plan whose source is not cleared
        (P4.3).

        ## The plans served

        | Plan | Review | Source | Status | Territories |
        |---|---|---|---|---|

        """
    for plan in plans {
        let source = byID[plan.rights]
        out += "| \(cell(plan.title)) (`\(plan.id)`) | \(plan.review) | `\(plan.rights)` | "
        out += "\(source?.status ?? "missing") | \(cell(source?.fields["Territories"] ?? "")) |\n"
    }
    out += """

        ## The sources

        | Source | Status | Used for | Basis | Credit | Territories |
        |---|---|---|---|---|---|

        """
    for source in sources {
        let status = source.statusNote.isEmpty ? source.status : "\(source.status): \(source.statusNote)"
        out += "| \(cell(source.title)) (`\(source.id)`) | \(cell(status)) | "
        out += "\(cell(source.fields["Used for"] ?? "")) | \(cell(source.fields["Basis"] ?? "")) | "
        out += "\(cell(source.fields["Attribution"] ?? "")) | \(cell(source.fields["Territories"] ?? "")) |\n"
    }
    let found = problems(plans, sources)
    out += "\n## Verdict\n\n"
    out +=
        found.isEmpty
        ? "Every plan served (\(plans.count)) and every cleared source is cleared everywhere: version 1.0 may serve them in the US App Store and on the web. Other storefronts (P18.8) need no further review for these sources, which hold everywhere; new plans need their own entries.\n"
        : found.map { "- \($0)\n" }.joined()
    return out
}

// MARK: - Commands

let allPlans = plans()
let allSources = sources()
let output = audit(allPlans, allSources)
let path = "docs/rights-audit.md"
switch CommandLine.arguments.dropFirst().first {
case "generate":
    try! output.write(to: root.appendingPathComponent(path), atomically: true, encoding: .utf8)
    print("rights-audit: wrote \(path)")
case "check":
    var found = problems(allPlans, allSources)
    if (try? String(contentsOf: root.appendingPathComponent(path), encoding: .utf8)) != output {
        found.append("\(path) is out of date; run make rights-audit")
    }
    if !found.isEmpty { fail(found.joined(separator: "\nrights-audit: ")) }
    print("rights-audit: \(allPlans.count) plans and \(allSources.count) sources, every served one cleared everywhere")
default:
    fail("usage: swift scripts/rights-audit.swift generate|check")
}
