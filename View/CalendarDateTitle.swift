import SwiftUI

struct CalendarDateTitle: View {
  @Environment(\.scenePhase) private var scenePhase
  @State private var currentDateString: String = ""
  
  var dateFormatter: DateFormatter {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEEE MMMM dd yyyy"
    return formatter
  }
  
  var body: some View {
    Text(currentDateString)
      .bold()
      .font(.system(size: 11))
      .foregroundColor(Color("fontColor"))
      .frame(minHeight: 0)
      .onAppear {
        updateDate()
      }
      .onChange(of: scenePhase) { newPhase in
        if newPhase == .active {
          updateDate()
        }
      }
  }
  
  private func updateDate() {
    currentDateString = dateFormatter.string(from: Date()).uppercased()
  }
}

struct CalendarDateTitle_Previews: PreviewProvider {
  static var previews: some View {
    CalendarDateTitle()
  }
}

