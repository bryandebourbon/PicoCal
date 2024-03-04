import EventKit

protocol EventRepresentable: Identifiable {
  var id: UUID { get }
  var title: String { get }
  var startDate: Date { get }
  var endDate: Date { get }
}

struct EventWrapper: EventRepresentable, Identifiable {
  var id: UUID { UUID() }// Conformance to Identifiable
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

struct MockEvent: EventRepresentable, Identifiable {
  var id: UUID { UUID() } // Conformance to Identifiable
  var title: String
  var startDate: Date
  var endDate: Date
}


class EventKitFetcher {
  static let store = EKEventStore()
  static var eventDays = [any EventRepresentable]() // Updated to use EventRepresentable

  // Initialize event store and fetch events
  func initializeEventStore(completion: @escaping (Bool, [any EventRepresentable]?, Error?) -> Void) {
    EventKitFetcher.requestCalendarAccess { granted, error in
      if granted {
        EventKitFetcher.fetchEvents { events in
          let wrappedEvents = events.map { EventWrapper(ekEvent: $0) }
          EventKitFetcher.eventDays = wrappedEvents
          completion(true, wrappedEvents, nil)
        }
      } else {
        completion(false, nil, error)
      }
    }
  }

  // Request calendar access
  static func requestCalendarAccess(completion: @escaping (Bool, Error?) -> Void) {
    store.requestFullAccessToEvents { granted, error in
      DispatchQueue.main.async {
        completion(granted, error)
      }
    }
  }

  // Fetch events from the calendar
  static func fetchEvents(completion: @escaping ([EKEvent]) -> Void) {
    let calendar = Calendar.current

    let components = calendar.dateComponents([.year, .month], from: Date())
    guard let startDate = calendar.date(from: components) else {
      completion([])
      return
    }

    var endComponents = DateComponents()
    endComponents.month = 1
    endComponents.day = -1
    guard let endDate = calendar.date(byAdding: endComponents, to: startDate) else {
      completion([])
      return
    }

    let predicate = store.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
    let events = store.events(matching: predicate)

    completion(events)
  }

  // Date formatter
  static var dateFormatter: DateFormatter {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter
  }
}

// Extension for generating mock events
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
          endDate: morningStartDate.addingTimeInterval(3600) // 1 hour long
        )
        mockEvents.append(morningEvent)
      }

      // Afternoon event at 2 PM
      if let afternoonEventDate = calendar.date(byAdding: .day, value: day, to: Date()),
         let afternoonStartDate = calendar.date(bySettingHour: 14, minute: 0, second: 0, of: afternoonEventDate) {
        let afternoonEvent = MockEvent(
          title: "Afternoon Event",
          startDate: afternoonStartDate,
          endDate: afternoonStartDate.addingTimeInterval(3600) // 1 hour long
        )
        mockEvents.append(afternoonEvent)
      }
    }

    return mockEvents
  }
}


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
    dateFormatter.dateFormat = "MMMM"
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

