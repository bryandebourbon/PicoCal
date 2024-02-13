import WidgetKit
import SwiftUI
import EventKit

@main
struct WidgetExtensionBundle: WidgetBundle {
  @WidgetBundleBuilder
  var body: some Widget {
    WidgetExtension()
  }
}

struct Provider: TimelineProvider {
  func placeholder(in context: Context) -> SimpleEntry {
    SimpleEntry(date: Date(), events: [], goalDays: [], hasContributionToday: false, calorieDays: [])
  }

  func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
    fetchSharedData { entry in
      completion(entry)
    }
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
    fetchSharedData { entry in
      let nextUpdateDate = Calendar.current.date(byAdding: .hour, value: 1, to: entry.date)!
      let timeline = Timeline(entries: [entry], policy: .after(nextUpdateDate))
      completion(timeline)
    }
  }

   func fetchSharedData(completion: @escaping (SimpleEntry) -> Void) {
//     let userDefaults = UserDefaults(suiteName: "groups.com.bryandebourbon.shared")

//     // Fetch the Bool array for calorieFlags
//     if let savedCalorieFlags = userDefaults?.array(forKey: "CalorieFlagsKey") as? [Bool] {
//       healthData.calorieFlags = savedCalorieFlags
//     }

    // Continue with your existing data fetching logic
    EventKitFetcher.fetchEvents { ekEvents in
      let wrappedEvents = ekEvents.map(EventWrapper.init)
      let entry = SimpleEntry(date: Date(), events: wrappedEvents, goalDays: [], hasContributionToday: false, calorieDays: [])
      completion(entry)
    }
  }
}

struct SimpleEntry: TimelineEntry {
  let date: Date
  let events: [EventWrapper]
  let goalDays: [Bool]
  let hasContributionToday: Bool
  let calorieDays: [Bool]
}

struct WidgetExtensionEntryView: View {
  var entry: Provider.Entry

  var body: some View {
    CalendarView(
      hasContributionToday: .constant(entry.hasContributionToday),
      eventDays: .constant(entry.events),
      goalDays: .constant(entry.goalDays),
      calorieDays: .constant(entry.calorieDays)
    )
      .background(ContainerRelativeShape().fill(Color.black))
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

// Continue with WidgetExtension_Previews, HealthData, and HealthDataPlaceholder structures as defined.


struct HealthData: Codable {
  var steps: Int = 0
  var heartRate: Int = 0
  var calorieFlags: [Bool] = []
}


// Placeholder function if needed
func HealthDataPlaceholder() -> HealthData {
  return HealthData() // Initialize with default or placeholder values
}

// Make sure to replace "YOUR_APP_GROUP_IDENTIFIER" with your actual App Group identifier.
