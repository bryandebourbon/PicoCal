import SwiftUI

struct DefaultDayBlock: View {

  let dayOfMonth: Int
  let isToday: Bool
  let isPast: Bool
  let isComplete: Bool
  @Environment(\.calendar) var calendar

  var body: some View {
    ZStack {
      Color.gray.opacity(0.4)

      VStack {
        Spacer()
        HStack(spacing: 0) {
          Rectangle().fill(.red)
          Rectangle().fill(.red)
          Rectangle().fill(.clear)
        }.frame(height: 3)
      }

      Text("\(dayOfMonth)")
        .bold()
        .font(.system(size: 10))
        .foregroundColor(Color("foreground"))
        .background(
          isToday ? AnyView(Color.gray.clipShape(Circle())) : AnyView(Color.clear))

    }.overlay(isComplete ? Color("accent").opacity(0.8) : Color.clear)
      .overlay(isPast ? Color(.black).opacity(0.6) : Color.clear)
    //    .onAppear {
    //      print("Day of Month: \(dayOfMonth)")
    //      print("isToday: \(isToday)")
    //      print("isPast: \(isPast)")
    //      print("isComplete: \(isComplete)")
    //    }
  }
}
