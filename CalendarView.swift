import HealthKit
import SwiftUI
import WidgetKit

struct CalendarView<Events: Sequence>: View where Events.Element: EventRepresentable {

  @Environment(\.calendar) var calendar

  @State var currentDay = Calendar.current.component(.day, from: Date())

  @Binding var hasContributionToday: Bool

  let timer = Timer.publish(every: 60 * 60, on: .main, in: .common).autoconnect()

  @Binding var eventDays: Events
  @Binding var goalDays: [Bool]
  @State var calendarMonth = CalendarMonth()
  @Binding var calorieDays: [Bool]

  let numberOfColumns = 7
  let padding: CGFloat = 2

  var numberOfRows: Int {
    return (calendarMonth.daysInMonth / numberOfColumns + 1)
  }

  //  healthDataFetcher.fetchCaloriesBurned { result in
  //    switch result {
  //      case .success(let dailyCalories):
  //        print("Fetched daily calories: \(dailyCalories)")
  //        // Update your UI or model with `dailyCalories` here
  //      case .failure(let error):
  //        print("Error fetching calories burned: \(error)")
  //        // Handle errors here
  //    }
  //  }
  let defaultView = AnyView(Color.clear)

  func calculateCurrentDayPosition() -> (row: Int, column: Int) {
    let startOfMonth = calendar.startOfMonth(for: Date())
    let firstDayOfWeek = calendar.component(.weekday, from: startOfMonth)
    let offset = (firstDayOfWeek - calendar.firstWeekday + 7) % 7

    // Calculate the adjusted day of the month for the current day, including the offset
    let adjustedDay = currentDay + offset - 1  // Subtracting 1 since `currentDay` is 1-based, but our calculation is 0-based

    let row = adjustedDay / numberOfColumns
    let column = adjustedDay % numberOfColumns

    return (row, column)
  }

  var body: some View {
    GeometryReader { geometry in
      let (blockWidth, blockHeight) = getResponsiveDemensions(geometry: geometry)
      let dayViewArray = fullMonthContent(blockWidth: blockWidth)

      // Calculate row and column for current day

      //      let row = (currentDay + start_offset) / numberOfColumns
      let column = (currentDay) % numberOfColumns

      let position = calculateCurrentDayPosition()
      let xPosition = CGFloat(position.column) * (blockWidth + padding)
      let yPosition = CGFloat(position.row) * blockHeight + 4

      ZStack {
        CalendarGrid(
          dayViewArray: dayViewArray,
          numberOfRows: numberOfRows,
          numberOfColumns: numberOfColumns,
          blockWidth: blockWidth,
          blockHeight: blockHeight
        )

        CurrentDayIndicator(
          xPosition: xPosition,
          yPosition: yPosition,
          hourOffset:
            calculateHourOffset(column: column, blockWidth: blockWidth),
          blockHeight: blockHeight,
          blockWidth: blockWidth,
          currentDay: currentDay
        )
      }
    }
    .onAppear {

    }

    //      gitHubFetcher.fetchContributionBooleans(accessToken: "YOUR_ACCESS_TOKEN") { result in
    //        switch result {
    //          case .success(let booleans):
    //            // Assuming you have a method to save fetched GitHub data to shared storage
    //            saveGitHubDataToSharedStorage(booleans)
    //          case .failure(let error):
    //            print(error.localizedDescription)
    //        }
    //      }

    .onReceive(timer) { _ in
      updateCurrentDay()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)

  }
  func fetchAndSaveCaloriesBurned() {
    guard let healthStore = HKHealthStore.isHealthDataAvailable() ? HKHealthStore() : nil else {
      return
    }
    let calorieType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
    let calendar = Calendar.current
    let now = Date()
    let range = calendar.range(of: .day, in: .month, for: now)!
    var dailyCalories: [String: Double] = [:]

    for day in range {
      guard let date = calendar.date(bySetting: .day, value: day, of: now) else { continue }
      let startOfDay = calendar.startOfDay(for: date)
      let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
      let predicate = HKQuery.predicateForSamples(
        withStart: startOfDay, end: endOfDay, options: .strictStartDate)

      let query = HKStatisticsQuery(
        quantityType: calorieType, quantitySamplePredicate: predicate, options: .cumulativeSum
      ) { _, result, _ in
        guard let result = result,
          let calories = result.sumQuantity()?.doubleValue(for: .kilocalorie())

        else {
          return
        }
//        print("Fetching HealthKit data for day: \(day), calories: \(calories)")
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateKey = dateFormatter.string(from: date)
        dailyCalories[dateKey] = calories

        // Save after the last day is processed
        if day == range.last {
          DispatchQueue.main.async {
            let userDefaults = UserDefaults(suiteName: "group.com.bryandebourbon.shared")
            userDefaults?.set(dailyCalories, forKey: "DailyCalorieData")
            WidgetCenter.shared.reloadAllTimelines()
          }
        }
      }
      healthStore.execute(query)

    }
  }

  //  func loadCalorieDataFromUserDefaults() {
  //    let userDefaults = UserDefaults(suiteName: "group.com.bryandebourbon.shared")
  //    if let savedCalories = userDefaults?.dictionary(forKey: "DailyCalorieData") as? [String: Double]
  //    {
  //      //      dailyCalories = savedCalories
  //    }
  //  }

  func updateCurrentDay() {
    let newDay = calendar.component(.day, from: Date())
    if newDay != currentDay {
      currentDay = newDay
      // Update hasContributionToday based on the new current day

      hasContributionToday = (currentDay - 1) < goalDays.count && goalDays[currentDay - 1]

// should include logic about goal days and github commit








    }
  }

  //  func saveHealthDataToSharedStorage() {
  //    let userDefaults = UserDefaults(suiteName: "group.com.bryandebourbon.shared")
  //    // Example: Save steps and calories
  //    userDefaults?.set(healthKitFetcher.steps, forKey: "HealthDataSteps")
  //    userDefaults?.set(healthKitFetcher.calories, forKey: "HealthDataCalories")
  //  }

  func calculateHourOffset(column: Int, blockWidth: CGFloat) -> CGFloat {
    let currentHour = calendar.component(.hour, from: Date())
    let totalHoursInDay: CGFloat = 24
    var adjustment = (CGFloat(currentHour) - 9)

    if adjustment < 0 { adjustment = 0 }
    let position = adjustment / totalHoursInDay * blockWidth
    return position - 3
  }

  func getResponsiveDemensions(geometry: GeometryProxy) -> (CGFloat, CGFloat) {
    let totalWidth = geometry.size.width
    let totalHeight = geometry.size.height
    let blockWidth =
      (totalWidth - padding * (CGFloat(numberOfColumns) + 1)) / CGFloat(numberOfColumns)
    let blockHeight =
      (totalHeight - padding * (CGFloat(numberOfRows) + 1)) / CGFloat(numberOfRows)
    return (blockWidth + 2.8, blockHeight + 3.5)
  }

  var currentMonthName: String {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEEE MMMM d yyyy"
    return formatter.string(from: Date())
  }

  func fullMonthContent(blockWidth: CGFloat) -> [AnyView] {

    let startOfMonth = calendar.startOfMonth(for: Date())
    let range = calendar.range(of: .day, in: .month, for: Date())!

    let weekdayOfFirstDay = calendar.component(.weekday, from: startOfMonth)

    let offset = (weekdayOfFirstDay - calendar.firstWeekday + 7) % 7

    var dayViews: [AnyView] = []

    for _ in 0..<offset {
      dayViews.append(AnyView(defaultView))
    }

    dayViews += (0..<range.count).map { day in
      let currentDate = calendar.date(byAdding: .day, value: day, to: startOfMonth)!
      let dayOfMonth = calendar.component(.day, from: currentDate)
      let isToday = calendar.isDateInToday(currentDate)
      return AnyView(
        defaultDayView(
          date: currentDate, dayOfMonth: dayOfMonth, isToday: isToday, blockWidth: blockWidth))
    }

    return dayViews
  }

  var dateFormatter: DateFormatter {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter
  }

  func defaultDayView(
    date: Date,
    dayOfMonth: Int,
    isToday: Bool,
    blockWidth: CGFloat
  )
    -> some View
  {
    //    let eventsForThisDay = eventDays.filter { event in
    //      calendar.isDate(event.startDate, inSameDayAs: date)
    //    }
    // Filter the events that happen on this specific date.
    let eventsForThisDay = eventDays.filter { event in
      let eventStartDay = calendar.startOfDay(for: event.startDate)
      let currentDay = calendar.startOfDay(for: date)
      return eventStartDay == currentDay
    }

//    print("caldays: \(calorieDays)")

    let caloriesWithPadding =
      calorieDays + [
        false, false, false, false, false, false, false, false, false, false, false, false, false,
        false, false, false, false, false, false, false, false, false, false, false, false, false,
        false, false, false, false, false, false, false, false, false, false, false, false, false,
        false, false, false, false, false, false, false, false, false, false, false, false, false,
        false, false, false, false, false, false, false, false, false, false, false, false, false,
        false, false, false, false, false, false, false,
      ]
    let shouldFillBlue = caloriesWithPadding[dayOfMonth - 1]

    let isPast = calendar.compare(date, to: Date(), toGranularity: .day) == .orderedAscending

    // Calculate index for goalDays
    let goalDayIndex = calendar.component(.day, from: date) - 1

    // Check if the index is within range and then access the corresponding value
    let shouldFillGreen =
      goalDayIndex >= 0 && goalDayIndex < goalDays.count && goalDays[goalDayIndex]

    return GeometryReader { geometry in

      ZStack {

        DayTimelineView(events: Array(eventsForThisDay), day: date, isToday: isToday)
          .frame(minHeight: 10)

        if isToday {
          let currentHour = calendar.component(.hour, from: Date())
          let totalHoursInDay: CGFloat = 24
          let adjustment = (CGFloat(currentHour) - 9)

          if adjustment > 0 {
            let position = (adjustment / totalHoursInDay * blockWidth) + 3

            ZStack {
              BinaryStatus(
                isToday: isToday,
                position: position,
                hasContributionToday: $hasContributionToday
              )
              //              LoadingBar(total: 1000, caloriesToday: 500, color: Color(.red))
            }

          }

        }

        VStack {

          ZStack {
            RoundedRectangle(cornerRadius: 5).fill(Color("background")).frame(width: 6, height: 7)

            Text("\(dayOfMonth)").bold()
              .font(.system(size: 11.5))
              .foregroundColor(Color("foreground"))
              .frame(minHeight: 0)
            //            .shadow(radius: 10)
          }

          Spacer()
        }.frame(maxHeight: .infinity)

        Rectangle().fill(shouldFillGreen ? Color.green : Color.black).opacity(isPast ? 0.4 : 0)
        Rectangle().fill(shouldFillBlue ? Color(.green) : Color.clear).opacity(isPast ? 0.4 : 0)

        //        TimeStaff(isToday: isToday)

      }.frame(
        width: geometry.size.width,
        height: geometry.size.height)
    }

  }

}
func createPreviewEvent() -> MockEvent {
  // Create a MockEvent with the required properties
  return MockEvent(
    title: "Preview Event",
    startDate: Calendar.current.date(byAdding: .hour, value: 2, to: Date()) ?? Date(),
    endDate: Calendar.current.date(byAdding: .hour, value: 3, to: Date()) ?? Date()
  )
}

func generateRandomBooleanArray(size: Int = 30) -> [Bool] {
  return (0..<size).map { _ in Bool.random() }
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

struct CalendarGrid: View {
  let dayViewArray: [AnyView]
  let numberOfRows: Int
  let numberOfColumns: Int
  let blockWidth: CGFloat
  let blockHeight: CGFloat

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      ForEach(0..<numberOfRows, id: \.self) { rowIndex in
        HStack(spacing: 2) {
          ForEach(0..<numberOfColumns, id: \.self) { columnIndex in
            let index = rowIndex * numberOfColumns + columnIndex
            if index < dayViewArray.count {
              dayViewArray[index]
                .frame(width: blockWidth, height: blockHeight)
                .cornerRadius(4)
            }
          }
        }
      }
    }
    .offset(x: -8, y: -4)
  }
}

struct CurrentDayIndicator: View {
  let xPosition: CGFloat
  let yPosition: CGFloat
  let hourOffset: CGFloat
  let blockHeight: CGFloat
  let blockWidth: CGFloat
  let currentDay: Int
  let color: Color = Color.red
  let backgroundColor = Color.black
  let emoji: String = ""

  var body: some View {
    ZStack {
      // The line indicator
      Rectangle().fill(.black)
        .frame(width: 6, height: 6)
        .opacity(0.3)
        .position(x: xPosition + hourOffset, y: yPosition)
      Rectangle()
        .fill(color)

        .frame(width: 4, height: 8)
        .opacity(0.7)
        .position(x: xPosition + hourOffset, y: yPosition + blockHeight / 2)
      ZStack(alignment: .center) {

        Circle()
          .fill(.black)
          .frame(width: 15, height: 15)
          .opacity(0.5)
          .position(x: xPosition + hourOffset, y: yPosition)

        Circle()
          .fill(color)
          .frame(width: 12, height: 12)
          .opacity(0.8)
          .position(x: xPosition + hourOffset, y: yPosition)

        Text("\(emoji)")
          .bold()
          .font(.system(size: 16))
          //          .foregroundColor(Color.white)
          //          .opacity(0.5)
          .position(x: xPosition + hourOffset, y: yPosition)
      }
    }
  }
}
//var body: some View {
//  ZStack {
//    // The line indicator
//    Rectangle().fill(.black)
//      .frame(width: 6, height: 6)
//      .opacity(0.3)
//      .position(x: xPosition + hourOffset, y: yPosition + 8)
//    Rectangle()
//      .fill(color)
//
//      .frame(width: 4, height: 8)
//      .opacity(0.7)
//      .position(x: xPosition + hourOffset, y: yPosition + blockHeight / 2)
//    ZStack(alignment: .center) {
//
//      Circle()
//        .fill(.white)
//        .frame(width: 15, height: 15)
//        .opacity(0.2)
//        .position(x: xPosition + hourOffset, y: yPosition + 2)
//
//       Second Circle (foreground)
//              Circle()
//                .fill(color)
//                .frame(width: 12, height: 12)
//                .opacity(0.5)
//                .position(x: xPosition + hourOffset, y: yPosition)
//
//      Text("\(emoji)")
//        .bold()
//        .font(.system(size: 16))
//      //          .foregroundColor(Color.white)
//      //          .opacity(0.5)
//        .position(x: xPosition + hourOffset, y: yPosition + 1)
//    }
