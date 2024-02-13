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
    let sharedDefaults = UserDefaults(suiteName: "group.com.bryandebourbon.shared")
    if let encodedData = sharedDefaults?.data(forKey: "githubContributions"),
       let contributionDays = try? JSONDecoder().decode([ContributionDay].self, from: encodedData) {
      DispatchQueue.main.async {
        self.contributions = contributionDays.map{contributionDay in
          contributionDay.contributionCount > 0}

        }
      }
    }
  }

  private func storeContributionsInUserDefaults(_ contributionDays: [Bool]) {
    if let encodedData = try? JSONEncoder().encode(contributionDays) {
      UserDefaults(suiteName: "group.com.bryandebourbon.shared")?.set(encodedData, forKey: "githubContributions")
    }
  }

  private func fetchContributionsFromGitHub() {
    // Assume GitHubDataFetcher is your class that fetches data from GitHub
    // Implement fetching logic here, and update contributions accordingly

    let ghdf = GitHubDataFetcher()
    ghdf.fetchContributionBooleans(accessToken: secrets["GitHub"]!){ result in
      print("GHDF: \(result)")
    }


  }

  // Add any additional methods needed for your app's functionality

