import EventKit
import SwiftUI
import WidgetKit

@main
struct WatchWidgetExtensionBundle: WidgetBundle {
  @WidgetBundleBuilder
  var body: some Widget {
    // You can include multiple widgets here if desired
    WatchWidgetExtension()
  }
}

/// 1) A simple `TimelineEntry` that captures the data needed by the widget.
/// We add `holidayDates` to hold the set of holiday days this month.
struct WatchWidgetEntry: TimelineEntry {
  let date: Date
  let flags: [Bool]
  let eventDays: [(morning: Bool, afternoon: Bool, evening: Bool)]
  let holidayDates: Set<Date>
}

/// 2) A `TimelineProvider` that fetches data, then hands off a `WatchWidgetEntry` to the widget’s SwiftUI.
struct WatchWidgetProvider: TimelineProvider {
  func placeholder(in context: Context) -> WatchWidgetEntry {
    // Simple placeholder data
    WatchWidgetEntry(
      date: Date(),
      flags: (1...30).map { _ in Bool.random() },
      eventDays: (1...30).map { _ in (morning: Bool.random(),
                                      afternoon: Bool.random(),
                                      evening: Bool.random()) },
      holidayDates: []  // No holiday data in the placeholder
    )
  }

  func getSnapshot(in context: Context, completion: @escaping (WatchWidgetEntry) -> Void) {
    // For debug or preview in Widget Gallery, fetch data quickly:
    fetchDataForWidget { entry in
      completion(entry)
    }
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<WatchWidgetEntry>) -> Void) {
    // A real fetch of data for your watch widget:
    fetchDataForWidget { entry in
      // Decide how long before the widget updates again
      let nextUpdate = Calendar.current.date(byAdding: .minute, value: 10, to: entry.date) ?? Date()
      let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
      completion(timeline)
    }
  }

  /// 3) Bridge the async calls from `DataManager` or `EventKitFetcher` into the widget’s callback.
  private func fetchDataForWidget(completion: @escaping (WatchWidgetEntry) -> Void) {
    let storeFlags = Store.shared.retrieve(forKey: "sharedFlags")
    
    Task {
      do {
        // 3a) Fetch busyDays as before
        let busyDays = try await EventKitFetcher.shared.initializeEventStore()
        
        // 3b) Fetch holiday dates for the current month
        let holidayDates = try await EventKitFetcher.shared.fetchHolidayDatesForCurrentMonth()
        
        let entry = WatchWidgetEntry(
          date: Date(),
          flags: storeFlags,
          eventDays: busyDays,
          holidayDates: holidayDates
        )
        completion(entry)
        
      } catch {
        // If an error occurs, provide fallback data
        let fallback = WatchWidgetEntry(
          date: Date(),
          flags: storeFlags,
          eventDays: (1...30).map { _ in (false, false, false) },
          holidayDates: []
        )
        completion(fallback)
      }
    }
  }
}

/// 4) The SwiftUI view that renders the data from a single `WatchWidgetEntry`.
struct WatchWidgetExtensionEntryView: View {
  let entry: WatchWidgetProvider.Entry
  
  var body: some View {
    VStack {
      // We can’t use the `CalendarView<T: CalendarViewProviding>` directly
      // because a Widget can’t hold an @ObservedObject. Instead, pass static data:
      CalendarStaticView(
        healthFlags: entry.flags,
        busyDays: entry.eventDays,
        holidayDates: entry.holidayDates
      )
    }
    .containerBackground(for: .widget) {
      Color.black
    }
  }
}

/// 5) The widget configuration
struct WatchWidgetExtension: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(
      kind: "WatchWidgetExtension",
      provider: WatchWidgetProvider()
    ) { entry in
      WatchWidgetExtensionEntryView(entry: entry)
    }
    .configurationDisplayName("Watch PicoCal")
    .description("A compact Watch widget for PicoCal.")
  }
}
