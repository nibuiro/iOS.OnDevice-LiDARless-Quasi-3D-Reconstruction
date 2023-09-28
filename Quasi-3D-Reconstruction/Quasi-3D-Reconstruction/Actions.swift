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
    
    var pointCloud: [Int8] = Array<Int8>(repeating: 0, count: 128*128*128)
    
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
        rotate.x = -(rotate.x - referenceRotation.x)
        rotate.y = (rotate.y - referenceRotation.y)
        rotate.z = (rotate.z - referenceRotation.z)
        
        let R = simd_make_rotate3(x: rotate.x, y: rotate.y, z: rotate.z)
        var keylines: [[SIMD3<Float>]] = []
        for keypointIndex in 0..<3 {
            let keypoint = (1 - keypoints[keypointIndex]) - (1 - centerOfObject)
            keylines.append([R * SIMD3<Float>(keypoint.x, keypoint.y, 1),
                             R * SIMD3<Float>(keypoint.x, keypoint.y, -1)])
        }
        
        var transformedPolygon0 = rigidTransform3(mesh: node.geometry!,
                                                 translateX: translate.x, translateY: translate.y, translateZ: translate.z,
                                                 rotateX: rotate.x, rotateY: rotate.y, rotateZ: rotate.z,
                                                 scaleX: 1, scaleY: 1, scaleZ: 1,
                                                  doClip: true,
                                                  minX: -0.5, maxX: 0.5,
                                                  minY: -0.5, maxY: 0.5,
                                                  minZ: -0.5, maxZ: 0.5,
                                                  d: p1(keylines[0]) - p0(keylines[0]))
        
        print("transformedPolygon0", translate, rotate)
        
        
        switch i {
        case 0:
            for keylineIndex in 0..<3 {
                referenceKeylines.append(keylines[keylineIndex])
            }
            
            exportMesh(transformedPolygon0, withName: "polygon\(i)")
            /*
            let voxelIndices = geometryToVoxelIndices(inp: transformedPolygon0)
            let xs = voxelIndices.x
            let ys = voxelIndices.y
            let zs = voxelIndices.z
            for voxelIndex in 0..<xs.count {
                let pointCloudIndex: Int = Int(xs[voxelIndex]) + 128 * Int(ys[voxelIndex]) + 16384 * Int(zs[voxelIndex])
                pointCloud[Int(pointCloudIndex)] += 1
            }*/
            
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
            let scaleCorrectionValue: Float = Float(1.0)//abs(referenceKeypointOnXYs[1].x - referenceKeypointOnXYs[2].x) /  abs(KeypointOnXYs[1].x - KeypointOnXYs[2].x)
            let shiftCorrectionVector = -(scaleCorrectionValue * KeypointOnXYs[0] - referenceKeypointOnXYs[0])
            
            for keypointIndex in 0..<3 {
                keylines[keypointIndex] = [
                    scaleCorrectionValue * p0(keylines[keypointIndex]) + shiftCorrectionVector,
                    scaleCorrectionValue * p1(keylines[keypointIndex]) + shiftCorrectionVector
                ]
            }
            
            var vertices: [Vertex] = []
            
            for keypointIndex in 0..<3 {
                let d = p1(referenceKeylines[keypointIndex]) - p0(referenceKeylines[keypointIndex])
                
                let pointA = Point2<Float>(p0(keylines[keypointIndex]).z,
                                           p0(keylines[keypointIndex]).y)
                let pointB = Point2<Float>(p1(keylines[keypointIndex]).z,
                                           p1(keylines[keypointIndex]).y)
                let pointC = Point2<Float>(p0(referenceKeylines[keypointIndex]).z,
                                           p0(referenceKeylines[keypointIndex]).y)
                let pointD = Point2<Float>(p1(referenceKeylines[keypointIndex]).z,
                                           p1(referenceKeylines[keypointIndex]).y)
                print(pointA, pointB, pointC, pointD)
                let intersectionPointYZ = calcIntersectionPointFromPointPairs2(A: pointA,
                                                                               B: pointB,
                                                                               C: pointC,
                                                                               D: pointD)
                
                let intersectionPoint = calcPointAtTargetZOnTheLineThroughPoint03(
                    p0: p0(referenceKeylines[keypointIndex]),
                    v: d,
                    targetZ: intersectionPointYZ.x
                )
                
                print("intersectionPoint: ", intersectionPoint)
                intersectionPoints.append(intersectionPoint)
                vertices.append(Vertex(Vector(Double(intersectionPoint.x),
                                              Double(intersectionPoint.y),
                                              Double(intersectionPoint.z))))
            }
            exportMesh(SCNGeometry(Mesh([Polygon(vertices)!])), withName: "intersectionPoints")
            
            var transformedPolygon = rigidTransform3(mesh: transformedPolygon0,
                                                     translateX: shiftCorrectionVector.x,
                                                     translateY: shiftCorrectionVector.y,
                                                     translateZ: shiftCorrectionVector.z,
                                                     rotateX: 0, rotateY: 0, rotateZ: 0,
                                                     scaleX: scaleCorrectionValue,
                                                     scaleY: scaleCorrectionValue,
                                                     scaleZ: scaleCorrectionValue,
                                                     doClip: true,
                                                     minX: -0.5, maxX: 0.5,
                                                     minY: -0.5, maxY: 0.5,
                                                     minZ: -0.5, maxZ: 0.5,
                                                     d: p1(keylines[0]) - p0(keylines[0]))
            
            exportMesh(transformedPolygon, withName: "polygon\(i)")
            /*
            let voxelIndices = geometryToVoxelIndices(inp: transformedPolygon)
            let xs = voxelIndices.x
            let ys = voxelIndices.y
            let zs = voxelIndices.z
            for voxelIndex in 0..<xs.count {
                let pointCloudIndex: UInt32 = xs[voxelIndex] + 128 * ys[voxelIndex] + 16384 * zs[voxelIndex]
                pointCloud[Int(pointCloudIndex)] += 1
            }
             */
        default:
            print("default", i)
            // scale correction stage
            let sourceAnchor0 = (p0(keylines[0]) + p1(keylines[0])) / 2
            let sourceAnchor1 = calcPointToLineOrthogonalIntersectionPoint(
                d: (p1(keylines[1]) - p0(keylines[1])),
                A0: p0(keylines[1]),
                pointP: sourceAnchor0)
            
            let targetAnchor0 = intersectionPoints[0]
            let targetAnchor1 = calcPointToLineOrthogonalIntersectionPoint(
                d: (p1(keylines[1]) - p0(keylines[1])),
                A0: intersectionPoints[1],
                pointP: targetAnchor0)
            
            let sourceScale = length(sourceAnchor1 - sourceAnchor0)
            let targetScale = length(targetAnchor1 - targetAnchor0)
            
            let scaleCorrectionValue = targetScale / sourceScale
            
            for keylineIndex in 0..<3 {
                keylines[keylineIndex][0] *= scaleCorrectionValue
                keylines[keylineIndex][1] *= scaleCorrectionValue
            }
            
            // shift correction stage
            let centerOfKeyline0 = (p1(keylines[0]) + p0(keylines[0])) / 2
            let centerOfKeyline1 = (p1(keylines[1]) + p0(keylines[1])) / 2
            let centerOfKeyline2 = (p1(keylines[2]) + p0(keylines[2])) / 2
            
            let currentCenterPoint = (centerOfKeyline0 + centerOfKeyline1 + centerOfKeyline2) / 3
            let targetCenterPoint = (intersectionPoints[0] + intersectionPoints[1] + intersectionPoints[2]) / 3
            let shiftCorrectionVector = targetCenterPoint - currentCenterPoint
            
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
                                                     doClip: true,
                                                     minX: -0.5, maxX: 0.5,
                                                     minY: -0.5, maxY: 0.5,
                                                     minZ: -0.5, maxZ: 0.5,
                                                     d: p1(keylines[0]) - p0(keylines[0]))
            exportMesh(transformedPolygon, withName: "polygon\(i)")
            /*
            let voxelIndices = geometryToVoxelIndices(inp: transformedPolygon)
            let xs = voxelIndices.x
            let ys = voxelIndices.y
            let zs = voxelIndices.z
            for voxelIndex in 0..<xs.count {
                let pointCloudIndex: Int32 = xs[voxelIndex] + 128 * ys[voxelIndex] + 16384 * zs[voxelIndex]
                pointCloud[Int(pointCloudIndex)] += 1
            }
            */
        }
        /*
        var vertices: [vector_int3] = []
        for pointCloudIndex in 0..<pointCloud.count {
            if  (3 <= pointCloud[pointCloudIndex]) {
                let x = Int(pointCloudIndex % 128)
                let y = Int(((pointCloudIndex - x) % 16384) / 128)
                let z = Int((pointCloudIndex - x - y) / 16384)
                vertices.append(vector_int3(Int32(x),Int32(y),Int32(z)))
            }
        }
        let newData = Data(bytes: vertices, count: vertices.count * MemoryLayout<vector_int3>.size)
        let mdlMesh = MDLVoxelArray(data: newData,
                      boundingBox: MDLAxisAlignedBoundingBox(maxBounds: vector_float3(100,
                                                                                      100,
                                                                                      100),
                                                             minBounds: vector_float3(-100,
                                                                                      -100,
                                                                                      -100)),
                                    voxelExtent: 100000).mesh(using: nil)
        let asset2 = MDLAsset()
        asset2.add(mdlMesh!)
        
        let outNode = asset2.object(at: 0)
        let out = SCNNode(mdlObject: outNode).geometry
        */
        
        
    }
    
    return SCNGeometry()
}
