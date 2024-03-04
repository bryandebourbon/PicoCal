import SwiftUI

struct CalendarView: View {
  @Binding var calorieDays: [Bool]
  @Environment(\.calendar) var calendar

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

  func fullMonthContent() -> [AnyView] {
    let startOfMonth = calendar.startOfMonth(for: Date())
    let range = calendar.range(of: .day, in: .month, for: Date())!
    var dayViews: [AnyView] = []

    let weekdayOfFirstDay = calendar.component(.weekday, from: startOfMonth)
    let offset = (weekdayOfFirstDay - calendar.firstWeekday + 7) % 7
    for _ in 0..<offset {
      dayViews.append(AnyView(defaultView))
    }

    dayViews += (0..<range.count).map { day in
      let currentDate = calendar.date(byAdding: .day, value: day, to: startOfMonth)!
      let dayOfMonth = calendar.component(.day, from: currentDate)
      let isToday = calendar.isDateInToday(currentDate)
      let isPast = isDateInPast(currentDate)

      print("calorieDays \(calorieDays)")
      let isComplete = day < calorieDays.count ? calorieDays[day] : false

      return AnyView(
        DefaultDayBlock(
          dayOfMonth: dayOfMonth,
          isToday: isToday,
          isPast: isPast,
          isComplete: isComplete
        )
      )
    }

    return dayViews
  }

  func isDateInPast(_ date: Date) -> Bool {
    return calendar.startOfDay(for: date) < calendar.startOfDay(for: Date())
  }
}
