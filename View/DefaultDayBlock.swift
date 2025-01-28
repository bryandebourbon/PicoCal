import SwiftUI

struct DefaultDayBlock: View {
    let dayOfMonth: Int
    let isToday: Bool
    let isPast: Bool
    let isComplete: Bool
    let isBusyMorning: Bool
    let isBusyAfternoon: Bool
    let isBusyEvening: Bool

    // NEW
    let isHoliday: Bool

    let DATE_TITLE_HEIGHT: CGFloat = 11
    let WATCH_WIDGET_BUSY_BAR_HEIGHT: CGFloat = 3

    private func overlayColor(isPast: Bool, isComplete: Bool) -> Color {
        #if os(watchOS)
            if isPast {
                return isComplete ? Color("goalComplete").opacity(0.5) : Color("todayIndicator").opacity(0.5)
            }
        #else
            if isPast {
                return Color("todayIndicator").opacity(0.5)
            }
        #endif
        return Color.clear
    }

    var body: some View {
      VStack(spacing: 0) {
        ZStack {
          (isToday ? Color("todayIndicator") : Color.clear)
            .clipShape(Ellipse())
            .padding(3)

          Text("\(dayOfMonth)")
            .bold()
            .font(.system(size: DATE_TITLE_HEIGHT))
            .foregroundColor(
              isHoliday ? Color("holidayFontColor") : Color("fontColor")
            )
            .background(
              (isComplete ? Color("goalComplete") : Color("default"))
                .opacity(0.6)
                .clipShape(Circle())
                .padding(-2)
            )
        }
        .frame(height: DATE_TITLE_HEIGHT - WATCH_WIDGET_BUSY_BAR_HEIGHT)

        EventPlot(
          dayOfMonth: dayOfMonth,
          isBusyMorning: isBusyMorning,
          isBusyAfternoon: isBusyAfternoon,
          isBusyEvening: isBusyEvening
        )
        .frame(minHeight: WATCH_WIDGET_BUSY_BAR_HEIGHT)
      }
      // .background((isComplete ? Color("goalComplete") : Color("default")).opacity(0.6))
      .overlay(overlayColor(isPast: isPast, isComplete: isComplete))
    }
  }





