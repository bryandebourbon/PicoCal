import SwiftUI
import EventKit


/// A protocol that exposes the minimal data needed by CalendarView.
protocol CalendarViewProviding: ObservableObject {
  var healthFlags: [Bool] { get }
  var busyDays: [(Bool, Bool, Bool)] { get }
  var holidayDates: Set<Date> {get}
}

struct CalendarView<T: CalendarViewProviding>: View {
    @ObservedObject var viewModel: T
     
  var body: some View {
    CalendarStaticView(
      healthFlags: viewModel.healthFlags,
      busyDays: viewModel.busyDays,
      holidayDates: viewModel.holidayDates
    )
  }
}

struct CalendarStaticView: View {
    let healthFlags: [Bool]
    let busyDays: [(Bool, Bool, Bool)]
    let holidayDates: Set<Date>
  @Environment(\.calendar) var calendar

  // Optional: if you still need them
  @State var currentDay = Calendar.current.component(.day, from: Date())
  @State var calendarMonth = CalendarMonth()

  let numberOfColumns = 7
  let defaultView = AnyView(Color.clear)

  var body: some View {
      // TODO: Handle 6-row-months: months that start on thurs/fri with 30/31 days!
      // in this case put CalendarDateTitle left justified in the same row as the first week of the 6-row-months
      VStack(spacing: 0){
          CalendarDateTitle()
          WrapGridView(
            items: fullMonthContent(),
            numberOfColumns: numberOfColumns
          )
      }
  }

private func fullMonthContent() -> [AnyView] {
    let startOfMonth = calendar.startOfMonth(for: Date())
    let dayRange = calendar.range(of: .day, in: .month, for: startOfMonth) ?? (1..<1)

    var dayViews: [AnyView] = []

    // Offset for first weekday
    let weekdayOfFirstDay = calendar.component(.weekday, from: startOfMonth)
    let offset = (weekdayOfFirstDay - calendar.firstWeekday + 7) % 7
    for _ in 0..<offset {
        dayViews.append(AnyView(Color.clear))
    }

    for dayOfMonth in dayRange {
        let currentDate = calendar.date(byAdding: .day, value: dayOfMonth - 1, to: startOfMonth)!
        let isToday = calendar.isDateInToday(currentDate)
        let isPast = isDateInPast(currentDate)
        let index = dayOfMonth - 1

        let isComplete = index < healthFlags.count ? healthFlags[index] : false
        let busyPeriods = index < busyDays.count ? busyDays[index] : (false, false, false)
        let dayMidnight = calendar.startOfDay(for: currentDate)
        let isHoliday = holidayDates.contains(dayMidnight)

        let dayBlock = NavigationLink(
            destination: DefaultDayBlock(
                dayOfMonth: dayOfMonth,
                isToday: isToday,
                isPast: isPast,
                isComplete: isComplete,
                isBusyMorning: busyPeriods.0,
                isBusyAfternoon: busyPeriods.1,
                isBusyEvening: busyPeriods.2,
                isHoliday: isHoliday
            )//.ignoresSafeArea()
            ,
            label: {
                DefaultDayBlock(
                    dayOfMonth: dayOfMonth,
                    isToday: isToday,
                    isPast: isPast,
                    isComplete: isComplete,
                    isBusyMorning: busyPeriods.0,
                    isBusyAfternoon: busyPeriods.1,
                    isBusyEvening: busyPeriods.2,
                    isHoliday: isHoliday
                )
            }
        ).buttonStyle(.plain)

#if WIDGET_TARGET
        dayViews.append(AnyView(DefaultDayBlock(
            dayOfMonth: dayOfMonth,
            isToday: isToday,
            isPast: isPast,
            isComplete: isComplete,
            isBusyMorning: busyPeriods.0,
            isBusyAfternoon: busyPeriods.1,
            isBusyEvening: busyPeriods.2,
            isHoliday: isHoliday)))
    
#else
    
    dayViews.append(AnyView(dayBlock))
#endif
    }
    
    return dayViews
}



  private func isDateInPast(_ date: Date) -> Bool {
    return calendar.startOfDay(for: date) < calendar.startOfDay(for: Date())
  }
}
