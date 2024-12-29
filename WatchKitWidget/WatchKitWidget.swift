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
struct WatchWidgetEntry: TimelineEntry {
  let date: Date
  let flags: [Bool]
  let eventDays: [(morning: Bool, afternoon: Bool, evening: Bool)]
}

/// 2) A `TimelineProvider` that fetches data from DataManager (or bridging calls),
/// then hands off a `WatchWidgetEntry` to the Widget’s SwiftUI.
struct WatchWidgetProvider: TimelineProvider {
  func placeholder(in context: Context) -> WatchWidgetEntry {
    // Simple placeholder data
    WatchWidgetEntry(
      date: Date(),
      flags: (1...30).map { _ in Bool.random() },
      eventDays: (1...30).map { _ in (morning: Bool.random(),
                                      afternoon: Bool.random(),
                                      evening: Bool.random()) }
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
    
    // If you want to fetch fresh EventKit data:
    Task {
      do {
        // This calls your async method that fetches or re-initializes EventKit
        let busyDays = try await EventKitFetcher.shared.initializeEventStore()
        
        let entry = WatchWidgetEntry(
          date: Date(),
          flags: storeFlags,
          eventDays: busyDays
        )
        completion(entry)
        
      } catch {
        // If an error occurs, provide fallback data
        let fallback = WatchWidgetEntry(
          date: Date(),
          flags: storeFlags,
          eventDays: (1...30).map { _ in (false, false, false) }
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
      CalendarDateTitle()
        .frame(height: 1)
      
      //  We can’t use the `CalendarView<T: CalendarViewProviding>` directly,
      //  because a Widget can’t hold an @ObservedObject. Instead, pass static data:
      CalendarStaticView(
        healthFlags: entry.flags,
        busyDays: entry.eventDays
      )
      .offset(x: -6)
    }
    .frame(width: 180, height: 56)
    .offset(y: -8)
    .containerBackground(for: .widget) {
      Color.black
    }
  }
}



/// 6) The widget configuration
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
