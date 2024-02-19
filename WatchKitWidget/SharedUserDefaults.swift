import Foundation

class SharedUserDefaults {
  static let shared = SharedUserDefaults()
  let userDefaults: UserDefaults?

  init() {
    userDefaults = UserDefaults(suiteName: "group.com.bryandebourbon.shared")
  }

  func getEnvironmentVariable(named name: String) -> String? {
    return ProcessInfo.processInfo.environment[name]
  }

  // Save eventDays, goalDays, and calorieDays
  func saveEvents(_  goalDays: [Bool], calorieDays: [Bool]) {
      userDefaults?.set(goalDays, forKey: "goalDays")
      userDefaults?.set(calorieDays, forKey: "calorieDays")
  }

  // Retrieve eventDays, goalDays, and calorieDays
  func retrieveEvents() -> ( [Bool], [Bool]) {

      let goalDays = userDefaults?.array(forKey: "goalDays") as? [Bool] ?? []
      let calorieDays = userDefaults?.array(forKey: "calorieDays") as? [Bool] ?? []
      return (goalDays, calorieDays)

  }
}
