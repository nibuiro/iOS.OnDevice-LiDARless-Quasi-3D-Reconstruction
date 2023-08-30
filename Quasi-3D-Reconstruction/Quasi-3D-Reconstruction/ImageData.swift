//
//  Record.swift
//  Quasi-3D-Reconstruction
//
//  Created by nibuiro on 2023/07/29.
//

import Foundation
import ARKit


class ImageData {
    
    enum State {
        case ready
        case scanning
        case finished
    }
    
    var images : [CIImage] = []
    var positions: [SIMD3<Float>] = []
    var relativePositions: [SIMD3<Float>] = []
    var previousRecordedTimestamp : Int64 = 0
    var centerPosition : SIMD3<Float> = SIMD3(0, 0, 0)
    var nSamples : Int = 0
    
    var isFixedCenterPosition : Bool = false
    var isConvertToRelativePositions : Bool = false
    var isConvertedToPolarCoordinates : Bool = false
    
    
    func append(position: SIMD3<Float>, image: CIImage, timestamp: Int64) {
        let elapsedTime = timestamp - previousRecordedTimestamp
        //save image a second
        if 0 < elapsedTime {
            previousRecordedTimestamp = timestamp
            positions.append(position)
            images.append(image)
            
            centerPosition += position
            nSamples += 1
        }
    }
    
    func fixCenterPosition() {
        centerPosition /= Float(nSamples)
        isFixedCenterPosition = true
    }
    

}


func convertToRelativePositions(_ positions:[SIMD3<Float>],
                                _ centerPosition:SIMD3<Float>) -> [SIMD3<Float>] {
    var relativePositions : [SIMD3<Float>] = []
    positions.forEach {
        relativePositions.append($0 - centerPosition)
    }
    return relativePositions
}

/*
func convertToPolarCoordinates(relativePositions:[SIMD3<Float>],
                               referenceCoodinate:SIMD3<Float>,
                               referenceLength:Float) -> [SIMD3<Float>] {
    
}
*/
