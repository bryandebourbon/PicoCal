import SwiftUI

struct DefaultDayBlock: View {
  let dayOfMonth: Int
  let isToday: Bool
  let isPast: Bool
  let isComplete: Bool
  let isBusyMorning: Bool
  let isBusyAfternoon: Bool
  let isBusyEvening: Bool
    
let DATE_TITLE_HEIGHT: CGFloat = 11
    let WatchWidgetBusyHeight: CGFloat = 2

  // Need support fort inverted color mode
  var body: some View {
    VStack(spacing:0){
      ZStack{
        (isToday ? Color("todayIndicator"): Color.clear).clipShape(Ellipse()).padding(2).opacity(0.6)
        Text("\(dayOfMonth)")
          .bold()
          .font(.system(size: DATE_TITLE_HEIGHT))
          .foregroundColor(Color("fontColor"))
      }.frame(height: DATE_TITLE_HEIGHT - WatchWidgetBusyHeight)

      HStack(spacing:0)
      {
      isBusyMorning ? Color("busy") : Color.clear
      isBusyAfternoon ? Color("busy") : Color.clear
      isBusyEvening ? Color("busy") : Color.clear
      }
     
    }



    .background((isComplete ? Color("goalComplete") : Color("default")).opacity(0.6))
  }
}



