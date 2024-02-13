import Foundation

class GitHubDataFetcher {
   let session: URLSession

  init() {
    self.session = URLSession.shared
  }

  func fetchGitHubData(
    accessToken: String, completion: @escaping (Result<GitHubQueryResponse, Error>) -> Void
  ) {
    let calendar = Calendar.current
    let components = calendar.dateComponents([.year, .month], from: Date())
    let from = calendar.date(from: components)! // Start of the current month
    let to = Date()

    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]

    let fromDate = formatter.string(from: from)
    let toDate = formatter.string(from: to)

    let url = URL(string: "https://api.github.com/graphql")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

    let query = """
      query UserContributions {
          viewer {
              contributionsCollection(from: "\(fromDate)", to: "\(toDate)") {
                  contributionCalendar {
                      totalContributions
                      weeks {
                          contributionDays {
                              date
                              contributionCount
                          }
                      }
                  }
              }
          }
      }
      """

    let queryDict = ["query": query]
    if let httpBody = try? JSONSerialization.data(withJSONObject: queryDict) {
      request.httpBody = httpBody
    } else {
      // Handle error here
      //      print("ERROR")
    }

    let task = session.dataTask(with: request) { data, response, error in
      if let error = error {
        completion(.failure(error))
        return
      }

      guard let data = data else {
        completion(
          .failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data"])))
        return
      }

      if let json = String(data: data, encoding: .utf8) {
        print("Raw JSON response: \(json)")
      }

      do {
        let decodedResponse = try JSONDecoder().decode(GitHubQueryResponse.self, from: data)
        completion(.success(decodedResponse))
      } catch {
        // Print the decoding error
        print("Decoding error: \(error)")
        completion(.failure(error))
      }
    }

    task.resume()
  }

   func iso8601String(from date: Date) -> String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withFullDate]
    return formatter.string(from: date)
  }

}

struct GitHubQueryResponse: Codable {
  let data: ViewerData
}

struct ViewerData: Codable {
  let viewer: Viewer
}

struct Viewer: Codable {
  let contributionsCollection: ContributionsCollection
}

struct ContributionsCollection: Codable {
  let contributionCalendar: ContributionCalendar
}

struct ContributionCalendar: Codable {
  let totalContributions: Int
  let weeks: [Week]
}

struct Week: Codable {
  let contributionDays: [ContributionDay]
}

struct ContributionDay: Codable, Equatable {
  let date: String
  let contributionCount: Int
}

extension GitHubDataFetcher {
  func fetchContributionBooleans(
    accessToken: String,
    completion: @escaping (Result<[Bool], Error>) -> Void
  ) {
    fetchGitHubData(accessToken: accessToken) { result in
      switch result {
        case .success(let response):
          // Process the response to create boolean array
          let booleans = self.createBooleanArray(from: response.data.viewer.contributionsCollection)
          completion(.success(booleans))
        case .failure(let error):
          completion(.failure(error))
      }
    }
  }

   func createBooleanArray(from contributionsCollection: ContributionsCollection) -> [Bool] {
    var daysWithContributions: Set<String> = []

    for week in contributionsCollection.contributionCalendar.weeks {
      for day in week.contributionDays {
        if day.contributionCount > 0 {
          daysWithContributions.insert(day.date)
        }
      }
    }

    print("Days with contributions: \(daysWithContributions)")

    let calendar = Calendar.current
    let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: Date()))!
    let today = calendar.startOfDay(for: Date())
    let daysInMonth = calendar.dateComponents([.day], from: startOfMonth, to: today).day! + 1

    var booleans: [Bool] = []

    for dayOffset in 0..<daysInMonth {
      let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
      let dateString = iso8601String(from: date)
      let hasContribution = daysWithContributions.contains(dateString)
      booleans.append(hasContribution)

      print("Date: \(dateString), Has Contribution: \(hasContribution)")
    }

    print("Boolean array: \(booleans.reversed())")
    return booleans.reversed()
  }

}

