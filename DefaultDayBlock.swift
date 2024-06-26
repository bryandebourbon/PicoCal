import SwiftUI

struct DefaultDayBlock: View {
  let dayOfMonth: Int
  let isToday: Bool
  let isPast: Bool
  let isComplete: Bool
  let isBusyMorning: Bool
  let isBusyAfternoon: Bool
  let isBusyEvening: Bool

  // Need support fort inverted color mode
  var body: some View {






    VStack(spacing:0){
      ZStack{
        (isToday ? Color("todayIndicator"): Color.clear).clipShape(Ellipse()).padding(2).opacity(0.6)
        Text("\(dayOfMonth)")
          .bold()
          .font(.system(size: 11))
          .foregroundColor(Color("fontColor"))
      }.offset(y:3)

      HStack(spacing:0)
      {
      isBusyMorning ? Color("busy") : Color.clear
      isBusyAfternoon ? Color("busy") : Color.clear
      isBusyEvening ? Color("busy") : Color.clear
      }.frame(height: 6)
    }



    .background((isComplete ? Color("goalComplete") : Color("default")).opacity(0.6))
  }
}



