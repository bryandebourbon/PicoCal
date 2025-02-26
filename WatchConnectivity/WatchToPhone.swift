import Foundation
import WatchConnectivity
import SwiftUI

class WatchToPhone: NSObject, WCSessionDelegate, ObservableObject {
    
    static let shared = WatchToPhone()
    @Published var local: [Bool] = []

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
      print("Session activation failed with error: \(error.localizedDescription)")
    } else {
      print("Session activated with state: \(activationState.rawValue)")
    }
  }



  // MARK: - Receiving a Message
  func session(_ session: WCSession,
               didReceiveMessage message: [String: Any],
               replyHandler: @escaping ([String: Any]) -> Void) {
    DispatchQueue.main.async { [weak self] in
      if let data = message["contributionDays"] as? [Bool] {
        self?.local = data
        print("Received message with data successfully.")
        replyHandler(["Response": "Data received"])
      } else {
        print("Received message does not contain expected data.")
        replyHandler(["Error": "Data format not recognized"])
      }
    }
  }

  // MARK: - Optional: Sending a Message Asynchronously from Watch → Phone
  func sendMessageAsync(data: [Bool]) async throws -> [String: Any] {
    let session = WCSession.default

    guard session.isReachable else {
      print("[WatchToPhone] Session not reachable.")
      throw WCSessionError.notReachable
    }

    let message = ["contributionDays": data]

    return try await withCheckedThrowingContinuation { continuation in
      session.sendMessage(
        message,
        replyHandler: { reply in
          print("[WatchToPhone] Received reply: \(reply)")
          continuation.resume(returning: reply)
        },
        errorHandler: { error in
          print("[WatchToPhone] Error sending message: \(error.localizedDescription)")
          continuation.resume(throwing: error)
        }
      )
    }
  }
}

/// Same error as used in PhoneToWatch
enum WCSessionError: Error {
  case notReachable
}

//extension WatchToPhone {
//    func requestHealthData() async throws -> [Bool] {
//        try await withCheckedThrowingContinuation { continuation in
//            WCSession.default.sendMessage(["request": "healthData"], replyHandler: { response in
//                if let data = response["healthData"] as? [Bool] {
//                    continuation.resume(returning: data)
//                } else {
//                    continuation.resume(throwing: NSError(domain: "HealthDataError", code: 0))
//                }
//            }, errorHandler: { error in
//                continuation.resume(throwing: error)
//            })
//        }
//    }
//}
//
//
//extension CentralViewModel {
//    func syncHealthDataFromPhone() async {
//        // Request health data from the phone
//        do {
//            let phoneHealthData = try await WatchToPhone.shared.requestHealthData()
//            self.healthFlags = phoneHealthData
//            print("[Watch] Synced health data from phone: \(phoneHealthData)")
//        } catch {
//            print("[Watch] Error syncing health data from phone: \(error)")
//        }
//    }
//    
//
//
//}
