import Foundation
import WatchConnectivity

class WatchToPhone: NSObject, WCSessionDelegate, ObservableObject {
  @Published var local: [Bool] = []

  override init() {
    super.init()
    if WCSession.isSupported() {
      debugPrint("WCSession is supported.")
      let session = WCSession.default
      session.delegate = self
      session.activate()
    } else {
      debugPrint("WCSession is not supported on this device.")
    }
  }

  func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    if let error = error {
      debugPrint("Session activation failed with error: \(error.localizedDescription)")
    } else {
      debugPrint("Session activated with state: \(activationState.rawValue)")
    }
  }

  func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
    DispatchQueue.main.async { [weak self] in
      if let data = message["contributionDays"] as? [Bool] {
        self?.local = data
        debugPrint("Received message with data successfully.")
        // Optionally, you can send back a reply if needed
        replyHandler(["Response": "Data received"])
      } else {
        debugPrint("Received message does not contain expected data.")
        replyHandler(["Error": "Data format not recognized"])
      }
    }
  }
}
