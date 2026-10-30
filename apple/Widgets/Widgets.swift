import SwiftUI
import WidgetKit

/// The app's widgets. A placeholder until the next-reading widget is built
/// (BUILD.md P8.9).
@main
struct DayByWordWidgets: WidgetBundle {
    var body: some Widget {
        NextReadingWidget()
    }
}

struct NextReadingWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "NextReading", provider: NextReadingProvider()) { _ in
            NextReadingView()
                .containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("Next reading")
        .description("Shows the next reading in your plan.")
        .supportedFamilies([.systemSmall, .accessoryRectangular])
    }
}

struct NextReadingEntry: TimelineEntry {
    let date: Date
}

struct NextReadingProvider: TimelineProvider {
    func placeholder(in context: Context) -> NextReadingEntry {
        NextReadingEntry(date: .now)
    }

    func getSnapshot(in context: Context, completion: @escaping (NextReadingEntry) -> Void) {
        completion(NextReadingEntry(date: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NextReadingEntry>) -> Void) {
        completion(Timeline(entries: [NextReadingEntry(date: .now)], policy: .never))
    }
}

struct NextReadingView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Day by Word")
                .font(.headline)
            Text("Your next reading will appear here.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
