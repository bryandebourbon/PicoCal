import Foundation
import WatchConnectivity

class Watch: NSObject, WCSessionDelegate {
  static let shared = Watch()
  var local: [Bool] = []

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
      debugPrint("WCSession not activated due to error: \(error.localizedDescription)")
    } else {
      debugPrint("WCSession activated with state: \(activationState.rawValue)")
    }
  }

  func sessionDidBecomeInactive(_ session: WCSession) {
    debugPrint("Session became inactive.")
  }

  func sessionDidDeactivate(_ session: WCSession) {
    debugPrint("Session deactivated.")
    WCSession.default.activate()
  }

  func send(data: [Bool]) {
    let session = WCSession.default

    guard session.isReachable else {
      debugPrint("Cannot send message. WCSession is not reachable.")
      return
    }

    let message = ["contributionDays": data]
    session.sendMessage(message, replyHandler: { reply in
      debugPrint("Received reply: \(reply)")
    }, errorHandler: { error in
      debugPrint("Error sending message: \(error.localizedDescription)")
    })
  }

}
