import Foundation
import WidgetKit

class SharedUserDefaults {
  static let shared = SharedUserDefaults()
  let userDefaults: UserDefaults?


  init() {
    userDefaults = UserDefaults(suiteName: "group.com.bryandebourbon.shared")
  }

  func getEnvironmentVariable(named name: String) -> String? {
    return ProcessInfo.processInfo.environment[name]
  }




}
