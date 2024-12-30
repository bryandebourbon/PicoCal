import EventKit
import UIKit
import SwiftUICore
import Foundation

/// Custom error for EventKit scenarios.
enum EventKitError: Error {
  case permissionDenied
  case invalidDateRange
}

/// A protocol for any type that can be represented as an event with a title and start/end dates.
protocol EventRepresentable: Identifiable {
  var id: UUID { get }
  var title: String { get }
  var startDate: Date { get }
  var endDate: Date { get }
}

/// Wrapper around EKEvent to conform to EventRepresentable.
struct EventWrapper: EventRepresentable, Identifiable {
  var id: UUID { UUID() } // Each call yields a new UUID
  var ekEvent: EKEvent

  init(ekEvent: EKEvent) {
    self.ekEvent = ekEvent
  }

  var title: String {
    ekEvent.title ?? "No Title"
  }

  var startDate: Date {
    ekEvent.startDate
  }

  var endDate: Date {
    ekEvent.endDate
  }
}

/// A mock event useful for testing.
struct MockEvent: EventRepresentable, Identifiable {
  var id: UUID { UUID() } // Conformance to Identifiable
  var title: String
  var startDate: Date
  var endDate: Date
}

/// A singleton for fetching EventKit data using Swift Concurrency.
class EventKitFetcher {
  static let shared = EventKitFetcher()
  static let store = EKEventStore()
  static var eventDays = [EventWrapper]()

  private init() {}

  // MARK: - Public Async Entry Point

  /// Requests calendar access, fetches monthly events, calculates “busy” periods, and returns them.
  func initializeEventStore() async throws -> [(morning: Bool, afternoon: Bool, evening: Bool)] {
    print("[EventKit] Initializing Event Store...")
    try await Self.requestCalendarAccess()
    let events = try await Self.fetchEvents()
    print("[EventKit] Fetched \(events.count) events this month.")

    // Wrap the EKEvents and store them
    let wrappedEvents = events.map { EventWrapper(ekEvent: $0) }
    Self.eventDays = wrappedEvents

    // Calculate busy periods for the current month
    let now = Date()
    let calendar = Calendar.current
    let startOfMonth = calendar.startOfMonth(for: now)
    guard let range = calendar.range(of: .day, in: .month, for: now) else {
      print("[EventKit] Could not find day range for current month.")
      throw EventKitError.invalidDateRange
    }

    let busyDays = calculateBusyPeriods(for: startOfMonth, range: range)
    print("[EventKit] Calculated busy periods for \(busyDays.count) days.")
    return busyDays
  }

  // MARK: - Request Calendar Access (async/throws)

  /// Requests full access to the calendar. Throws if not granted or if an error occurs.
  static func requestCalendarAccess() async throws {
    print("[EventKit] Requesting calendar access...")
    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
      // `requestFullAccessToEvents` is presumably a custom extension on EKEventStore
      // that eventually calls requestAccess(to: .event, completion:)
      store.requestFullAccessToEvents { granted, error in
        // Jump back to main thread if needed
        DispatchQueue.main.async {
          if let error = error {
            print("[EventKit] Error in requestCalendarAccess: \(error.localizedDescription)")
            continuation.resume(throwing: error)
          } else if !granted {
            print("[EventKit] User denied calendar access.")
            continuation.resume(throwing: EventKitError.permissionDenied)
          } else {
            print("[EventKit] Calendar access granted.")
            continuation.resume(returning: ())
          }
        }
      }
    }
  }

  // MARK: - Fetching Events for the Current Month (async/throws)

  /// Returns events from the first day of the current month to its last day.
  static func fetchEvents() async throws -> [EKEvent] {
    print("[EventKit] Fetching events for the current month...")
    let calendar = Calendar.current
    let components = calendar.dateComponents([.year, .month], from: Date())

    // Build startDate = “start of this month”
    guard let startDate = calendar.date(from: components) else {
      print("[EventKit] Could not compute startDate from components: \(components)")
      return []
    }

    // Build endDate = “last day of this month”
    var endComponents = DateComponents()
    endComponents.month = 1
    endComponents.day = -1

    guard let endDate = calendar.date(byAdding: endComponents, to: startDate) else {
      print("[EventKit] Could not compute endDate by adding endComponents to startDate.")
      return []
    }

    // Build the predicate to match events in [startDate, endDate].
    let predicate = store.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)

    // Actually fetch events on the calling thread (no closure-based result).
    return try await withCheckedThrowingContinuation { continuation in
      let events = store.events(matching: predicate)
      // Return them synchronously
      continuation.resume(returning: events)
    }
  }

  // MARK: - Calculate Busy Periods

  /// Given the start date of the month and a day-range, returns an array describing which parts of the day are busy.
  func calculateBusyPeriods(
    for startDate: Date,
    range: Range<Int>
  ) -> [(morning: Bool, afternoon: Bool, evening: Bool)] {
    var busyDays: [(morning: Bool, afternoon: Bool, evening: Bool)] = []

    for day in range {
      let currentDate = Calendar.current.date(byAdding: .day, value: day - 1, to: startDate)!
      let busyPeriods = Self.busyPeriods(for: currentDate)
      busyDays.append(busyPeriods)
    }

    return busyDays
  }

  /// Helper that checks if any events overlap with morning, afternoon, or evening blocks of the given date.
  static func busyPeriods(
    for date: Date
  ) -> (morning: Bool, afternoon: Bool, evening: Bool) {
    let calendar = Calendar.current

    let morningStart = calendar.date(bySettingHour: 6, minute: 0, second: 0, of: date)!
    let morningEnd   = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: date)!
    let afternoonStart = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: date)!
    let afternoonEnd   = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: date)!
    let eveningStart   = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: date)!
    let eveningEnd     = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: date)!

    // We check if any stored events intersect with each time range.
    let isMorningBusy = eventDays.contains { event in
      event.startDate < morningEnd && event.endDate > morningStart
    }
    let isAfternoonBusy = eventDays.contains { event in
      event.startDate < afternoonEnd && event.endDate > afternoonStart
    }
    let isEveningBusy = eventDays.contains { event in
      event.startDate < eveningEnd && event.endDate > eveningStart
    }

    return (isMorningBusy, isAfternoonBusy, isEveningBusy)
  }
}

// MARK: - Extension for generating mock events (unchanged)

extension EventKitFetcher {
  static func generateWeeklyMockEventData() -> [MockEvent] {
    var mockEvents: [MockEvent] = []
    let calendar = Calendar.current

    // Create events for the next 7 days
    for day in 0..<7 {
      // Morning event at 9 AM
      if let morningEventDate = calendar.date(byAdding: .day, value: day, to: Date()),
         let morningStartDate = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: morningEventDate) {
        let morningEvent = MockEvent(
          title: "Morning Event",
          startDate: morningStartDate,
          endDate: morningStartDate.addingTimeInterval(3600) // 1 hour
        )
        mockEvents.append(morningEvent)
      }

      // Afternoon event at 2 PM
      if let afternoonEventDate = calendar.date(byAdding: .day, value: day, to: Date()),
         let afternoonStartDate = calendar.date(bySettingHour: 14, minute: 0, second: 0, of: afternoonEventDate) {
        let afternoonEvent = MockEvent(
          title: "Afternoon Event",
          startDate: afternoonStartDate,
          endDate: afternoonStartDate.addingTimeInterval(3600) // 1 hour
        )
        mockEvents.append(afternoonEvent)
      }
    }

    return mockEvents
  }
}


extension Date {
  func bySettingHour(_ hour: Int) -> Date {
    return Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: self)!
  }
}


// Extension for generating mock events
//extension EventKitFetcher 


struct CalendarDay {
  let date: String
  let eventCount: Int
}

struct AccosicatedDayInfoByDateNumber {
  let dateNumber: String
  let dayInfo: Any
}

struct CalendarMonth {
  var currentDate = Date()
  let calendar = Calendar.current
  var monthName: String  {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "MMM"
    return dateFormatter.string(from: currentDate)
  }

  var daysInMonth: Int {
    let range =
    calendar.range(of: .day,in: .month,for: currentDate)!
    return range.count
  }

  var startingDayOfMonth: Int {
    let components =
    calendar.dateComponents([.year, .month], from: currentDate)
    let firstDayOfMonth =
    calendar.date(from: components)!
    return calendar.component(.weekday, from: firstDayOfMonth) - 1
  }
}

extension Calendar {
  func settingHour(_ hour: Int) -> Calendar {
    var newCalendar = self
    // Set the desired date and hour here
    newCalendar.firstWeekday = hour  // This is just an example. You should set the actual date and time as needed.
    return newCalendar
  }

  func startOfMonth(for date: Date) -> Date {
    let components = dateComponents([.year, .month], from: date)
    return self.date(from: components)!
  }
}

extension EventWrapper {
  var calendarcolor: Color {

    // Convert the CGColor to a UIColor, then to SwiftUI Color
    let uiColor = UIColor(cgColor: ekEvent.calendar.cgColor)
    return Color(uiColor)

  }
}
