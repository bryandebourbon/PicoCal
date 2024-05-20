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
      date: Date(),
      flags: (1...30).map { _ in Bool.random() },
      eventDays: (1...30).map { _ in (morning: Bool.random(), afternoon: Bool.random(), evening: Bool.random()) }
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
    let eventKitFetcher = EventKitFetcher.shared

    eventKitFetcher.initializeEventStore { granted, busyDays, error in
      let entry: SimpleEntry
      if granted, let busyDays = busyDays {
        entry = SimpleEntry(date: Date(), flags: flags, eventDays: busyDays)
      } else {
        entry = SimpleEntry(
          date: Date(),
          flags: flags,
          eventDays: (1...30).map { _ in (morning: false, afternoon: false, evening: false) }
        )
      }
      completion(entry)
    }
  }
}

struct SimpleEntry: TimelineEntry {
  var date: Date
  let flags: [Bool]
  let eventDays: [(morning: Bool, afternoon: Bool, evening: Bool)]
}

struct WidgetExtensionEntryView: View {
  var entry: Provider.Entry

  var body: some View {
    CalendarView(
      calorieDays: .constant(entry.flags),
      eventDays: .constant(entry.eventDays)
    )
    .frame(width: 180, height: 60)
    .offset(x: -5, y: -10)
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
