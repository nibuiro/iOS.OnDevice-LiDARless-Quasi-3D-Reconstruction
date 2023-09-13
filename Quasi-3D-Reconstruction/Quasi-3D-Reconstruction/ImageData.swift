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
    var centerOfObjects: [SIMD2<Float>] = []
    var keypointsList: [[SIMD2<Float>]] = []
    var rotations: [SIMD3<Float>] = []
    var scales: [Float] = []
    
    
    var previousRecordedTimestamp : Int64 = 0
    var nSamples : Int = 0
    
    var isFixedCenterPosition : Bool = false
    var isConvertToRelativePositions : Bool = false
    var isConvertedToPolarCoordinates : Bool = false
    
    
    func append(image: CIImage,
                centerOfObject: SIMD2<Float>,
                keypoints: [SIMD2<Float>],
                rotation: SIMD3<Float>,
                scale: Float,
                timestamp: Int64)
    {
        let elapsedTime = timestamp - previousRecordedTimestamp
        //save image a second
        if 0 < elapsedTime {
            previousRecordedTimestamp = timestamp
            images.append(image)
            centerOfObjects.append(centerOfObject)
            keypointsList.append(keypoints)
            rotations.append(rotation)
            scales.append(scale)
            nSamples += 1
        }
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
