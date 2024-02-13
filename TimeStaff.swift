import Foundation
import SwiftUI

struct TimeStaff: View {
  let isToday: Bool

  var body: some View {
    Spacer()
  }
}

struct EllipseWithStem: View {
  let distance: CGFloat
  let isHorizontal: Bool
  let stemHeight: CGFloat

  var body: some View {
    GeometryReader { geometry in

      ZStack {

        if !isHorizontal {
          Rectangle().fill(.black).opacity(0.3)
            .frame(
              width: stemHeight,
              height: 5)
          Rectangle()
            .fill(Color("today"))
            .frame(
              width: stemHeight,
              height: 2
            ).opacity(0.6)

        } else {
//          Rectangle().fill(.black).opacity(0.3)
//            .frame(
//              width: 5,
//              height: stemHeight)
//          Rectangle()
//            .fill(Color("today"))
//            .frame(
//              width: 2,
//              height: stemHeight
//            ).opacity(0.8)
        }

        if !isHorizontal {
          HStack(spacing: 0) {
            ZStack {
//              Circle().fill(.black).opacity(0.3)
//                .frame(height: 8)
//                .offset(x: -4)
//              Circle()
//                .fill(Color("today"))
//                .frame(width: 9, height: 9)
//                .offset(x: -4)
            }
            Spacer()
          }
        } else {
          VStack(spacing: 0) {
            ZStack {
              Circle().fill(.black)
                .frame(width: 10, height: 12)
                .offset(y: 0)
                .opacity(0.3)
                .shadow(color: .black, radius: 10)
//              Circle()
//                .fill(Color("today"))
//                .frame(
//                  width: 9,
//                  height: 9
//                )
//                .offset(y:-2)
//                .opacity(0.8)
            }
            Spacer()
          }
        }

      }
    }
  }
}
