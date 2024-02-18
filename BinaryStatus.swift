import Foundation
import SwiftUI

struct BinaryStatus: View {
  let isToday: Bool
  let position: CGFloat
  @Binding var hasContributionToday: Bool // Use @Binding here

  var body: some View {
    GeometryReader { geometry in
      if isToday && hasContributionToday{
//        ZStack {
//          HStack {
            Rectangle()
              .fill(Color.green)
              .opacity(0.5)
//              .frame(width: position)
//            Spacer()
//          }
//        }
      }
    }
  }
}
