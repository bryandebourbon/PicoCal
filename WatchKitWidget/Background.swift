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
    // Prepare data for the watch
    fetchData { success, data in
      if success, let data = data {
        // Send data to the watch
        PhoneToWatch.shared.send(data: data)
      }
      task.setTaskCompleted(success: success)
    }

    task.expirationHandler = {
      task.setTaskCompleted(success: false)
    }
  }

  private static func fetchData(completion: @escaping (Bool, [Bool]?) -> Void) {
    // Simulate data fetching
    let fetchedData = [true, false, true] // Example data
    completion(true, fetchedData)
  }
}
