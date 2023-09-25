//
//  Actions.swift
//  Quasi-3D-Reconstruction
//
//  Created by nibuiro on 2023/07/29.
//

/*
クラスを管理するためのなんちゃってクラスをやめましょう。
golangのようにDIで書いていくスタイルでいきましょう。簡潔なコードに必要なシンプルさです。
果たして、利用する側にとって最適な関数名であった場合、異なるライブラリで名前が衝突することなどあり得るのでしょうか？
*/

import Foundation
import simd
import ARKit
import CoreImage
import CoreImage.CIFilterBuiltins
import Euclid
import Metal
import MetalKit

func setupScaleMesure(sceneView: ARSCNView, referencePosition: SIMD3<Float>) -> () -> Float {
    
    guard let camera = sceneView.pointOfView else { abort() }
    
    let left = SIMD3<Float>(0.05, 0.05 ,0.05)
    
    let measure = (simd_float3(sceneView.projectPoint(SCNVector3(referencePosition))) - simd_float3(sceneView.projectPoint(SCNVector3(referencePosition + left))))
    let referenceLength = length(simd_make_float2(measure.x, measure.y))
    let referenceEulerAngles = simd_float3(camera.eulerAngles)
    
    return {
        let rotate = simd_float3(camera.eulerAngles)
        let R = simd_make_rotate3(x: rotate.x, y: rotate.y, z: rotate.z)
        //print("rotated left", R * left)
        let measure = simd_float3(sceneView.projectPoint(SCNVector3(referencePosition))) - simd_float3(sceneView.projectPoint(SCNVector3(referencePosition + R * left)))
        let currentLength = length(simd_make_float2(measure.x, measure.y))
        
        let currentScale = currentLength / referenceLength
        return currentScale
    }
}

let deg2rad = (Float.pi * 2) / 360
/*
 ,
                                  fieldOfView: Float,
                                  explicitCenterPosition: SIMD3<Float>,
                                  useExplicitCenterPosition: Bool
 */
                            
func makeGenerallyAccurate3dMesh(imageData :ImageData) -> SCNGeometry {
    //let centerPosition = useExplicitCenterPosition ? explicitCenterPosition : imageData.centerPosition
    //let relativePositions : [SIMD3<Float>] = convertToRelativePositions(imageData.positions, imageData.centerPosition)
    //let referenceCoodinate : SIMD3<Float> = relativePositions[0]
    //let referenceLength : Float = simd.length(referenceCoodinate)
    
    //let referenceFrustumHeight = 2.0 * referenceLength * tan(fieldOfView * 0.5 * deg2rad);
    let p0 = { (arr: [SIMD3<Float>]) -> SIMD3<Float> in arr[0] }
    let p1 = { (arr: [SIMD3<Float>]) -> SIMD3<Float> in arr[1] }
    
    let extractObjectOutlines = setupExtractObjectOutlines()
    let referenceRotation = imageData.rotations[0]
    //
    var referenceKeylines: [[SIMD3<Float>]] = []
    var intersectionPoints: [SIMD3<Float>] = []
    
    for i in 0..<imageData.nSamples {
        let image : CIImage = imageData.images[i]
        let targetOutline = selectLongestPath(observations: extractObjectOutlines(image))
        let shape = SCNShape(path: UIBezierPath(cgPath: targetOutline), extrusionDepth:2.0)
        let mesh = MDLMesh(scnGeometry: shape)
        let asset = MDLAsset()
        asset.add(mesh)
        let voxelArray = MDLVoxelArray(asset: asset, divisions: 10, patchRadius: 0)
        let object = asset.object(at: 0)
        let node = SCNNode(mdlObject: object)
        let centerOfObject = imageData.centerOfObjects[i]
        let keypoints = imageData.keypointsList[i]
        var scale: Float = 1.0 // imageData.scales[i]
        var translate = SIMD3<Float>(-(1-centerOfObject.x), -(1-centerOfObject.y), 0)
        var rotate = imageData.rotations[i]
        rotate.x = (rotate.x - referenceRotation.x)
        rotate.y = (rotate.y - referenceRotation.y)
        rotate.z = (rotate.z - referenceRotation.z)
        
        let R = simd_make_rotate3(x: rotate.x, y: rotate.y, z: rotate.z)
        var keylines: [[SIMD3<Float>]] = []
        for keypointIndex in 0..<3 {
            let keypoint = keypoints[keypointIndex] - (1 - centerOfObject)
            keylines.append([R * SIMD3<Float>(keypoint.x, keypoint.y, 1),
                             R * SIMD3<Float>(keypoint.x, keypoint.y, -1)])
        }
        
        var transformedPolygon0 = rigidTransform3(mesh: node.geometry!,
                                                 translateX: translate.x, translateY: translate.y, translateZ: translate.z,
                                                 rotateX: rotate.x, rotateY: rotate.y, rotateZ: rotate.z,
                                                 scaleX: 1, scaleY: 1, scaleZ: 1,
                                                 minX: -1, maxX: 1, minY: -1, maxY: 1, minZ: -1, maxZ: 1,
                                                 translateFirst: true)
        
        print("transformedPolygon0", translate, rotate)
        
        
        switch i {
        case 0:
            for keylineIndex in 0..<3 {
                referenceKeylines.append(keylines[keylineIndex])
            }
            
            exportMesh(transformedPolygon0, withName: "polygon\(i)")
        case 1:
            print("start: 1")
            var maxA: Float = -Float.infinity
            var minA: Float = Float.infinity
            var argmaxA: Int = 0
            var argminA: Int = 0
            var referenceKeypointOnXYs: [SIMD3<Float>] = []
            var KeypointOnXYs: [SIMD3<Float>] = []
            for keylineIndex in 0..<3 {
                let KeypointOnXY = calcPointAtTargetZOnTheLineThrough2Points(p0: p0(keylines[keylineIndex]),
                                                                 p1: p1(keylines[keylineIndex]),
                                                                 targetZ: 0)
                KeypointOnXYs.append(KeypointOnXY)
                
                let referenceKeypointOnXY = calcPointAtTargetZOnTheLineThrough2Points(p0: p0(referenceKeylines[keylineIndex]),
                                                                 p1: p1(referenceKeylines[keylineIndex]),
                                                                 targetZ: 0)
                referenceKeypointOnXYs.append(referenceKeypointOnXY)
                if maxA < referenceKeypointOnXY.x {
                    maxA = referenceKeypointOnXY.x
                    argmaxA = keylineIndex
                }
                if minA > referenceKeypointOnXY.x {
                    minA = referenceKeypointOnXY.x
                    argminA = keylineIndex
                }
            }
            let scaleCorrectionValue: Float = abs(referenceKeypointOnXYs[1].x - referenceKeypointOnXYs[2].x) /  abs(KeypointOnXYs[1].x - KeypointOnXYs[2].x)
            let shiftCorrectionVector = -(scaleCorrectionValue * KeypointOnXYs[0] - referenceKeypointOnXYs[0])
            
            for keypointIndex in 0..<3 {
                keylines[keypointIndex] = [
                    scaleCorrectionValue * p0(keylines[keypointIndex]) + shiftCorrectionVector,
                    scaleCorrectionValue * p1(keylines[keypointIndex]) + shiftCorrectionVector
                ]
            }
            
            for keypointIndex in 0..<3 {
                let n = normalize(p1(keylines[keypointIndex]) - p0(keylines[keypointIndex]))
                let a = SIMD3<Float>(0, 0, 0)
                let p = p0(referenceKeylines[keypointIndex])
                let d = p1(referenceKeylines[keypointIndex]) - p0(referenceKeylines[keypointIndex])
                let intersectionPoint = planeLineIntersection(n: n, a: a, p0: p, d: d)
                print(intersectionPoint)
                intersectionPoints.append(intersectionPoint)
            }
            
            var transformedPolygon = rigidTransform3(mesh: transformedPolygon0,
                                                     translateX: shiftCorrectionVector.x,
                                                     translateY: shiftCorrectionVector.y,
                                                     translateZ: shiftCorrectionVector.z,
                                                     rotateX: 0, rotateY: 0, rotateZ: 0,
                                                     scaleX: scaleCorrectionValue,
                                                     scaleY: scaleCorrectionValue,
                                                     scaleZ: scaleCorrectionValue,
                                                     minX: -1, maxX: 1, minY: -1, maxY: 1, minZ: -1, maxZ: 1,
                                                     translateFirst: true)
            
            exportMesh(transformedPolygon, withName: "polygon\(i)")
        default:
            print("default", i)
            // scale correction stage
            let footOfPerpendicular = calcPointToLineOrthogonalIntersectionPoint(
                d: (p1(keylines[1]) - p0(keylines[1])),
                A0: p0(keylines[1]),
                pointP: intersectionPoints[1]
            )
            
            let orthVector = footOfPerpendicular - intersectionPoints[1]
            //selfAnchor := footOfPerpendicular
            let selfAnotherAnchor = planeLineIntersection(n: normalize(orthVector),
                                  a: (p0(keylines[0]) + p1(keylines[0])) / 2,
                                  p0: footOfPerpendicular,
                                  d: normalize(orthVector))
            let currentScale = length(selfAnotherAnchor - footOfPerpendicular)
            
            //interSectionAnchor := intersectionPoints[1]
            let anotherIntersectionAnchor = planeLineIntersection(n: normalize(orthVector),
                                  a: intersectionPoints[0],
                                  p0: intersectionPoints[1],
                                  d: normalize(orthVector))
            let targetScale = length(anotherIntersectionAnchor - intersectionPoints[1])
            
            let scaleCorrectionValue = targetScale / currentScale
            
            for keylineIndex in 0..<3 {
                keylines[keylineIndex][0] *= scaleCorrectionValue
                keylines[keylineIndex][1] *= scaleCorrectionValue
            }
            
            // shift correction stage
            let shiftCorrectionVector = -calcPointToLineOrthogonalVector(
                d: (p1(keylines[0]) - p0(keylines[0])),
                A0: p0(keylines[0]),
                pointP: intersectionPoints[0]
            )
            
            for keylineIndex in 0..<3 {
                keylines[keylineIndex][0] += shiftCorrectionVector
                keylines[keylineIndex][1] += shiftCorrectionVector
            }
            
            var transformedPolygon = rigidTransform3(mesh: transformedPolygon0,
                                                     translateX: shiftCorrectionVector.x,
                                                     translateY: shiftCorrectionVector.y,
                                                     translateZ: shiftCorrectionVector.z,
                                                     rotateX: 0, rotateY: 0, rotateZ: 0,
                                                     scaleX: scaleCorrectionValue,
                                                     scaleY: scaleCorrectionValue,
                                                     scaleZ: scaleCorrectionValue,
                                                     minX: -1, maxX: 1, minY: -1, maxY: 1, minZ: -1, maxZ: 1,
                                                     translateFirst: true)
            
            exportMesh(transformedPolygon, withName: "polygon\(i)")
        }
        
        
    }
    
    return SCNGeometry()
}



func calcPointAtTargetZOnTheLineThrough2Points(p0: SIMD3<Float>, p1: SIMD3<Float>, targetZ: Float) -> SIMD3<Float> {
    // XY平面
    let v = p1 - p0
    let t = (targetZ - p0.z) / v.z
    let x = p0.x + t * v.x
    let y = p0.y + t * v.y
    let point = SIMD3<Float>(x, y, targetZ)
    
    return point
}


func planeLineIntersection(n: SIMD3<Float>, a: SIMD3<Float>, p0: SIMD3<Float>, d: SIMD3<Float>) -> SIMD3<Float> {
    let nDotD = simd_dot(n, d)
    
    // normal vector and line are orthonal
    if nDotD == 0 {
        return SIMD3<Float>(0,0,0)
    }
    
    let t = simd_dot(n, a - p0) / nDotD
    
    let intersectionPoint = p0 + t * d
    
    return intersectionPoint
}


func calcPointToLineOrthogonalIntersectionPoint(d: SIMD3<Float>, A0: SIMD3<Float>, pointP: SIMD3<Float>) -> SIMD3<Float> {

    let v = pointP - A0
    // projection
    let proj_v_d = simd_dot(d, v) / length(d)**2 * d
    let footOfPerpendicular = A0 + proj_v_d
    
    return footOfPerpendicular
}

func calcPointToLineOrthogonalVector(d: SIMD3<Float>, A0: SIMD3<Float>, pointP: SIMD3<Float>) -> SIMD3<Float> {

    let v = pointP - A0
    // projection
    let proj_v_d = simd_dot(d, v) / pow(length(d),2) * d
    let footOfPerpendicular = A0 + proj_v_d
    let OrthogonalProjectedVector = footOfPerpendicular - pointP
    
    return OrthogonalProjectedVector
}

