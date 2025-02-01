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
/// We add a `holidayDates` field to capture which days are holidays.
struct iOSWidgetEntry: TimelineEntry {
  let date: Date
  let flags: [Bool]
  let eventDays: [(morning: Bool, afternoon: Bool, evening: Bool)]
  
  // NEW: The set of holiday dates in the current month
  let holidayDates: Set<Date>
}

// MARK: - 3) Timeline Provider
struct iOSWidgetProvider: TimelineProvider {
  func placeholder(in context: Context) -> iOSWidgetEntry {
    iOSWidgetEntry(
      date: Date(),
      flags: (1...30).map { _ in Bool.random() },
      eventDays: (1...30).map { _ in
        (morning: Bool.random(), afternoon: Bool.random(), evening: Bool.random())
      },
      holidayDates: []
    )
  }

  func getSnapshot(in context: Context, completion: @escaping (iOSWidgetEntry) -> Void) {
    fetchDataForWidget { entry in
      completion(entry)
    }
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<iOSWidgetEntry>) -> Void) {
    fetchDataForWidget { entry in
      // Update again in 10 minutes (or choose whatever interval you prefer)
      let nextUpdate = Calendar.current.date(byAdding: .minute, value: 10, to: entry.date) ?? Date()
      let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
      completion(timeline)
    }
  }

  /// Fetch the data needed for this widget, including holiday dates.
  private func fetchDataForWidget(completion: @escaping (iOSWidgetEntry) -> Void) {
    // Check if we need to clear data
    if Health.shared.shouldClearHealthData() {
        Store.shared.persist(data: [], forKey: "sharedFlags")
    }
    
    // Get potentially cleared data
    let storeFlags = Store.shared.retrieve(forKey: "sharedFlags")

    Task {
      do {
        // 1) Fetch busy events for the current month (existing logic)
        let busyDays = try await EventKitFetcher.shared.initializeEventStore()

        // 2) Fetch holiday dates for the current month
        let holidayDates = try await EventKitFetcher.shared.fetchHolidayDatesForCurrentMonth()

        let entry = iOSWidgetEntry(
          date: Date(),
          flags: storeFlags,
          eventDays: busyDays,
          holidayDates: holidayDates
        )
        completion(entry)

      } catch {
        // If an error occurs, provide fallback data
        let fallback = iOSWidgetEntry(
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

// MARK: - 4) SwiftUI View for a Single Timeline Entry
struct iOSWidgetExtensionEntryView: View {
  let entry: iOSWidgetEntry
  @Environment(\.widgetFamily) var family

  var body: some View {
    switch family {
    case .accessoryCircular:
      // Circular Lock Screen widget
      ZStack {
        // Use your existing calendar logic but simplified for tiny circular display
        CalendarStaticView(
          healthFlags: entry.flags,
          busyDays: entry.eventDays,
          holidayDates: entry.holidayDates
        )
        .widgetAccentable()
      } .containerBackground(Color("background"), for: .widget)
      
    case .accessoryRectangular:
      // Rectangular Lock Screen widget
      VStack {
        CalendarStaticView(
          healthFlags: entry.flags,
          busyDays: entry.eventDays,
          holidayDates: entry.holidayDates
        )
      }
      .widgetAccentable()
      .containerBackground(Color("background"), for: .widget)

    case .accessoryInline:
      // Inline Lock Screen widget (text only)
      Text("Today: \(entry.flags.filter { $0 }.count) completed")
            .containerBackground(Color("background"), for: .widget)

    default:
      // Your existing Home Screen widget layout
      VStack(spacing: 0) {
        CalendarStaticView(
          healthFlags: entry.flags,
          busyDays: entry.eventDays,
          holidayDates: entry.holidayDates
        )
      }
      .containerBackground(Color("background"), for: .widget)
    }
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
    .supportedFamilies([
      .systemSmall,
      .systemMedium, 
      .systemLarge,
      .systemExtraLarge,
      // Add Lock Screen widget families:
      .accessoryCircular,
      .accessoryRectangular,
      .accessoryInline
    ])
  }
}
