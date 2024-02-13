import Foundation
import SwiftUI

struct LoadingBar: View {

  let total: CGFloat
  let caloriesToday: CGFloat
  var color: Color = Color(.red).opacity(0.5)

  var body: some View {

      GeometryReader { geometry in
        ZStack(alignment: .leading) {
          Rectangle().fill(Color.clear)
            .frame(width: geometry.size.width, height: 20)

          Rectangle().fill(color).opacity(0.5)
            .frame(width: (caloriesToday / total) * geometry.size.width, height: 20)
            .animation(.linear, value: caloriesToday)
        }

      }

  }
}
