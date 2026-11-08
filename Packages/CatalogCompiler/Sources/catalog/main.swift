import CatalogCompiler
import Foundation

let usage = """
    usage: catalog build [--source DIR] [--output PATH] [--release]
           catalog export [--source DIR] [--catalog PATH] [--output PATH]

    build compiles the reading-plan catalog into a SQLite database.
    export writes a compiled catalog as the JSON document the server's
    PostgreSQL import reads (docs/catalog-format.md, "The export").

      --source DIR    the catalog's sources (default: catalog)
      --output PATH   where to write (default: build/catalog/Catalog.sqlite, or
                      build/catalog/catalog-export.json for export)
      --release       build for release: leave out plans not yet reviewed, and
                      refuse a plan whose source is not cleared
      --catalog PATH  the compiled catalog to export
                      (default: build/catalog/Catalog-release.sqlite)
    """

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data("catalog: \(message)\n\(usage)\n".utf8))
    exit(2)
}

var arguments = Array(CommandLine.arguments.dropFirst())
guard let command = arguments.first else { fail("missing command") }
arguments.removeFirst()

switch command {
case "build":
    var source = "catalog"
    var output = "build/catalog/Catalog.sqlite"
    var mode = CatalogBuild.Mode.development
    while let argument = arguments.first {
        arguments.removeFirst()
        switch argument {
        case "--source":
            guard let path = arguments.first else { fail("--source needs a directory") }
            arguments.removeFirst()
            source = path
        case "--output":
            guard let path = arguments.first else { fail("--output needs a path") }
            arguments.removeFirst()
            output = path
        case "--release":
            mode = .release
        default:
            fail("unknown option \(argument)")
        }
    }
    let url = URL(fileURLWithPath: output)
    do {
        let leftOut = try CatalogBuild.write(from: URL(fileURLWithPath: source, isDirectory: true), to: url, mode: mode)
        print("catalog: wrote \(url.path) (\(mode.rawValue), schema \(CatalogBuild.schemaVersion))")
        if !leftOut.isEmpty {
            print(
                "catalog: left out, not yet \(CatalogBuild.releaseReview.rawValue): \(leftOut.map(\.rawValue).joined(separator: ", "))"
            )
        }
    } catch {
        FileHandle.standardError.write(Data("catalog: \(error)\n".utf8))
        exit(1)
    }
case "export":
    var source = "catalog"
    var catalog = "build/catalog/Catalog-release.sqlite"
    var output = "build/catalog/catalog-export.json"
    while let argument = arguments.first {
        arguments.removeFirst()
        guard ["--source", "--catalog", "--output"].contains(argument) else { fail("unknown option \(argument)") }
        guard let value = arguments.first else { fail("\(argument) needs a path") }
        arguments.removeFirst()
        switch argument {
        case "--source": source = value
        case "--catalog": catalog = value
        default: output = value
        }
    }
    do {
        let sources = try CatalogBuild.readSources(from: URL(fileURLWithPath: source, isDirectory: true))
        let url = URL(fileURLWithPath: output)
        try CatalogExport.write(catalog: URL(fileURLWithPath: catalog), sources: sources, to: url)
        print("catalog: exported \(catalog) to \(url.path) (format \(CatalogExport.formatVersion))")
    } catch {
        FileHandle.standardError.write(Data("catalog: \(error)\n".utf8))
        exit(1)
    }
case "--help", "-h", "help":
    print(usage)
default:
    fail("unknown command \(command)")
}
