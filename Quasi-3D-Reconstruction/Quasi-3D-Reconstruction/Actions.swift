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
    let referenceEulerAngles = camera.eulerAngles
    
    return {
        let rotate = simd_float3(camera.eulerAngles) - simd_float3(referenceEulerAngles)
        //print("rotate: ", rotate)
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
        let image : CIImage = imageData.images[i] // expect front of object
        let outlines : [VNContoursObservation] = extractObjectOutlines(image)
        let targetOutline = selectLongestPath(observations: outlines)
        let shape = SCNShape(path: UIBezierPath(cgPath: targetOutline), extrusionDepth:2.0)
        let mesh = MDLMesh(scnGeometry: shape)
        let asset = MDLAsset()
        asset.add(mesh)
        let voxelArray = MDLVoxelArray(asset: asset, divisions: 10, patchRadius: 0)
        let object = asset.object(at: 0)
        let node = SCNNode(mdlObject: object)
        let centerOfObject = imageData.centerOfObjects[i]
        let keypoints = imageData.keypointsList[i]
        var scale = 1 / imageData.scales[i]
        var translate = SIMD3<Float>(-(1-centerOfObject.x), -(1-centerOfObject.y), 0)
        print(scale)
        var rotate = imageData.rotations[i]
        rotate.x -= referenceRotation.x
        rotate.y -= referenceRotation.y
        rotate.z -= referenceRotation.z
        
        let R = simd_make_rotate3(x: rotate.x, y: rotate.y, z: rotate.z)
        var keylines: [[SIMD3<Float>]] = []
        for keypointIndex in 0..<5 {
            let keypoint = keypoints[keypointIndex] - (1 - centerOfObject)
            keylines.append([R * SIMD3<Float>(scale * keypoint.x, scale * keypoint.y, 1),
                             R * SIMD3<Float>(scale * keypoint.x, scale * keypoint.y, -1)])
        }
        
        
        switch i {
        case 0:
            for keylineIndex in 0..<5 {
                referenceKeylines.append(keylines[keylineIndex])
            }
        case 1:
            var maxA: Float = -Float.infinity
            var minA: Float = Float.infinity
            var argmaxA: Int = 0
            var argminA: Int = 0
            var referenceKeypointOnXYs: [SIMD3<Float>] = []
            var KeypointOnXYs: [SIMD3<Float>] = []
            for keylineIndex in 0..<5 {
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
                if minA < referenceKeypointOnXY.x {
                    minA = referenceKeypointOnXY.x
                    argminA = keylineIndex
                }
            }
            let scaleCorrectionValue: Float = (KeypointOnXYs[argmaxA].x - KeypointOnXYs[argminA].x) / (referenceKeypointOnXYs[argmaxA].x - referenceKeypointOnXYs[argminA].x)
            let shiftCorrectionVector = scale * (KeypointOnXYs[argmaxA] - referenceKeypointOnXYs[argmaxA])
            
            for keypointIndex in 0..<5 {
                keylines[keypointIndex] = [
                    scaleCorrectionValue * p0(keylines[keypointIndex]) + shiftCorrectionVector,
                    scaleCorrectionValue * p1(keylines[keypointIndex]) + shiftCorrectionVector
                ]
            }
            
            scale *= scaleCorrectionValue
            translate += shiftCorrectionVector
            
            for keypointIndex in 0..<5 {
                let n = normalize(p1(keylines[keypointIndex]) - p0(keylines[keypointIndex]))
                let a = SIMD3<Float>(0, 0, 0)
                let p = p0(referenceKeylines[keypointIndex])
                let d = p1(referenceKeylines[keypointIndex]) - p0(referenceKeylines[keypointIndex])
                let intersectionPoint = planeLineIntersection(n: n, a: a, p0: p, d: d)
                intersectionPoints.append(intersectionPoint)
            }
            
        default:
            break
        }
        ///*
        var transformedPolygon = rigidTransform3(mesh: node.geometry!,
                                                 translateX: translate.x, translateY: translate.y, translateZ: translate.z,
                                                 rotateX: rotate.x, rotateY: rotate.y, rotateZ: rotate.z,
                                                 scaleX: scale, scaleY: scale, scaleZ: scale,
                                                 minX: -1, maxX: 1, minY: -1, maxY: 1, minZ: -1, maxZ: 1,
                                                 translateFirst: true)
        //*/
        /*
        let polygon = Mesh(node.geometry!)?
            .translated(by: Vector(-Double(1-centerOfObject.x),-Double(1-centerOfObject.y),-1))
            .rotated(by: Rotation(pitch: Angle.degrees(2*Double.pi*Double(rotate.x)),
                                  yaw: Angle.degrees(2*Double.pi*Double(rotate.y)),
                                  roll: Angle.degrees(2*Double.pi*Double(rotate.z))))
        */
        
        exportMesh(transformedPolygon, withName: "polygon\(i)")
        if i == 10 {
            return transformedPolygon
        }
    }
    

    //let polygon = Mesh.extrude(targetOutline.paths(), depth: 2.0).translated(by: Vector(-Double(1.0-centerOfObject.x),-Double(1.0-centerOfObject.y),-1))
    //let polygon = Mesh(node.geometry!)?.translated(by: Vector(-Double(1-centerOfObject.x),-Double(1-centerOfObject.y),-1))
    //?.translated(by: Vector(-Double(centerOfObject.x),-Double(centerOfObject.y),-1))
    //generated2023-09-05 17/45/37.obj
    //
    //generated2023-09-05 17/48/07.obj
    //print(polygon!.objString())
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
