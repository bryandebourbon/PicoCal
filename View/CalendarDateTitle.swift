import SwiftUI

struct CalendarDateTitle: View {
  // Date formatter
   var dateFormatter: DateFormatter {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEE MMM dd yyyy"
    return formatter
  }

  // Current date
   var currentDate: String {
    dateFormatter.string(from: Date()).uppercased()
  }

  var body: some View {
    Text(currentDate)
      .bold()
      .font(.system(size: 12))
      .foregroundColor(Color("fontColor"))
      .frame(minHeight: 0)
  }
}

struct CalendarDateTitle_Previews: PreviewProvider {
  static var previews: some View {
    CalendarDateTitle()
  }
}

