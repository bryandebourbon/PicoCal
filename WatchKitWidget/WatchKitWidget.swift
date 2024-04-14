import EventKit
import SwiftUI
import WidgetKit

@main
struct WidgetExtensionBundle: WidgetBundle {
  @WidgetBundleBuilder
  var body: some Widget {
    WidgetExtension()
  }
}

struct Provider: TimelineProvider {
  func placeholder(in context: Context) -> SimpleEntry {
    SimpleEntry(
      date: Date(), flags: (1...30).map { _ in Bool.random() }
    )
  }

  func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
    fetchSharedData { entry in completion(entry) }
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
    fetchSharedData { entry in

      let nextUpdateDate = Calendar.current.date(byAdding: .minute, value: 10, to: entry.date)!

      let timeline = Timeline(
        entries: [entry],
        policy: .after(nextUpdateDate)
      )
      
      completion(timeline)
    }
  }

  func fetchSharedData(completion: @escaping (SimpleEntry) -> Void) {
    let flags = Store.shared.retrieve(forKey: "sharedFlags")
    let entry = SimpleEntry(date: Date(), flags: flags)
    completion(entry)
  }

}

struct SimpleEntry: TimelineEntry {
  var date: Date
  let flags: [Bool]
}

struct WidgetExtensionEntryView: View {
  var entry: Provider.Entry

  var body: some View {
    CalendarDateTitle().offset(y: -10)
    CalendarView(
      calorieDays: .constant(entry.flags)
    )
    .offset(x: -5, y: -15)
    .containerBackground(for: .widget) {
      Color.black
    }
  }
}

struct WidgetExtension: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "WidgetExtension", provider: Provider()) { entry in
      WidgetExtensionEntryView(entry: entry)
    }
    .configurationDisplayName("PicoCal")
    .description("A Calendar for tiny spaces.")
  }
}
