import EventKit
import SwiftUI



struct DayTimelineView<Events: Sequence>: View where Events.Element: EventRepresentable {
  var events: Events
  var day: Date
  let isToday: Bool

  let morningRange = 6..<12  // 6 AM to 12 PM
  let afternoonRange = 12..<18  // 12 PM to 6 PM
  let eveningRange = 18..<24  // 6 PM to 12 AM

  var body: some View {
    GeometryReader { geometry in
      if geometry.size.width <= geometry.size.height {
        Spacer().frame(maxHeight: 0.1)
        CalendarDayView(events: events, day: day)
      } else {
        ZStack {
          VStack {

            Spacer()
            HStack {
              ForEach([9, 10, 12, 10, 15, 18], id: \.self) { hour in
                Spacer().frame(minWidth: 0.1)
                Rectangle()
                  .fill(Color.white)
                  .frame(
                    width: 1, height: geometry.size.height * 0.4) /*isBucketStart(hour: hour) ? 10 : 5)*/
              }
            }.frame(maxWidth: .infinity)
              .offset(x:1)

          }

          // Event rectangles
          VStack {

            Spacer()
            HStack(spacing: 0) {
              Rectangle()
                .fill(self.hasEvent(in: morningRange) ? Color.red : Color.clear)
              Rectangle()
                .fill(self.hasEvent(in: afternoonRange) ? Color.red : Color.clear)
              Rectangle()
                .fill(self.hasEvent(in: eveningRange) ? Color.red : Color.clear)

            }
            .frame(
              width: geometry.size.width, height: geometry.size.height  * 0.35)

          }
        }

        Rectangle()
          .fill(Color.black)
          .opacity(0.3)

      }
    }
  }

   func hasEvent(in hourRange: Range<Int>) -> Bool {
    let calendar = Calendar.current
    return events.contains { event in
      let eventStartHour = calendar.component(.hour, from: event.startDate)
      let eventEndHour = calendar.component(.hour, from: event.endDate)
      return hourRange.contains(eventStartHour) || hourRange.contains(eventEndHour)
    }
  }

   func isBucketStart(hour: Int) -> Bool {
    [12].contains(hour)
  }
}

struct DayTimelineView_Previews: PreviewProvider {
  static var previews: some View {
    let previewEvents: [MockEvent] =
      EventKitFetcher.generateWeeklyMockEventData()  // This should return an array of MockEvent
    DayTimelineView(events: previewEvents, day: Date(), isToday: true)

  }

}
