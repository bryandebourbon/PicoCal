import Foundation
import WatchConnectivity

class PhoneToWatch: NSObject, WCSessionDelegate {
  static let shared = PhoneToWatch()
  var local: [Bool] = []

  override init() {
    super.init()
    if WCSession.isSupported() {
      print("WCSession is supported.")
      let session = WCSession.default
      session.delegate = self
      session.activate()
    } else {
      print("WCSession is not supported on this device.")
    }
  }

  // MARK: - WCSessionDelegate
  func session(_ session: WCSession,
               activationDidCompleteWith activationState: WCSessionActivationState,
               error: Error?) {
    if let error = error {
      print("WCSession not activated due to error: \(error.localizedDescription)")
    } else {
      print("WCSession activated with state: \(activationState.rawValue)")
    }
  }

  func sessionDidBecomeInactive(_ session: WCSession) {
    print("Session became inactive.")
  }

  func sessionDidDeactivate(_ session: WCSession) {
    print("Session deactivated.")
    WCSession.default.activate()
  }

  // MARK: - Async Send with Reply
  /// Sends data to the watch and awaits a reply. Throws if WCSession is not reachable or if an error occurs.
  func sendMessageAsync(data: [Bool]) async throws -> [String: Any] {
    let session = WCSession.default

    guard session.isReachable else {
      print("[PhoneToWatch] Cannot send message. WCSession is not reachable.")
      throw WCSessionError.notReachable
    }

    let message = ["contributionDays": data]

    return try await withCheckedThrowingContinuation { continuation in
      session.sendMessage(
        message,
        replyHandler: { reply in
          print("[PhoneToWatch] Received reply: \(reply)")
          continuation.resume(returning: reply)
        },
        errorHandler: { error in
          print("[PhoneToWatch] Error sending message: \(error.localizedDescription)")
          continuation.resume(throwing: error)
        }
      )
    }
  }

  // MARK: - Fire-and-Forget
  /// Old closure-based approach (no async/await). Use if you do not care about the reply.
  func send(data: [Bool]) {
    let session = WCSession.default

    guard session.isReachable else {
      print("Cannot send message. WCSession is not reachable.")
      return
    }

    let message = ["contributionDays": data]
    session.sendMessage(
      message,
      replyHandler: { reply in
        print("Received reply: \(reply)")
      },
      errorHandler: { error in
        print("Error sending message: \(error.localizedDescription)")
      }
    )
  }
}

func session(_ session: WCSession,
               didReceiveMessage message: [String : Any],
               replyHandler: @escaping ([String : Any]) -> Void) {
    // 1) Process the incoming data
    if let data = message["contributionDays"] as? [Bool] {
      print("[PhoneToWatch] Received data from watch: \(data)")

      // 2) Optionally store or merge the data
      Store.shared.local = data

      // 3) If you want, send a reply
      replyHandler(["Response": "Got it!"])
    } else {
      replyHandler(["Error": "Data format not recognized"])
    }
  }

// Custom error to signal a not reachable session
enum WCSessionError: Error {
  case notReachable
}
//
//extension PhoneToWatch {
//    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
//        if message["request"] as? String == "healthData" {
//            Task {
//                do {
//                    let healthData = DataManager.shared.store.local
//                    replyHandler(["healthData": healthData])
//                } catch {
//                    print("[Phone] Failed to fetch health data: \(error)")
//                    replyHandler(["error": "Failed to fetch health data"])
//                }
//            }
//        }
//    }
//}
