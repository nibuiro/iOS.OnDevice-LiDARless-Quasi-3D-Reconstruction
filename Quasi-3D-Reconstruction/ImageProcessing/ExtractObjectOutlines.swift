//
//  File.swift
//  Quasi-3D-Reconstruction
//
//  Created by user01 on 2023/08/08.
//

import Foundation

import simd
import ARKit
import CoreImage
import CoreImage.CIFilterBuiltins


func setupExtractObjectOutlines() -> (CIImage) -> [VNContoursObservation] {
    
    var pred : CVPixelBuffer?
    
    // func setupVisionModel {
    guard let model = try? VNCoreMLModel(for: u2net(configuration: MLModelConfiguration()).model) else { fatalError("model initialization failed") }
    
    let visonRequest = VNCoreMLRequest(model: model) { request, error in
        guard let result = request.results?.first as? VNPixelBufferObservation else { return }
        pred = result.pixelBuffer
    }
    // }
    let ciFilter = CIFilter(name: "CIColorThreshold")
    ciFilter?.setValue(0.1, forKey: "inputThreshold")
    
    let contourRequest = VNDetectContoursRequest.init()
    contourRequest.revision = VNDetectContourRequestRevision1
    contourRequest.contrastAdjustment = 1.0
    contourRequest.detectsDarkOnLight = false
    
    return { sourceImage in
        let handler = VNImageRequestHandler(ciImage: sourceImage, options: [:])
        try? handler.perform([visonRequest])
            
        let ciImage : CIImage = CIImage(cvPixelBuffer: pred!, options: [:])//.resizeAffine(scaleX: 5, scaleY: 1)!
        ciFilter?.setValue(ciImage, forKey: kCIInputImageKey)
    
        let requestHandler = VNImageRequestHandler.init(ciImage: (ciFilter?.outputImage)!, options: [:])
    
        try? requestHandler.perform([contourRequest])
        
        return contourRequest.results!
    }
}

func selectLongestPath(observations:[VNContoursObservation]) -> CGPath {
    /*
     length := number of points of CGPath
     */
    var longestPathLength = 0
    var longestPath: CGPath = observations[0].topLevelContours[0].normalizedPath
    observations.forEach { observation in
        observation.topLevelContours.forEach { counter in
            let length = counter.normalizedPath.numberOfPoints
            if length > longestPathLength {
                longestPathLength = length
                longestPath = counter.normalizedPath
            }
        }
    }
    return longestPath
}

func extractPoints(from path: CGPath) -> [CGPoint] {
    var points: [CGPoint] = []

    path.applyWithBlock { element in
        switch element.pointee.type {
        case .moveToPoint, .addLineToPoint:
            let point = element.pointee.points[0]
            points.append(point)
        case .addQuadCurveToPoint:
            let controlPoint = element.pointee.points[0]
            let endPoint = element.pointee.points[1]
            // You might want to interpolate more points along the quadratic curve
            points.append(controlPoint)
            points.append(endPoint)
        case .addCurveToPoint:
            let controlPoint1 = element.pointee.points[0]
            let controlPoint2 = element.pointee.points[1]
            let endPoint = element.pointee.points[2]
            // You might want to interpolate more points along the cubic curve
            points.append(controlPoint1)
            points.append(controlPoint2)
            points.append(endPoint)
        default:
            break
        }
    }

    return points
}
