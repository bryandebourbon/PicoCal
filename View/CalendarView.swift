import SwiftUI
import EventKit


/// A protocol that exposes the minimal data needed by CalendarView.
protocol CalendarViewProviding: ObservableObject {
  var healthFlags: [Bool] { get }
  var busyDays: [(Bool, Bool, Bool)] { get }
}

struct CalendarView<T: CalendarViewProviding>: View {
    @ObservedObject var viewModel: T
     
  var body: some View {
    CalendarStaticView(
      healthFlags: viewModel.healthFlags,
      busyDays: viewModel.busyDays
    )
  }
}

struct CalendarStaticView: View {
    let healthFlags: [Bool]
    let busyDays: [(Bool, Bool, Bool)]
  @Environment(\.calendar) var calendar

  // Optional: if you still need them
  @State var currentDay = Calendar.current.component(.day, from: Date())
  @State var calendarMonth = CalendarMonth()

  let numberOfColumns = 7
  let defaultView = AnyView(Color.clear)

  var body: some View {
    WrapGridView(
      items: fullMonthContent(),
      numberOfColumns: numberOfColumns
    )
  }

  private func fullMonthContent() -> [AnyView] {
    let startOfMonth = calendar.startOfMonth(for: Date())
    let dayRange = calendar.range(of: .day, in: .month, for: startOfMonth) ?? (1..<1)

    var dayViews: [AnyView] = []

    // Calculate the offset for the first weekday
    let weekdayOfFirstDay = calendar.component(.weekday, from: startOfMonth)
    let offset = (weekdayOfFirstDay - calendar.firstWeekday + 7) % 7
    for _ in 0..<offset {
      dayViews.append(AnyView(defaultView))
    }

    // Build a view for each day in dayRange (1-based)
    for dayOfMonth in dayRange {
      let currentDate = calendar.date(byAdding: .day, value: dayOfMonth - 1, to: startOfMonth)!
      let isToday = calendar.isDateInToday(currentDate)
      let isPast = isDateInPast(currentDate)
      let index = dayOfMonth - 1

      // Safely access flags
      let isComplete = index < healthFlags.count
        ? healthFlags[index]
        : false

      let busyCount = busyDays.count
      let busyPeriods = index < busyCount
        ? busyDays[index]
        : (false, false, false)

      dayViews.append(
        AnyView(
          DefaultDayBlock(
            dayOfMonth: dayOfMonth,
            isToday: isToday,
            isPast: isPast,
            isComplete: isComplete,
            isBusyMorning: busyPeriods.0,
            isBusyAfternoon: busyPeriods.1,
            isBusyEvening: busyPeriods.2
          )
        )
      )
    }

    return dayViews
  }

  private func isDateInPast(_ date: Date) -> Bool {
    return calendar.startOfDay(for: date) < calendar.startOfDay(for: Date())
  }
}
