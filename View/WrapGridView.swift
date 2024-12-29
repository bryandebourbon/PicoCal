import HealthKit
import SwiftUI

struct WrapGridView: View {
  let items: [AnyView]
  let numberOfColumns: Int
  var numberOfRows: Int {
    (items.count + numberOfColumns - 1) 
    / numberOfColumns
  }

  var body: some View {
    GeometryReader { geometry in
      let blockWidth = (geometry.size.width ) / CGFloat(numberOfColumns)
      let blockHeight = (geometry.size.height + 10) / CGFloat(numberOfRows)

      VStack(alignment: .leading, spacing: 2) {
        ForEach(0..<numberOfRows, id: \.self) { rowIndex in
          HStack(spacing: 2) {
            ForEach(0..<numberOfColumns, id: \.self) { columnIndex in
              let index = rowIndex * numberOfColumns + columnIndex
              if index < items.count {
                items[index]
                  .frame(width: blockWidth, height: blockHeight)
                  .cornerRadius(2)
              } else {
                Spacer()
                  .frame(width: blockWidth, height: blockHeight)
              }
            }
          }
        }
      }
    }
  }
}
