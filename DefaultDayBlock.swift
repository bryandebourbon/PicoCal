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

      Text("\(dayOfMonth)")
        .bold()
        .font(.system(size: 11))
        .foregroundColor(.white)
//        .padding(1)
        .shadow(color: .black.opacity(0.4), radius: 2)

    }
    .overlay(isPast ? Color(.black).opacity(0.5) : Color.clear)
    .background(
      isToday ? AnyView(Color.red.clipShape(Ellipse()).padding(3)) : AnyView(Color.clear)
    )
    .background(isComplete ? Color("accent").opacity(0.6) : Color.clear)
  }
}
