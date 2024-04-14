import Foundation

class Store: NSObject, ObservableObject {
  static let shared = Store()
  @Published var local: [Bool] = []

  let userDefaults = UserDefaults(suiteName: "group.com.bryandebourbon.shared")
  
  func persist(data: [Bool], forKey: String) {
    userDefaults?.set(data, forKey: forKey)
  }
  
  func retrieve(forKey: String) -> [Bool] {
    return userDefaults?.array(forKey: forKey) as? [Bool] ?? []
  }


}
