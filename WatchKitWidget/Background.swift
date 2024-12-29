import BackgroundTasks
import UIKit


class AppDelegate: UIResponder, UIApplicationDelegate {
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    // Register background tasks here
    BackgroundScheduler.registerBackgroundTasks()
    return true
  }

  func applicationDidEnterBackground(_ application: UIApplication) {
    // Schedule the background tasks here
    BackgroundScheduler.scheduleAppRefresh()
  }
}

class BackgroundScheduler {
  static func registerBackgroundTasks() {
    BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.bryandebourbon.PicoCal.refresh", using: nil) { task in
      self.handleAppRefresh(task: task as! BGAppRefreshTask)
    }
  }

  static func scheduleAppRefresh() {
    let request = BGAppRefreshTaskRequest(identifier: "com.bryandebourbon.PicoCal.refresh")
    request.earliestBeginDate = Date(timeIntervalSinceNow: 1 * 60 * 60) // Fetch hourly
    do {
      try BGTaskScheduler.shared.submit(request)
    } catch {
      print("Could not schedule app refresh: \(error)")
    }
  }
    private static func handleAppRefresh(task: BGAppRefreshTask) {
      // 1) Set up the expiration handler early
      task.expirationHandler = {
        task.setTaskCompleted(success: false)
      }

      // 2) Convert to async by launching a Task
      Task {
        do {
          let data = try await fetchDataAsync() // An async version of fetchData
          // Now “send data to the watch”
          PhoneToWatch.shared.send(data: data)
          task.setTaskCompleted(success: true)
        } catch {
          print("[Background] Error fetching data: \(error)")
          task.setTaskCompleted(success: false)
        }
      }
    }

    /// Example: an async version of fetchData
    private static func fetchDataAsync() async throws -> [Bool] {
      // Simulate data fetching with a continuation
      try await withCheckedThrowingContinuation { continuation in
        // Existing synchronous or callback-based logic
        let fetchedData = [true, false, true]
        // e.g., if no error condition, resume returning
        continuation.resume(returning: fetchedData)
      }
    }


  private static func fetchData(completion: @escaping (Bool, [Bool]?) -> Void) {
    // Simulate data fetching
    let fetchedData = [true, false, true] // Example data
    completion(true, fetchedData)
  }
}
