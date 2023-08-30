import CoreGraphics

extension CGPath {

  /// this is a computed property, it will hold the points we want to extract
  var numberOfPoints: Int {

     /// this is a local transient container where we will store our CGPoints
     var count: Int = 0

     // applyWithBlock lets us examine each element of the CGPath, and decide what to do
     self.applyWithBlock { element in

        switch element.pointee.type
        {
        case .moveToPoint, .addLineToPoint:
          count += 1

        case .addQuadCurveToPoint:
            count += 1
            count += 1
        case .addCurveToPoint:
            count += 1
            count += 1
            count += 1

        default:
          break
        }
     }

    // We are now done collecting our CGPoints and so we can return the result
      return count

  }
}

