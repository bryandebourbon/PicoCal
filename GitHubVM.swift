import Foundation
import Combine

class GitHubVM: ObservableObject {
  @Published var contributions: [Bool] = []
  private var cancellables = Set<AnyCancellable>()

  init() {
    loadContributions()
  }

  func loadContributions() {
    loadContributionsFromUserDefaults()
    fetchContributionsFromGitHub()
  }

  private func loadContributionsFromUserDefaults() {
    // Utilize SharedUserDefaults instead of direct UserDefaults access
    if let contributionDays = SharedUserDefaults.shared.retrieveContributions() {
      DispatchQueue.main.async {
        self.contributions = contributionDays
      }
    }
  }

  private func storeContributionsInUserDefaults(_ contributionDays: [Bool]) {
    // Utilize SharedUserDefaults for storing the contributions
    SharedUserDefaults.shared.saveContributions(contributionDays)
  }

  private func fetchContributionsFromGitHub() {
    // Implementation remains the same, adjust as necessary for your fetching logic
//    let ghdf = GitHubDataFetcher()
//    ghdf.fetchContributionBooleans(accessToken: secrets["GitHub"] ?? "") { [weak self] result in
//      // Assuming result is the [Bool] array representing contributions
//      DispatchQueue.main.async {
//        switch result {
//          case .success(let success):
//            self?.contributions = success
//            self?.storeContributionsInUserDefaults(success)
//          case .failure(let failure):
//            self?.contributions =  []
//            print(failure)
//        }
//      }
//    }
  }

  // You would need to adjust your SharedUserDefaults class to include:
  // - saveContributions(_ contributionDays: [Bool])
  // - retrieveContributions() -> [Bool]?
}


extension SharedUserDefaults {

  func saveContributions(_ contributionDays: [Bool]) {
    if let encodedData = try? JSONEncoder().encode(contributionDays) {
      userDefaults?.set(encodedData, forKey: "githubContributions")
    }
  }

  func retrieveContributions() -> [Bool]? {
    if let encodedData = userDefaults?.data(forKey: "githubContributions"),
       let contributionDays = try? JSONDecoder().decode([Bool].self, from: encodedData) {
      return contributionDays
    }
    return nil
  }
}






