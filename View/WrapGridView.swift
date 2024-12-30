import HealthKit
import SwiftUI

struct WrapGridView: View {
  let SPACING = 2.0
  let items: [AnyView]
  let numberOfColumns: Int

  var numberOfRows: Int {
    (items.count + numberOfColumns - 1) 
    / numberOfColumns
  }

  var body: some View {
    GeometryReader { geometry in
        let blockWidth = (geometry.size.width - SPACING*CGFloat(numberOfColumns)) / CGFloat(numberOfColumns)
      let blockHeight = (geometry.size.height - SPACING*CGFloat(numberOfRows)) / CGFloat(numberOfRows)

      VStack(alignment: .leading, spacing: SPACING) {
        ForEach(0..<numberOfRows, id: \.self) { rowIndex in
          HStack(spacing: SPACING) {
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
