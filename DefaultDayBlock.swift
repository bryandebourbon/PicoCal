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
      Color.gray.opacity(0.4)

      VStack {
        Spacer()
        HStack(spacing: 0) {
          Rectangle().fill(isBusyMorning ? .red : .clear)
          Rectangle().fill(isBusyAfternoon ? .red : .clear)
          Rectangle().fill(isBusyEvening ? .red : .clear)
        }.frame(height: 3)
      }

      Text("\(dayOfMonth)")
        .bold()
        .font(.system(size: 9))
        .foregroundColor(Color("foreground"))
        .padding(1)
        .background(
          isToday ? AnyView(Color.gray.clipShape(Circle())) : AnyView(Color.clear))
    }
    .overlay(isPast ? Color(.black).opacity(0.5) : Color.clear)
    .overlay(isComplete ? Color("accent").opacity(0.6) : Color.clear)
  }
}
