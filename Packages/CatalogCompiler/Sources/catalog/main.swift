import CatalogCompiler
import Foundation

let usage = """
    usage: catalog build [--source DIR] [--output PATH] [--release]

    Compiles the reading-plan catalog into a SQLite database.

      --source DIR   the catalog's sources (default: catalog)
      --output PATH  where to write the catalog (default: build/catalog/Catalog.sqlite)
      --release      build for release: uncleared sources are errors, not warnings
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
        try CatalogBuild.write(from: URL(fileURLWithPath: source, isDirectory: true), to: url, mode: mode)
        print("catalog: wrote \(url.path) (\(mode.rawValue), schema \(CatalogBuild.schemaVersion))")
    } catch {
        FileHandle.standardError.write(Data("catalog: \(error)\n".utf8))
        exit(1)
    }
case "--help", "-h", "help":
    print(usage)
default:
    fail("unknown command \(command)")
}
