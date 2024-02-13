import Foundation
import SwiftUI

struct BinaryStatus: View {
  let isToday: Bool
  let position: CGFloat
  @Binding var hasContributionToday: Bool // Use @Binding here

  var body: some View {
    GeometryReader { geometry in
      if isToday {
        ZStack {
          HStack {
            Rectangle().fill(Color.black)
              .opacity(0.2).frame(width: position)
            Spacer()
          }
        }
      }
      // If there is additional logic for the else case, add it here
    }
  }
}
