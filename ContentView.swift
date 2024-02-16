import EventKit
import HealthKit  // Import HealthKit
import SwiftUI
import WidgetKit  // Import WidgetKit for widget updates

struct ContentView: View {
  @StateObject var healthKitVM = HealthKitVM()
  @State var eventDays: [EventWrapper] = []
  @State var goalDays: [Bool] = []
  @State var hasContributionToday: Bool = false  // New state variable

 let store = SharedUserDefaults()

  let gitHubFetcher = GitHubDataFetcher()
  let eventKitFetcher = EventKitFetcher()

  @State var isLoading = false

  var body: some View {
   VStack {
    CurrentDateView()
    CalendarView(
     hasContributionToday: $hasContributionToday,
     eventDays: $eventDays,
     goalDays: $goalDays,
     calorieDays: $healthKitVM.calorieFlags
    )
    .frame(maxWidth: 180, maxHeight: 77)

   }
    .onAppear {
      eventKitFetcher.initializeEventStore { granted, events, error in
        if let events = events as? [EventWrapper] {
          self.eventDays = events
        } else if let error = error {
          print("An error occurred: \(error.localizedDescription)")
        }

      }
      healthKitVM.fetchCaloriesBurnedForCurrentMonth()
      gitHubFetcher.fetchContributionBooleans(accessToken: secrets["GitHub"]!) { result in
        switch result {
        case .success(let fetchedGoalDays):
          self.goalDays = fetchedGoalDays
          self.updateContributionStatus()
        case .failure(let error):
          print("Error fetching GitHub data: \(error)")
          self.goalDays = Array(repeating: false, count: 30)
          self.hasContributionToday = false
        }
       store.saveEvents(goalDays, calorieDays: healthKitVM.calorieFlags)
      }
    }
  }

  func updateContributionStatus() {
    print("goalDays", goalDays)
    hasContributionToday = goalDays.last ?? false
  }
//  func loadCalorieDataFromUserDefaults() {
//    let userDefaults = UserDefaults(suiteName: "group.com.bryandebourbon.shared")
//    if let savedCalories = userDefaults?.dictionary(forKey: "DailyCalorieData") as? [String: Double]
//    {
//      dailyCalories = savedCalories
//    }
//  }
}

#Preview{
  ContentView()
}
