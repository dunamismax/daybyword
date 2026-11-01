// Generates the design's outputs from design/tokens.json (docs/decisions.md E12,
// BUILD.md P2.4), so the app and the web cannot drift:
//
//   apple/Shared/Colors.xcassets   one color set per token, light and dark
//   apple/Shared/DesignTokens.swift  Palette, Radius, Spacing, and TypeScale
//   Server/Public/assets/tokens.css  the same values as CSS custom properties
//
//   swift scripts/tokens.swift generate   rewrite the outputs
//   swift scripts/tokens.swift check      fail if an output is stale, or if a text
//                                         pair in docs/design.md is below WCAG AA
import Foundation

let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data("tokens: \(message)\n".utf8))
    exit(1)
}

// MARK: - Reading the tokens

struct Tokens {
    struct ColorToken {
        let name: String
        let light: String
        let dark: String
        let use: String
    }
    struct TypeToken {
        let name: String
        let size: Int
        let weight: String
        let relativeTo: String
        let desktopSize: Int?
        let use: String
    }
    var colors: [ColorToken] = []
    var radius: [(String, Int)] = []
    var space: [(String, Int)] = []
    var type: [TypeToken] = []
}

func readTokens() -> Tokens {
    let url = root.appendingPathComponent("design/tokens.json")
    guard let data = try? Data(contentsOf: url),
        let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    else { fail("cannot read design/tokens.json") }

    var tokens = Tokens()
    let hex = #/^#[0-9A-F]{6}$/#
    for (name, value) in (json["color"] as? [String: [String: String]] ?? [:]).sorted(by: { $0.key < $1.key }) {
        guard let light = value["light"], let dark = value["dark"],
            light.wholeMatch(of: hex) != nil, dark.wholeMatch(of: hex) != nil
        else { fail("color \(name) needs light and dark values as #RRGGBB in capitals") }
        tokens.colors.append(.init(name: name, light: light, dark: dark, use: value["use"] ?? ""))
    }
    tokens.radius = (json["radius"] as? [String: Int] ?? [:]).sorted { $0.value < $1.value || ($0.value == $1.value && $0.key < $1.key) }
    tokens.space = (json["space"] as? [String: Int] ?? [:]).sorted { $0.value < $1.value }
    for (name, value) in (json["type"] as? [String: Any] ?? [:]).sorted(by: { $0.key < $1.key }) {
        guard let style = value as? [String: Any] else { continue }  // the "comment" entry
        guard let size = style["size"] as? Int, let weight = style["weight"] as? String,
            let relativeTo = style["relativeTo"] as? String
        else { fail("type \(name) needs size, weight, and relativeTo") }
        tokens.type.append(
            .init(name: name, size: size, weight: weight, relativeTo: relativeTo,
                desktopSize: style["desktopSize"] as? Int, use: style["use"] as? String ?? ""))
    }
    if tokens.colors.isEmpty { fail("design/tokens.json has no colors") }
    return tokens
}

// MARK: - Contrast

func luminance(_ hex: String) -> Double {
    let value = Int(hex.dropFirst(), radix: 16)!
    func channel(_ shift: Int) -> Double {
        let c = Double((value >> shift) & 0xFF) / 255
        return c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
    }
    return 0.2126 * channel(16) + 0.7152 * channel(8) + 0.0722 * channel(0)
}

func contrast(_ a: String, _ b: String) -> Double {
    let (x, y) = (luminance(a), luminance(b))
    return (max(x, y) + 0.05) / (min(x, y) + 0.05)
}

// MARK: - Outputs

func kebab(_ name: String) -> String {
    name.replacing(#/[A-Z]/#) { "-" + $0.output.lowercased() }
}

func capitalized(_ name: String) -> String {
    name.prefix(1).uppercased() + name.dropFirst()
}

let header = "Generated from design/tokens.json by scripts/tokens.swift. Do not edit."

func colorSet(_ token: Tokens.ColorToken) -> String {
    func components(_ hex: String) -> String {
        let s = Array(hex.dropFirst())
        return """
            "color-space" : "srgb", "components" : { "alpha" : "1.000", "red" : "0x\(String(s[0...1]))", "green" : "0x\(String(s[2...3]))", "blue" : "0x\(String(s[4...5]))" }
            """
    }
    return """
        {
          "colors" : [
            { "color" : { \(components(token.light)) }, "idiom" : "universal" },
            { "appearances" : [ { "appearance" : "luminosity", "value" : "dark" } ], "color" : { \(components(token.dark)) }, "idiom" : "universal" }
          ],
          "info" : { "author" : "xcode", "version" : 1 }
        }

        """
}

func swiftSource(_ tokens: Tokens) -> String {
    var lines = ["// \(header)", "", "import SwiftUI", ""]
    lines.append("/// The design's colors (docs/design.md). Each follows light and dark mode.")
    lines.append("enum Palette {")
    for token in tokens.colors {
        lines.append("    /// \(capitalized(token.use)).")
        lines.append("    static let \(token.name) = Color(\"\(capitalized(token.name))\")")
    }
    lines.append("}")
    lines.append("")
    lines.append("/// Corner radii, in points.")
    lines.append("enum Radius {")
    for (name, value) in tokens.radius { lines.append("    static let \(name): CGFloat = \(value)") }
    lines.append("}")
    lines.append("")
    lines.append("/// Spacing steps, in points.")
    lines.append("enum Spacing {")
    for (name, value) in tokens.space { lines.append("    static let \(name): CGFloat = \(value)") }
    lines.append("}")
    if !tokens.type.isEmpty {
        lines.append("")
        lines.append("/// The type scale (docs/design.md). Sizes are at the default text size and")
        lines.append("/// scale with Dynamic Type relative to their text style (Typography.swift).")
        lines.append("enum TypeScale {")
        for style in tokens.type {
            lines.append("    /// \(capitalized(style.use)).")
            lines.append(
                "    static let \(style.name) = TypeStyle(size: \(style.size), weight: .\(style.weight), relativeTo: .\(style.relativeTo))"
            )
        }
        lines.append("}")
    }
    return lines.joined(separator: "\n") + "\n"
}

func css(_ tokens: Tokens) -> String {
    func colors(_ pick: (Tokens.ColorToken) -> String, indent: String) -> String {
        tokens.colors.map { "\(indent)--color-\(kebab($0.name)): \(pick($0));" }.joined(separator: "\n")
    }
    func rem(_ px: Int) -> String {
        let value = Double(px) / 16
        return value == value.rounded() ? "\(Int(value))rem" : "\(value)rem"
    }
    var out = "/* \(header) */\n\n:root {\n  color-scheme: light dark;\n"
    out += colors({ $0.light }, indent: "  ") + "\n"
    for (name, value) in tokens.radius { out += "  --radius-\(kebab(name)): \(value)px;\n" }
    for (name, value) in tokens.space { out += "  --space-\(kebab(name)): \(value)px;\n" }
    let weights = ["regular": 400, "medium": 500, "semibold": 600, "bold": 700, "heavy": 800]
    for style in tokens.type {
        out += "  --font-size-\(kebab(style.name)): \(rem(style.size));\n"
        if let desktop = style.desktopSize { out += "  --font-size-\(kebab(style.name))-desktop: \(rem(desktop));\n" }
        out += "  --font-weight-\(kebab(style.name)): \(weights[style.weight] ?? 400);\n"
    }
    out += "}\n\n"
    out += "@media (prefers-color-scheme: dark) {\n  :root:not([data-theme=\"light\"]) {\n"
    out += colors({ $0.dark }, indent: "    ") + "\n  }\n}\n\n"
    out += ":root[data-theme=\"light\"] {\n  color-scheme: light;\n}\n\n"
    out += ":root[data-theme=\"dark\"] {\n  color-scheme: dark;\n" + colors({ $0.dark }, indent: "  ") + "\n}\n"
    return out
}

/// Every output file, by its path under the repository.
func outputs(_ tokens: Tokens) -> [String: String] {
    var files: [String: String] = [:]
    let catalog = "apple/Shared/Colors.xcassets"
    files["\(catalog)/Contents.json"] = "{\n  \"info\" : { \"author\" : \"xcode\", \"version\" : 1 }\n}\n"
    for token in tokens.colors {
        files["\(catalog)/\(capitalized(token.name)).colorset/Contents.json"] = colorSet(token)
    }
    if let accent = tokens.colors.first(where: { $0.name == "accent" }) {
        files["\(catalog)/AccentColor.colorset/Contents.json"] = colorSet(accent)
    }
    files["apple/Shared/DesignTokens.swift"] = swiftSource(tokens)
    files["Server/Public/assets/tokens.css"] = css(tokens)
    return files
}

// MARK: - Commands

func checkTextPairs(_ tokens: Tokens) -> [String] {
    guard let design = try? String(contentsOf: root.appendingPathComponent("docs/design.md"), encoding: .utf8) else {
        return ["cannot read docs/design.md"]
    }
    let byName = Dictionary(uniqueKeysWithValues: tokens.colors.map { ($0.name, $0) })
    let row = #/^\| `(\w+)` \| `(\w+)` \| ([\d.]+) \| ([\d.]+) \|$/#
    var problems: [String] = []
    var pairs = 0
    for line in design.split(separator: "\n") {
        guard let match = String(line).wholeMatch(of: row) else { continue }
        let (text, ground) = (String(match.1), String(match.2))
        guard let fg = byName[text], let bg = byName[ground] else {
            problems.append("docs/design.md pairs unknown tokens \(text) on \(ground)")
            continue
        }
        pairs += 1
        for (appearance, a, b, written) in [("light", fg.light, bg.light, match.3), ("dark", fg.dark, bg.dark, match.4)] {
            let ratio = contrast(a, b)
            if ratio < 4.5 {
                problems.append("\(text) on \(ground) is \(String(format: "%.2f", ratio)):1 in \(appearance); WCAG AA needs 4.5")
            }
            if String(format: "%.1f", ratio) != written {
                problems.append(
                    "docs/design.md says \(text) on \(ground) is \(written) in \(appearance), but it is \(String(format: "%.1f", ratio))"
                )
            }
        }
    }
    if pairs == 0 { problems.append("docs/design.md lists no text pairs") }
    return problems
}

let tokens = readTokens()
switch CommandLine.arguments.dropFirst().first {
case "generate":
    let catalog = root.appendingPathComponent("apple/Shared/Colors.xcassets")
    try? FileManager.default.removeItem(at: catalog)
    for (path, contents) in outputs(tokens) {
        let url = root.appendingPathComponent(path)
        try! FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try! contents.write(to: url, atomically: true, encoding: .utf8)
    }
    print("tokens: wrote \(outputs(tokens).count) files")
case "check":
    var problems = checkTextPairs(tokens)
    let expected = outputs(tokens)
    for (path, contents) in expected.sorted(by: { $0.key < $1.key }) {
        let current = try? String(contentsOf: root.appendingPathComponent(path), encoding: .utf8)
        if current != contents { problems.append("\(path) is out of date; run make tokens") }
    }
    let catalog = root.appendingPathComponent("apple/Shared/Colors.xcassets")
    let sets = (try? FileManager.default.contentsOfDirectory(atPath: catalog.path)) ?? []
    for set in sets where set.hasSuffix(".colorset") && expected["apple/Shared/Colors.xcassets/\(set)/Contents.json"] == nil {
        problems.append("apple/Shared/Colors.xcassets/\(set) is not in design/tokens.json; run make tokens")
    }
    if !problems.isEmpty { fail(problems.joined(separator: "\ntokens: ")) }
    print("tokens: outputs current; \(tokens.colors.count) colors, every text pair meets WCAG AA")
default:
    fail("usage: swift scripts/tokens.swift generate|check")
}
