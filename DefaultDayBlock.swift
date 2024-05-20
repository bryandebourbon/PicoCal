import SwiftUI

struct DefaultDayBlock: View {
  let dayOfMonth: Int
  let isToday: Bool
  let isPast: Bool
  let isComplete: Bool

  let isBusyMorning: Bool = false
  let isBusyAfternoon: Bool = false
  let isBusyEvening: Bool = false

  var body: some View {
    ZStack {
      (isComplete ? Color("goalComplete") : Color("default")).opacity(0.6)
      (isToday ? Color("todayIndicator"): Color.clear).clipShape(Ellipse()).opacity(0.6)
    }
    .overlay(
      Text("\(dayOfMonth)")
        .bold()
        .font(.system(size: 11))
        .foregroundColor(Color("fontColor"))
    )
  }
}



