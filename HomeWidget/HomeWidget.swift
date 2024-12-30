import SwiftUI
import WidgetKit
import EventKit

// MARK: - 1) Widget Bundle
@main
struct iOSWidgetExtensionBundle: WidgetBundle {
  var body: some Widget {
    iOSWidgetExtension()
  }
}

// MARK: - 2) Timeline Entry
struct iOSWidgetEntry: TimelineEntry {
  let date: Date
  let flags: [Bool]
  let eventDays: [(morning: Bool, afternoon: Bool, evening: Bool)]
}

// MARK: - 3) Timeline Provider
struct iOSWidgetProvider: TimelineProvider {
  func placeholder(in context: Context) -> iOSWidgetEntry {
    iOSWidgetEntry(
      date: Date(),
      flags: (1...30).map { _ in Bool.random() },
      eventDays: (1...30).map { _ in
        (morning: Bool.random(), afternoon: Bool.random(), evening: Bool.random())
      }
    )
  }

  func getSnapshot(in context: Context, completion: @escaping (iOSWidgetEntry) -> Void) {
    fetchDataForWidget { entry in
      completion(entry)
    }
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<iOSWidgetEntry>) -> Void) {
    fetchDataForWidget { entry in
      let nextUpdate = Calendar.current.date(byAdding: .minute, value: 10, to: entry.date) ?? Date()
      let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
      completion(timeline)
    }
  }

  private func fetchDataForWidget(completion: @escaping (iOSWidgetEntry) -> Void) {
    let storeFlags = Store.shared.retrieve(forKey: "sharedFlags")

    Task {
      do {
        // This assumes your EventKitFetcher has an async method
        // that returns [(morning: Bool, afternoon: Bool, evening: Bool)].
        let busyDays = try await EventKitFetcher.shared.initializeEventStore()

        let entry = iOSWidgetEntry(date: Date(), flags: storeFlags, eventDays: busyDays)
        completion(entry)
      } catch {
        // If an error occurs, provide fallback data
        let fallback = iOSWidgetEntry(
          date: Date(),
          flags: storeFlags,
          eventDays: (1...30).map { _ in (false, false, false) }
        )
        completion(fallback)
      }
    }
  }
}

// MARK: - 4) The SwiftUI View for a Single Timeline Entry
struct iOSWidgetExtensionEntryView: View {
    let entry: iOSWidgetEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        VStack(spacing: 0) {
          
//            CalendarDateTitle()

            CalendarStaticView(healthFlags: entry.flags, busyDays: entry.eventDays)
                
        }
        .containerBackground(.black, for: .widget)
    }
}

// MARK: - 5) The Widget Configuration
struct iOSWidgetExtension: Widget {
  let kind: String = "iOSWidgetExtension"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: iOSWidgetProvider()) { entry in
      iOSWidgetExtensionEntryView(entry: entry)
    }
    .configurationDisplayName("PicoCal (iPhone)")
    .description("A compact iPhone widget for PicoCal.")
    .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
  }
}
