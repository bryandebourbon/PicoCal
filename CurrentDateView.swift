import SwiftUI

struct CurrentDateView: View {
  // Date formatter
   var dateFormatter: DateFormatter {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEEE MMM dd yyyy"
    return formatter
  }

  // Current date
   var currentDate: String {
    dateFormatter.string(from: Date()).uppercased()
  }

  var body: some View {
    Text(currentDate)
      .bold()
      .font(.system(size: 16))
      .foregroundColor(Color("title")) // Make sure "foreground" color is defined in your asset catalog
      .frame(minHeight: 0)
  }
}

struct CurrentDateView_Previews: PreviewProvider {
  static var previews: some View {
    CurrentDateView()
  }
}


//january
//february
//march
//august
//september
//october
//november
//december
