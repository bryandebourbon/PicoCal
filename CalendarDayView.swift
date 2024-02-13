import EventKit
import SwiftUI

struct CalendarDayView<Events: Sequence>: View where Events.Element: EventRepresentable {
  var events: Events
  let day: Date

  var body: some View {
    GeometryReader { geometry in
      ZStack(alignment: .leading) {
        // VStack for HourRows

        VStack(alignment: .leading, spacing: 0) {
          ForEach(8..<24) { hour in
            HourRow(hour: hour, events: Array(events), day: day)
            Divider()
          }
        }

//        if Calendar.current.isDateInToday(day) {
//          let currentHour = Calendar.current.component(.hour, from: Date())
//
//          let currentMinute = Calendar.current.component(.minute, from: Date())
//
//          let hourHeight = geometry.size.height / 16
//
//          let positionY = Int(hourHeight) * (currentHour - 8) + Int(CGFloat(currentMinute) / hourHeight)

//          VStack {
//            Spacer().frame(
//              height:
//                CGFloat(positionY)
//            )
//
//            EllipseWithStem()
//            Spacer()
//          }
//        }

      }
    }
  }
}

struct HourRow<Events: Sequence>: View where Events.Element: EventRepresentable {
  var hour: Int
  var events: Events
  let day: Date

  var body: some View {
    HStack {
      Text("\(hour)").font(.system(size: 7))
//      Divider()
      VStack {
        ForEach(
          events.filter { self.eventOccursDuring($0, hour: hour, day: day) }.map { $0 }, id: \.id
        ) { event in
          Text(event.title).font(.system(size: 7))
        }
      }
      Spacer()
    }
  }

  func eventOccursDuring(_ event: any EventRepresentable, hour: Int, day: Date) -> Bool {
    let calendar = Calendar.current
    let eventStartHour = calendar.component(.hour, from: event.startDate)
    let eventDay = calendar.startOfDay(for: event.startDate)
    let currentDay = calendar.startOfDay(for: day)
    return eventStartHour == hour && eventDay == currentDay
  }
}

struct CalendarDayView_Previews: PreviewProvider {
  static var previews: some View {
    // Ensure generateWeeklyMockEventData returns [MockEvent] or cast to [MockEvent]
    let previewEvents: [MockEvent] =
      EventKitFetcher.generateWeeklyMockEventData()
    CalendarDayView(events: previewEvents, day: Date())
  }
}
