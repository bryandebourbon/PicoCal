import Foundation

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


